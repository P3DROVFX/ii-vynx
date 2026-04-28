#!/usr/bin/env python3
"""Fetch Gmail messages for a given label. Handles token refresh internally.
Usage: fetch_emails.py <refresh_token> <label_id> [max_results]
Outputs JSON array of message objects to stdout.
"""
import sys, json, urllib.request, urllib.parse, concurrent.futures, re
import gmail_config

def api_get(url, token):
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())

# Contextual icon classifier — keyword/regex, < 1ms per email
_ICON_RULES = [
    # (icon_name, [keywords...])
    ("local_shipping",  [r"tracking", r"rastreio", r"\bpedido\b", r"entregue", r"shipped",
                         r"delivery", r"\border\b", r"enviado", r"postado", r"transportadora"]),
    ("receipt_long",    [r"invoice", r"fatura", r"\bcompra\b", r"purchase", r"\bpayment\b",
                         r"pagamento", r"recibo", r"receipt", r"nota fiscal", r"boleto"]),
    ("security",        [r"login\b", r"\bsenha\b", r"password", r"\b2fa\b", r"verify",
                         r"verification", r"seguran[cç]a", r"security", r"suspicious",
                         r"alert.*account", r"account.*alert", r"acesso n[aã]o"]),
    ("campaign",        [r"unsubscribe", r"newsletter", r"weekly digest", r"monthly report",
                         r"desinscrev", r"cancelar inscri[cç][aã]o"]),
    ("event",           [r"\binvite\b", r"\bmeeting\b", r"\bevent\b", r"reuni[aã]o",
                         r"agendado", r"webinar", r"conference", r"calendar", r"calend[aá]rio",
                         r"confer[eê]ncia"]),
    ("check_circle",    [r"confirmed", r"welcome", r"bem.vindo", r"activated", r"ativado",
                         r"cadastro aprovado", r"conta criada", r"account created",
                         r"successfully", r"conclu[íi]do"]),
    ("code",            [r"github", r"gitlab", r"pull request", r"\bcommit\b", r"\bissue\b",
                         r"\bdeploy\b", r"ci/cd", r"pipeline", r"bitbucket", r"merge request"]),
    ("forum",           [r"comentou", r"mentioned you", r"commented", r"\bliked\b",
                         r"replied", r"responded", r"new reply", r"respondeu"]),
    ("account_balance", [r"extrato", r"\bsaldo\b", r"transfer[eê]ncia", r"\bpix\b",
                         r"\bbank\b", r"statement", r"balance", r"banco", r"nubank",
                         r"bradesco", r"itau", r"ita[uú]"]),
    ("sell",            [r"promo[cç][aã]o", r"desconto", r"discount", r"\bsale\b",
                         r"\boferta\b", r"\d+%\s*off", r"black friday", r"cupom", r"coupon"]),
    ("warning",         [r"\balerta\b", r"\balert\b", r"\berror\b", r"\bwarning\b",
                         r"\bfalha\b", r"\bfailed\b", r"expired", r"expira", r"vencimento",
                         r"problema", r"problema detectado"]),
    ("support_agent",   [r"\bticket\b", r"\bsupport\b", r"\bcase #", r"solicita[cç][aã]o",
                         r"\brequest\b", r"atendimento", r"suporte"]),
    ("newspaper",       [r"\bnews\b", r"breaking", r"\breport\b", r"not[íi]cia", r"manchete"]),
    ("flight",          [r"\bflight\b", r"\bbooking\b", r"reserva", r"\bhotel\b",
                         r"passagem", r"\bviagem\b", r"itinerary", r"check.in", r"embarque"]),
    ("school",          [r"\bcourse\b", r"certificate", r"certificado", r"\blearn\b",
                         r"\baula\b", r"m[oó]dulo", r"li[cç][aã]o", r"udemy", r"coursera",
                         r"alura"]),
    ("new_releases",    [r"new version", r"nova vers[aã]o", r"\brelease\b", r"changelog",
                         r"new feature", r"nova funcionalidade", r"update available"]),
]

def classify_icon(subject: str, sender: str, snippet: str) -> str:
    """Return a Material Symbols icon name based on email content."""
    text = (subject + " " + sender + " " + snippet).lower()
    for icon, patterns in _ICON_RULES:
        for pattern in patterns:
            if re.search(pattern, text):
                return icon
    return "person"

def fetch_detail(msg_id, token):
    url = f"https://gmail.googleapis.com/gmail/v1/users/me/messages/{msg_id}?format=metadata&metadataHeaders=Subject&metadataHeaders=From&metadataHeaders=Date"
    detail = api_get(url, token)
    headers = {h["name"]: h["value"] for h in detail.get("payload", {}).get("headers", [])}
    label_ids = detail.get("labelIds", [])
    subject = headers.get("Subject", "")
    sender  = headers.get("From", "")
    snippet = detail.get("snippet", "")
    return {
        "id":       detail["id"],
        "threadId": detail.get("threadId", ""),
        "subject":  subject or "(sem assunto)",
        "from":     sender,
        "date":     headers.get("Date", ""),
        "snippet":  snippet,
        "unread":   "UNREAD" in label_ids,
        "starred":  "STARRED" in label_ids,
        "labels":   label_ids,
        "icon":     classify_icon(subject, sender, snippet),
    }

