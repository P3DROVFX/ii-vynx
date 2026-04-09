#!/bin/bash
# TickTick OAuth2 Token Helper
# Este script ajuda a obter o access_token do TickTick
#
# Uso: ./ticktick-auth.sh

ENV_FILE="$(dirname "$0")/../.env"

echo "╔══════════════════════════════════════════════════╗"
echo "║        TickTick OAuth2 - Obter Access Token      ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Ler credenciais do .env se existirem
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE" 2>/dev/null
fi

# Pedir Client ID se não existir
if [ -z "$TICKTICK_CLIENT_ID" ]; then
    read -p "Cole seu Client ID: " TICKTICK_CLIENT_ID
fi

if [ -z "$TICKTICK_CLIENT_SECRET" ]; then
    read -p "Cole seu Client Secret: " TICKTICK_CLIENT_SECRET
fi

REDIRECT_URI="http://localhost:18321"
SCOPE="tasks:read tasks:write"

echo ""
echo "━━━ Passo 1: Autorizar no navegador ━━━"
echo ""

AUTH_URL="https://ticktick.com/oauth/authorize?scope=$(echo $SCOPE | sed 's/ /%20/g')&client_id=${TICKTICK_CLIENT_ID}&response_type=code&redirect_uri=$(echo $REDIRECT_URI | sed 's/:/%3A/g; s/\//%2F/g')&state=quickshell"

echo "Abrindo o navegador para autorizar..."
echo ""

# Abrir no navegador
xdg-open "$AUTH_URL" 2>/dev/null || open "$AUTH_URL" 2>/dev/null || echo "Abra manualmente: $AUTH_URL"

echo "━━━ Passo 2: Capturando o código ━━━"
echo ""
echo "Aguardando callback em $REDIRECT_URI ..."
echo "(O navegador vai redirecionar automaticamente)"
echo ""

# Mini servidor HTTP para capturar o callback
RESPONSE=$(python3 -c "
import http.server, urllib.parse, sys

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        query = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(query)
        code = params.get('code', [''])[0]
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b'<html><body style=\"background:#1a1a1a;color:#fff;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0\"><div style=\"text-align:center\"><h1>Autorizado!</h1><p>Pode fechar esta janela.</p></div></body></html>')
        
        print(code)
        sys.stdout.flush()
        
    def log_message(self, format, *args):
        pass  # silenciar logs

server = http.server.HTTPServer(('localhost', 18321), Handler)
server.handle_request()
" 2>/dev/null)

AUTH_CODE="$RESPONSE"

if [ -z "$AUTH_CODE" ]; then
    echo "❌ Erro: não foi possível capturar o código de autorização."
    echo ""
    echo "Método manual: após autorizar, copie o 'code' da URL de redirect."
    read -p "Cole o código aqui: " AUTH_CODE
fi

echo ""
echo "✓ Código capturado!"
echo ""
echo "━━━ Passo 3: Trocando código por access token ━━━"
echo ""

# Trocar código por token
TOKEN_RESPONSE=$(curl -s -X POST "https://ticktick.com/oauth/token" \
    -u "${TICKTICK_CLIENT_ID}:${TICKTICK_CLIENT_SECRET}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "code=${AUTH_CODE}&grant_type=authorization_code&redirect_uri=${REDIRECT_URI}")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Erro ao obter o token. Resposta da API:"
    echo "$TOKEN_RESPONSE"
    exit 1
fi

echo "✓ Access Token obtido!"
echo ""

# Salvar no .env
cat > "$ENV_FILE" << EOF
# TickTick API Credentials
TICKTICK_CLIENT_ID=${TICKTICK_CLIENT_ID}
TICKTICK_CLIENT_SECRET=${TICKTICK_CLIENT_SECRET}
TICKTICK_ACCESS_TOKEN=${ACCESS_TOKEN}
EOF

echo "━━━ Pronto! ━━━"
echo ""
echo "✓ Token salvo em: $ENV_FILE"
echo ""
echo "Reinicie o Quickshell para ativar a integração."
echo ""
