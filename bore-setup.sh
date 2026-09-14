#!/bin/bash
set +e

log() {
    local line
    line="[$(date '+%H:%M:%S')] $*"
    echo "$line"
    echo "$line" > /proc/1/fd/1 2>/dev/null || true
}

NTFY_TOPIC="${NTFY_TOPIC:-}"
BORE_SERVER="${BORE_SERVER:-bore.pub}"
ROOT_PASS="${ROOT_PASS:-}"
PORT="${PORT:-8080}"
LOGDIR="/tmp/bore"
mkdir -p "$LOGDIR"

log "=== BORE TUNNEL MANAGER ==="
log "Server: $BORE_SERVER"

# Ports to tunnel: port:label
PORTS=(
    "22:SSH"
    "80:HTTP"
    "443:HTTPS"
    "${PORT}:APP"
    "3000:APP3K"
)

declare -A TUNNEL_URLS
declare -A TUNNEL_PORTS
declare -A RESTART_COUNT

start_tunnel() {
    local port="$1" label="$2"
    local logf="$LOGDIR/${port}.log"
    local pidf="$LOGDIR/${port}.pid"

    if test -f "$pidf"; then
        kill "$(cat "$pidf" 2>/dev/null)" 2>/dev/null
        rm -f "$pidf"
    fi
    sleep 1
    : > "$logf"

    log "🚇 bore local $port → $BORE_SERVER ($label)"
    bore local "$port" --to "$BORE_SERVER" >> "$logf" 2>&1 &
    echo "$!" > "$pidf"

    # Wait up to 30s for bore to print the remote address:
    # "Forwarded TCP traffic from bore.pub:12345 to localhost:22"
    local remote_port=""
    for _ in $(seq 1 15); do
        sleep 2
        remote_port=$(grep -oE "${BORE_SERVER}:[0-9]+" "$logf" 2>/dev/null | head -1 | grep -oE '[0-9]+$')
        test -n "$remote_port" && break
    done

    if test -n "$remote_port"; then
        log "✅ $label → ${BORE_SERVER}:${remote_port}"
        TUNNEL_URLS["$label"]="${BORE_SERVER}:${remote_port}"
        TUNNEL_PORTS["$label"]="$remote_port"
    else
        log "⚠️ $label — URL not detected yet"
        TUNNEL_URLS["$label"]="connecting..."
        TUNNEL_PORTS["$label"]=""
    fi
}

send_ntfy() {
    # ntfy optional: skip when NTFY_TOPIC is empty
    test -z "$NTFY_TOPIC" && return 0
    curl -s --max-time 15 -X POST "https://ntfy.sh/${NTFY_TOPIC}" \
        -H "Title: $1" -H "Priority: $2" -H "Tags: computer,rocket,key" \
        -d "$3" >/dev/null 2>&1 \
        && log "📲 ntfy terkirim (topic: $NTFY_TOPIC)" \
        || log "⚠️ ntfy gagal dikirim"
}

build_status_msg() {
    local mode="$1" reason="$2"
    local ssh_addr="${TUNNEL_URLS[SSH]:-N/A}"
    local app_addr="${TUNNEL_URLS[APP]:-N/A}"
    local app3k_addr="${TUNNEL_URLS[APP3K]:-N/A}"
    local ssh_port="${TUNNEL_PORTS[SSH]:-}"
    local uptime
    uptime=$(uptime -p 2>/dev/null | sed 's/up //' || echo "N/A")
    local ram
    ram=$(free -m | awk '/Mem:/{printf "%sMB/%sMB (%d%%)", $3, $2, $3*100/$2}' 2>/dev/null || echo "N/A")

    local ssh_cmd="N/A"
    test -n "$ssh_port" && ssh_cmd="ssh root@${BORE_SERVER} -p ${ssh_port}"

    local header="" footer=""
    case "$mode" in
        online)
            header="⚡ Rairu-Kun2 VPS — ONLINE"
            footer="🟢 Status : First boot — semua tunnel aktif"
            ;;
        restart)
            header="🔄 Rairu-Kun2 VPS — AUTO RESTART"
            footer="♻️ Restart : Tunnel ${reason} mati → auto restart oleh watchdog