def main():
    if len(sys.argv) < 3:
        print(json.dumps({"messages": [], "nextPageToken": "", "historyId": ""}))
        sys.exit(0)

    refresh_token = sys.argv[1]
    label_id = sys.argv[2]
    max_results = int(sys.argv[3]) if len(sys.argv) > 3 else 50
    
    flags_arg = ""
    page_token = ""
    last_history_id = ""
    
    if label_id == "INBOX":
        flags_arg = sys.argv[4] if len(sys.argv) > 4 else ""
        page_token = sys.argv[5] if len(sys.argv) > 5 else ""
        last_history_id = sys.argv[6] if len(sys.argv) > 6 else ""
    else:
        page_token = sys.argv[4] if len(sys.argv) > 4 else ""
        last_history_id = sys.argv[5] if len(sys.argv) > 5 else ""

    try:
        token = gmail_config.refresh_token_exchange(refresh_token)
    except Exception:
        sys.exit(1)

    # Always get current historyId from profile
    profile = api_get("https://gmail.googleapis.com/gmail/v1/users/me/profile", token)
    current_history_id = profile.get("historyId", "")

    # Try incremental sync if historyId provided
    incremental_success = False
    messages = []
    next_page_token = ""

    if last_history_id and not page_token:
        try:
            # history.list returns changes since last_history_id
            h_url = f"https://gmail.googleapis.com/gmail/v1/users/me/history?startHistoryId={last_history_id}&maxResults=100"
            history_data = api_get(h_url, token)
            
            if "history" in history_data:
                # Identify all message IDs that were added or had labels changed
                affected_ids = set()
                for h in history_data["history"]:
                    for m in h.get("messagesAdded", []): affected_ids.add(m["message"]["id"])
                    for m in h.get("labelsAdded", []): affected_ids.add(m["message"]["id"])
                    for m in h.get("labelsRemoved", []): affected_ids.add(m["message"]["id"])
                
                if not affected_ids:
                    # No changes at all, we can stop here if we're just syncing
                    # But for simplicity in the current QML architecture, 
                    # we still want to return the "current state" list.
                    # A better impl would return a "no change" flag.
                    pass
                else:
                    # If there are changes, a simple "messages.list" is still the most robust 
                    # way to get the current view without re-implementing label filtering 
                    # logic in Python. The real optimization is skipping metadata fetch 
                    # for IDs we already have, but since this script is stateless, 
                    # we can't easily do that without a local cache.
                    pass
        except Exception:
            # historyId might be expired (404), fall back to full sync
            pass

    # Standard fetch (Full sync or fallback)
    if label_id == "INBOX":
        cats = ["category:primary"]
        if flags_arg:
            flags = flags_arg.split(",")
            if len(flags) == 3:
                if flags[0] == "1": cats.append("category:updates")
                if flags[1] == "1": cats.append("category:promotions")
                if flags[2] == "1": cats.append("category:social")
        
        q_cats = "{" + " ".join(cats) + "}"
        q_param = f"in:inbox {q_cats}"
        query_params = f"q={urllib.parse.quote(q_param)}&maxResults={max_results}"
    elif label_id.startswith("SEARCH:"):
        q = label_id[7:]
        query_params = f"q={urllib.parse.quote(q)}&maxResults={max_results}"
    else:
        query_params = f"labelIds={label_id}&maxResults={max_results}"

    if page_token:
        query_params += f"&pageToken={page_token}"

    listing = api_get(
        f"https://gmail.googleapis.com/gmail/v1/users/me/messages?{query_params}",
        token
    )

    messages = listing.get("messages", [])
    next_page_token = listing.get("nextPageToken", "")

    if not messages:
        print(json.dumps({
            "messages": [], 
            "nextPageToken": next_page_token,
            "historyId": current_history_id
        }))
        return

    # Fetch details in parallel (up to 10 threads)
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as pool:
        futures = {pool.submit(fetch_detail, m["id"], token): i for i, m in enumerate(messages)}
        for future in concurrent.futures.as_completed(futures):
            try:
                results.append((futures[future], future.result()))
            except Exception:
                pass

    # Sort by original order
    results.sort(key=lambda x: x[0])
    
    print(json.dumps({
        "messages": [r[1] for r in results],
        "nextPageToken": next_page_token,
        "historyId": current_history_id
    }))

if __name__ == "__main__":
    main()
