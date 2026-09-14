#!/bin/bash
set +e

log() { echo "[$(date '+%H:%M:%S')] [watchdog] $*"; }

log "Watchdog started — monitoring services..."

while true; do
    sleep 30

    # SSH
    if ! pgrep -x sshd >/dev/null 2>&1; then
        log "⚠️ SSH down — restarting"
        /usr/sbin/sshd 2>/dev/null
    fi

    # Nginx
    if ! pgrep -x nginx >/dev/null 2>&1; then
        log "⚠️ Nginx down — restarting"
        /usr/sbin/nginx 2>/dev/null
    fi

    # ngrok tunnel manager
    if ! pgrep -f "ngrok-setup.sh" >/dev/null 2>&1; then
        log "⚠️ ngrok manager down — supervisord will restart"
    fi
done