🤖 Engine : supervisord + bore watchdog"
            ;;
        status)
            header="📊 Rairu-Kun2 VPS — STATUS UPDATE"
            footer="⏱ Uptime : ${uptime}
💾 RAM : ${ram}"
            ;;
    esac

    echo "${header}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔐 SSH : ${ssh_addr}
💡 Cmd : ${ssh_cmd}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📡 App : ${app_addr}
📡 3000 : ${app3k_addr}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${footer}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ️ Password : set via ROOT_PASS env (auto-generated if empty — see logs)
🚀 Powered by DevCulture ©2026"
}

# ─── Start all tunnels ────────────────────────────────
log "🚀 Starting bore tunnels..."
for entry in "${PORTS[@]}"; do
    IFS=':' read -r p l <<< "$entry"
    RESTART_COUNT["$l"]=0
    start_tunnel "$p" "$l"
done

send_ntfy "⚡ Rairu-Kun2 VPS — ONLINE" "high" "$(build_status_msg online)"

# ─── Watchdog loop ────────────────────────────────────
log "🔄 Watchdog aktif (${#PORTS[@]} tunnels)..."
LAST_STATUS_TIME=0

while true; do
    sleep 30

    CHANGED=false
    RESTARTED_LABELS=""

    for entry in "${PORTS[@]}"; do
        IFS=':' read -r p l <<< "$entry"
        pidf="$LOGDIR/${p}.pid"
        old_addr="${TUNNEL_URLS[$l]}"
        needs_restart=false

        if test -f "$pidf"; then
            pid=$(cat "$pidf" 2>/dev/null)
            kill -0 "$pid" 2>/dev/null || needs_restart=true
        else
            needs_restart=true
        fi

        if $needs_restart; then
            RESTART_COUNT["$l"]=$(( ${RESTART_COUNT[$l]:-0} + 1 ))
            log "♻️ Auto-restart $l (port $p) — restart #${RESTART_COUNT[$l]}..."
            start_tunnel "$p" "$l"
            if test "${TUNNEL_URLS[$l]}" != "$old_addr"; then
                CHANGED=true
            fi
            RESTARTED_LABELS="${RESTARTED_LABELS}${l}(#${RESTART_COUNT[$l]}) "
        fi
    done

    # Re-notify on restart or changed ports
    if test -n "$RESTARTED_LABELS"; then
        log "🔔 Kirim notifikasi auto-restart: $RESTARTED_LABELS"
        send_ntfy "🔄 Rairu-Kun2 — AUTO RESTART" "high" \
            "$(build_status_msg restart "$RESTARTED_LABELS")"
    elif test "$CHANGED" = "true"; then
        send_ntfy "🔄 Rairu-Kun2 — PORT BERUBAH" "default" \
            "$(build_status_msg restart "port changed")"
    fi

    # Periodic status every 5 minutes
    NOW=$SECONDS
    if test $((NOW - LAST_STATUS_TIME)) -ge 300; then
        LAST_STATUS_TIME=$NOW
        ACTIVE=0
        for pidf in "$LOGDIR"/*.pid; do
            test -f "$pidf" && kill -0 "$(cat "$pidf" 2>/dev/null)" 2>/dev/null && ACTIVE=$((ACTIVE+1))
        done
        log "📊 Status periodik — ${ACTIVE}/${#PORTS[@]} tunnels aktif"
        send_ntfy "📊 Rairu-Kun2 — STATUS" "default" \
            "$(build_status_msg status)
🔗 Tunnels: ${ACTIVE}/${#PORTS[@]} aktif"
    fi
done
