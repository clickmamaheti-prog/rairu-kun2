#!/bin/bash
# ============================================================
#  Rairu-Kun2 — GitHub Codespaces VPS Starter
#  Menjalankan SSH server + tunnel bore di dalam Codespace.
#  Password & ntfy diambil dari Codespaces secrets:
#    ROOT_PASS   (opsional — kosong = password acak)
#    NTFY_TOPIC  (opsional)
# ============================================================
set +e

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== Rairu-Kun2 VPS (Codespaces) ==="

# ---- Install ssh server + bore ----
sudo apt-get update -qq && sudo apt-get install -y -qq openssh-server curl jq >/dev/null 2>&1
BORE_BIN="$HOME/.local/bin/bore"
mkdir -p "$HOME/.local/bin"
if ! test -x "$BORE_BIN"; then
    curl -fsSL https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-unknown-linux-musl.tar.gz -o /tmp/bore.tgz \
        && tar -xzf /tmp/bore.tgz -C "$HOME/.local/bin" bore && chmod +x "$BORE_BIN"
fi

# ---- Set root password (dari secret ROOT_PASS, atau acak) ----
ROOT_PASS="${ROOT_PASS:-}"
if test -z "$ROOT_PASS"; then
    ROOT_PASS=$(openssl rand -base64 14 | tr -d '/+=' | cut -c1-14)
    log "🔑 ROOT_PASS kosong — password acak: ${ROOT_PASS}"
fi
echo "root:${ROOT_PASS}" | sudo chpasswd
log "➡️ Root password diset (${ROOT_PASS:0:4}****)"

# ---- Konfigurasi sshd (port tinggi, tidak perlu sudo untuk connect) ----
sudo mkdir -p /run/sshd
cat <<'SSHD' | sudo tee /etc/ssh/sshd_config.d/99-rairu.conf >/dev/null
PermitRootLogin yes
PasswordAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 4
LoginGraceTime 30
Port 2222
SSHD
sudo ssh-keygen -A
sudo /usr/sbin/sshd
log "✅ sshd jalan di localhost:2222"

# ---- Tunnel bore untuk SSH ----
NTFY_TOPIC="${NTFY_TOPIC:-}"
"$BORE_BIN" local 2222 --to bore.pub > /tmp/bore-ssh.log 2>&1 &
sleep 4
SSH_PORT=$(grep -oE "bore\.pub:[0-9]+" /tmp/bore-ssh.log 2>/dev/null | head -1 | grep -oE '[0-9]+$')

if test -n "$SSH_PORT"; then
    log "✅ SSH tunnel → ssh -p ${SSH_PORT} root@bore.pub (password: dari ROOT_PASS)"
else
    log "⚠️ Tunnel belum konek — cek /tmp/bore-ssh.log"
fi

# ---- Kirim notifikasi ntfy ----
if test -n "$NTFY_TOPIC" && test -n "$SSH_PORT"; then
    curl -s --max-time 10 -X POST "https://ntfy.sh/${NTFY_TOPIC}" \
        -H "Title: Rairu-Kun2 Codespaces Online" -H "Priority: high" \
        -d "🔐 SSH: ssh root@bore.pub -p ${SSH_PORT}
🔑 Password: (isi ROOT_PASS / lihat log)" >/dev/null 2>&1 \
        && log "📲 ntfy terkirim (topic: ${NTFY_TOPIC})"
fi

log "=== Selesai. Codespace tetap hidup selama dipakai (idle max ±30 menit) ==="
