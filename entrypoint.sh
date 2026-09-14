#!/bin/bash
set -e

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "╔═══════════════════════════════════════╗"
log "║   Rairu-Kun2 — DevCulture VPS v5.0   ║"
log "╚═══════════════════════════════════════╝"

# ---- Environment (auto-detect from platform variables) ----
# Just fill these in on Railway/Render/Fly and everything configures itself:
#   NGROK_AUTHTOKEN — from https://dashboard.ngrok.com/get-started/your-authtoken
#   ROOT_PASS       — optional; random strong password auto-generated if empty
#   NTFY_TOPIC      — optional; unique ntfy.sh topic for notifications
ROOT_PASS="${ROOT_PASS:-}"
NTFY_TOPIC="${NTFY_TOPIC:-}"
PORT="${PORT:-8080}"
TZ="${TZ:-Asia/Jakarta}"
NGROK_AUTHTOKEN="${NGROK_AUTHTOKEN:-}"
NGROK_DOMAIN_SSH="${NGROK_DOMAIN_SSH:-}"

log "➡️ PORT=$PORT"
log "➡️ TZ=$TZ"
if test -n "$NGROK_AUTHTOKEN"; then
    log "➡️ NGROK_AUTHTOKEN=✅ configured"
else
    log "➡️ NGROK_AUTHTOKEN=❌ NOT SET — tunnels will be disabled!"
    log "   Get one free at https://dashboard.ngrok.com/get-started/your-authtoken"
fi
test -n "$NGROK_DOMAIN_SSH" && log "➡️ NGROK_DOMAIN_SSH=$NGROK_DOMAIN_SSH"
test -n "$NTFY_TOPIC" && log "➡️ NTFY TOPIC=$NTFY_TOPIC"

# ---- Root password: use ROOT_PASS, or auto-generate a strong one ----
if test -z "$ROOT_PASS"; then
    ROOT_PASS=$(openssl rand -base64 14 | tr -d '/+=' | cut -c1-14)
    AUTO_GENERATED=1
else
    AUTO_GENERATED=0
fi
echo "root:${ROOT_PASS}" | chpasswd 2>/dev/null || true
log "➡️ Root password set (${ROOT_PASS:0:4}****)"
if test "$AUTO_GENERATED" = "1"; then
    log "🔑 ROOT_PASS was empty — auto-generated password: ${ROOT_PASS}"
    log "   (Set ROOT_PASS env var to choose your own password.)"
fi

# ---- Fix Nginx config with correct PORT ----
cat > /etc/nginx/sites-available/ollama << EOF
server {
    listen ${PORT};
    server_name _;
    client_max_body_size 10M;
    location / {
        root /var/www/ollama-ui;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
    location /health {
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
EOF
log "➡️ Nginx config updated for PORT=$PORT"

# ---- Configure ngrok authtoken (if provided) ----
if test -n "$NGROK_AUTHTOKEN"; then
    ngrok config add-authtoken "$NGROK_AUTHTOKEN" >/dev/null 2>&1 \
        && log "➡️ ngrok authtoken configured" \
        || log "⚠️ ngrok authtoken configuration failed"
fi

# ---- Start supervisord (manages everything) ----
log "➡️ Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
