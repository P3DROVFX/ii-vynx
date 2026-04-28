#!/usr/bin/env python3
import http.server
import urllib.parse
import urllib.request
import subprocess
import json
import secrets
import hashlib
import base64
import os
import gmail_config

CLIENT_ID, CLIENT_SECRET = gmail_config.get_credentials()
if not CLIENT_ID or not CLIENT_SECRET:
    print(json.dumps({"error": "Missing GMAIL_CLIENT_ID or GMAIL_CLIENT_SECRET in .env"}), flush=True)
    exit(1)

REDIRECT_URI  = "http://localhost:42069/callback"
SCOPES        = "https://www.googleapis.com/auth/gmail.modify https://www.googleapis.com/auth/gmail.send email profile"
PORT          = 42069

# PKCE
code_verifier  = secrets.token_urlsafe(64)
code_challenge = base64.urlsafe_b64encode(
    hashlib.sha256(code_verifier.encode()).digest()
).rstrip(b"=").decode()

auth_url = (
    f"https://accounts.google.com/o/oauth2/v2/auth"
    f"?client_id={CLIENT_ID}"
    f"&redirect_uri={urllib.parse.quote(REDIRECT_URI, safe='')}"
    f"&response_type=code"
    f"&scope={urllib.parse.quote(SCOPES)}"
    f"&code_challenge={code_challenge}"
    f"&code_challenge_method=S256"
    f"&access_type=offline"
    f"&prompt=consent"
)

os.makedirs(os.path.expanduser("~/.cache/quickshell-gmail"), exist_ok=True)
with open(os.path.expanduser("~/.cache/quickshell-gmail/verifier"), "w") as f:
    f.write(code_verifier)

print(f"\n🔗 URL de autorização:\n{auth_url}\n", flush=True)
print(f"⏳ Aguardando callback em localhost:{PORT}...", flush=True)
subprocess.Popen(["xdg-open", auth_url])

# Flag para comunicar resultado ao thread principal
result = {"done": False, "refresh": "", "email": "", "picture": ""}

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args): pass
    def handle_error(self): pass

    def do_GET(self):
        # Responde PRIMEIRO, depois processa — evita timeout no browser
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"""<html><body style="font-family:sans-serif;text-align:center;padding:60px">
        <h2>Autorizado!</h2><p>Pode fechar esta aba.</p></body></html>""")
        self.wfile.flush()

        if not self.path.startswith("/callback"):
            return

        params = dict(urllib.parse.parse_qsl(
            urllib.parse.urlparse(self.path).query
        ))
        code = params.get("code", "")

        if not code:
            print("❌ Nenhum code na URL", flush=True)
            return

        print(f"\n📨 Code recebido: {code[:20]}...", flush=True)
        print("🔄 Trocando code por tokens...", flush=True)

        # Troca code → tokens
        try:
            data = urllib.parse.urlencode({
                "code":          code,
                "client_id":     CLIENT_ID,
                "client_secret": CLIENT_SECRET,
                "redirect_uri":  REDIRECT_URI,
                "grant_type":    "authorization_code",
                "code_verifier": code_verifier,
            }).encode()

            req = urllib.request.Request(
                "https://oauth2.googleapis.com/token",
                data=data,
                headers={"Content-Type": "application/x-www-form-urlencoded"}
            )
            with urllib.request.urlopen(req) as resp:
                tokens = json.loads(resp.read())
        except urllib.error.HTTPError as e:
            body = e.read().decode()
            print(f"❌ Erro na troca de tokens: {e.code} {e.reason}", flush=True)
            print(f"   Resposta: {body}", flush=True)
            return
        except Exception as e:
            print(f"❌ Erro inesperado: {type(e).__name__}: {e}", flush=True)
            return

        refresh = tokens.get("refresh_token", "")
        access  = tokens.get("access_token", "")

        if not refresh:
            print("⚠️  refresh_token não veio — revogue o app em myaccount.google.com/permissions e tente de novo", flush=True)
            print(f"   access_token (temporário): {access[:40]}...", flush=True)
            return

        # Busca email do usuário
        try:
            req2 = urllib.request.Request(
                "https://www.googleapis.com/oauth2/v2/userinfo",
                headers={"Authorization": f"Bearer {access}"}
            )
            with urllib.request.urlopen(req2) as resp:
                userinfo = json.loads(resp.read())
            email = userinfo.get("email", "desconhecido")
            picture = userinfo.get("picture", "")
        except Exception as e:
            email = "erro-ao-buscar"
            picture = ""
            print(f"⚠️  Não conseguiu buscar email: {e}", flush=True)

        print(f"\n✅ Autenticado como: {email}", flush=True)
        print(f"🔑 refresh_token:\n{refresh}\n", flush=True)

        result["refresh"] = refresh
        result["email"]   = email
        result["picture"] = picture
        result["done"]    = True

http.server.HTTPServer.allow_reuse_address = True
httpd = http.server.HTTPServer(("localhost", PORT), Handler)
while not result["done"]:
    httpd.handle_request()

if result["done"]:
    print("📡 Notificando Quickshell via IPC...", flush=True)
    ipc = subprocess.run(
        ["qs", "-c", os.path.expanduser("~/.config/quickshell/ii"), "ipc", "call", "gmail", "onAuthComplete", result["refresh"], result["email"], result["picture"]],
        capture_output=True, text=True
    )
    if ipc.returncode == 0:
        print("✅ IPC enviado com sucesso", flush=True)
    else:
        print(f"⚠️  IPC falhou (Quickshell não está rodando?): {ipc.stderr}", flush=True)
        print("   Salve o refresh_token acima manualmente para continuar testando", flush=True)
