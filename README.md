<div align="center">

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    ██████╗  █████╗ ██╗██████╗ ██╗   ██╗   ██╗  ██╗██╗   ██╗███╗   ██╗ ║
║    ██╔══██╗██╔══██╗██║██╔══██╗██║   ██║   ██║ ██╔╝██║   ██║████╗  ██║ ║
║    ██████╔╝███████║██║██║  ██║██║   ██║   █████╔╝ ██║   ██║██╔██╗ ██║ ║
║    ██╔══██╗██╔══██║██║██║  ██║██║   ██║   ██╔═██╗ ██║   ██║██║╚██╗██║ ║
║    ██║  ██║██║  ██║██║██████╔╝╚██████╔╝██╗██║  ██╗╚██████╔╝██║ ╚████║ ║
║    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ║
║                                                              ║
║              ★  RAIRU-KUN2 PREMIUM VPS  ★                   ║
╚═══════════════════════════════════════════════════════════════╝
              powered by: DevCulture ©2026 linux
```

# Rairu-Kun2 — Premium SSH VPS via bore Tunnel

**Ubuntu 20.04 · bore Tunnel · Multi-Port · Railway · ntfy Premium**

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.app/new)
[![Deploy on Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04_LTS-E95420?logo=ubuntu&logoColor=white)
![bore](https://img.shields.io/badge/bore-Tunnel-00e5ff)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-00e5ff)

</div>

---

## ✨ Fitur Premium

| Fitur | Keterangan |
|-------|-----------|
| 🖥 **Ubuntu 20.04 LTS** | OS premium, stabil dan ringan |
| 🔑 **SSH via bore** | TCP tunnel publik — akses langsung `ssh root@bore.pub -p <port>` |
| 🔐 **Supervisord** | Systemd alternative — auto-restart semua service |
| 🌐 **Web UI Premium** | Dashboard dengan tema gelap DevCulture |
| 📲 **ntfy Premium** | Notifikasi SSH URL + status periodik (set topic unik milikmu) |
| 🔄 **bore Tunnel** | Auto-restart jika tunnel mati |
| 🐳 **Docker Ready** | Deploy ke Railway, Render, Fly.io, atau VPS |
| 🆓 **100% Gratis** | Tanpa registrasi, tanpa token, tanpa kartu |

---

## 🚀 Deploy ke Railway

### 1. Fork repo ini
### 2. Buat project di [railway.app](https://railway.app)
New Project → Deploy from GitHub → pilih repo ini

### 3. Set Environment Variables

| Variable | Wajib? | Default | Deskripsi |
|----------|--------|---------|-----------|
| `ROOT_PASS` | Opsional | *(auto-generated)* | Password SSH root — kosong = password acak kuat dibuat otomatis (lihat log) |
| `NTFY_TOPIC` | Opsional | *(kosong)* | Topic ntfy unik untuk notifikasi (contoh: `rairu-abc123`) |
| `BORE_SERVER` | Opsional | `bore.pub` | Server bore relay |
| `TZ` | Opsional | `Asia/Jakarta` | Timezone |
| `PORT` | Opsional | `8080` | Port web UI |

### 4. Tidak perlu daftar apa-apa ✅
bore tidak butuh token, akun, atau kartu — langsung jalan saat deploy.

### 5. Subscribe ntfy di HP (untuk notifikasi)
```
ntfy.sh/<NTFY_TOPIC-anda>
```

> ⚠️ **Pakai topic unik!** Topic publik bisa dibaca siapa saja — password SSH kamu ikut terkirim ke situ.

---

## 🔐 Cara Akses SSH

bore membuka **TCP tunnel publik** untuk SSH — tidak perlu install client atau registrasi:

```bash
# Endpoint muncul di notifikasi ntfy atau log container:
#   ✅ SSH → bore.pub:12345

ssh root@bore.pub -p 12345
# Password: nilai ROOT_PASS (atau password auto-generated dari log)
```

> **Catatan:** port bore acak dan berubah tiap restart — selalu cek notifikasi/log terbaru.

---

## 🌐 Akses Web

bore membuka tunnel ke **5 port sekaligus**: 22 (SSH), 80 (HTTP), 443 (HTTPS), 8080 (App), 3000. Semua endpoint aktif bersamaan — URL muncul di notifikasi ntfy.

---

## 📲 Notifikasi ntfy

Semua notifikasi dikirim ke topic **`NTFY_TOPIC`** milikmu:

| Event | Notifikasi |
|-------|-----------|
| ⚡ VPS Online | SSH endpoint + Web URL + password |
| 📊 Status (5 menit) | Uptime, RAM, Disk, SSH endpoint |
| 🚨 Tunnel Restart | Alert jika tunnel mati |

---

## 🏗 Struktur Proyek

```
rairu-kun2/
├── Dockerfile                 # Ubuntu 20.04 + bore + supervisord
├── entrypoint.sh              # Startup config + auto password + supervisord
├── supervisord.conf           # Process manager (systemd alternative)
├── bore-setup.sh              # bore tunnels + ntfy + watchdog
├── watchdog.sh                # Service watchdog (SSH, Nginx)
├── nginx-ollama.conf          # Nginx config web UI
├── index.html                 # DevCulture Web UI
├── devculture-banner.sh       # SSH login banner
├── render.yaml                # Render deploy config
├── railway.json               # Railway deploy config
├── fly.toml                   # Fly.io deploy config
└── .github/workflows/
    └── railway-deploy.yml     # Auto-deploy CI/CD
```

---

## ⚙️ System Architecture

```
┌──────────────────────────────────┐
│         Supervisord              │
│  (systemd alternative)           │
├──────────────────────────────────┤
│  ┌──────┐ ┌──────┐ ┌──────────┐  │
│  │ SSH  │ │Nginx │ │ bore     │  │
│  │sshd -D│ │:PORT│ │ Tunnel   │  │
│  └──────┘ └──────┘ │ Manager  │  │
│                    └──────────┘  │
│  ┌────────────────────────────┐  │
│  │ Watchdog                    │  │
│  │ (auto-restart dead services)│  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
         │
    ┌────┴────┐
    │  bore   │ ← Public TCP tunnel
    │  Cloud  │
    └─────────┘
    SSH / HTTPS
```

---

## ⚠️ Catatan Penting

- **Tidak perlu registrasi/token/kartu** — bore langsung jalan tanpa akun
- **Tidak ada password default** — `ROOT_PASS` kosong = password acak dibuat otomatis saat start (lihat log/ntfy)
- Port tunnel bore **acak & berubah tiap restart** — selalu cek notifikasi/log terbaru
- **TIDAK pakai Ollama** — pure VPS + SSH + tunnel
- Semua service auto-restart via supervisord & watchdog
- Jangan pernah commit password/token ke repo

---

<div align="center">

**Dibuat dengan ❤️ oleh [DevCulture](https://github.com/clickmamaheti-prog)**

*Premium VPS via bore · No Ollama · Supervisord Powered*

⭐ **Star repo ini jika membantu!** ⭐

```
powered by: DevCulture ©2026 linux
```

</div>
