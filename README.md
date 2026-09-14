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

# Rairu-Kun2 — Premium SSH VPS via ngrok Tunnel

**Ubuntu 20.04 · ngrok Tunnel · Multi-Port · Railway · ntfy Premium**

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.app/new)
[![Deploy on Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04_LTS-E95420?logo=ubuntu&logoColor=white)
![ngrok](https://img.shields.io/badge/ngrok-Tunnel-1F176E?logo=ngrok&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-00e5ff)

</div>

---

## ✨ Fitur Premium

| Fitur | Keterangan |
|-------|-----------|
| 🖥 **Ubuntu 20.04 LTS** | OS premium, stabil dan ringan |
| 🔑 **SSH via ngrok** | TCP tunnel publik — akses langsung `ssh root@<host> -p <port>` |
| 🔐 **Supervisord** | Systemd alternative — auto-restart semua service |
| 🌐 **Web UI Premium** | Dashboard dengan tema gelap DevCulture |
| 📲 **ntfy Premium** | Notifikasi SSH URL + status periodik (set topic unik milikmu) |
| 🔄 **ngrok Tunnel** | Auto-restart jika tunnel mati |
| 🐳 **Docker Ready** | Deploy ke Railway, Render, Fly.io, atau VPS |
| 🆓 **100% Gratis** | Cukup akun ngrok free + authtoken |

---

## 🚀 Deploy ke Railway

### 1. Fork repo ini
### 2. Buat project di [railway.app](https://railway.app)
New Project → Deploy from GitHub → pilih repo ini

### 3. Set Environment Variables

| Variable | Wajib? | Default | Deskripsi |
|----------|--------|---------|-----------|
| `NGROK_AUTHTOKEN` | **⚠️ Wajib** | - | Authtoken dari [dashboard.ngrok.com](https://dashboard.ngrok.com/get-started/your-authtoken) |
| `ROOT_PASS` | Opsional | *(auto-generated)* | Password SSH root — kosong = password acak kuat dibuat otomatis (lihat log) |
| `NTFY_TOPIC` | Opsional | *(kosong)* | Topic ntfy unik untuk notifikasi (contoh: `rairu-abc123`) |
| `TZ` | Opsional | `Asia/Jakarta` | Timezone |
| `PORT` | Opsional | `8080` | Port web UI |
| `NGROK_DOMAIN_SSH` | Opsional | - | Reserved TCP domain ngrok (kalau punya) |

### 4. Daftar ngrok
1. Buka https://dashboard.ngrok.com/signup
2. Register (gratis)
3. Copy authtoken → set sebagai `NGROK_AUTHTOKEN`

### 5. Subscribe ntfy di HP (untuk notifikasi)
```
ntfy.sh/<NTFY_TOPIC-anda>
```

> ⚠️ **Pakai topic unik!** Topic publik bisa dibaca siapa saja — password SSH kamu ikut terkirim ke situ.

---

## 🔐 Cara Akses SSH

ngrok membuka **TCP tunnel publik** untuk SSH — tidak perlu install client tambahan:

```bash
# Endpoint muncul di notifikasi ntfy atau log container:
#   ✅ SSH → 0.tcp.ap.ngrok.io:12345

ssh root@0.tcp.ap.ngrok.io -p 12345
# Password: nilai ROOT_PASS (atau password auto-generated dari log)
```

> **Catatan:** ngrok free = 1 tunnel online + endpoint acak yang berubah tiap restart. Untuk endpoint tetap, reserved TCP domain tersedia di plan berbayar (set `NGROK_DOMAIN_SSH`).

---

## 🌐 Akses Web

ngrok juga membuka tunnel ke port 80 (Web UI) dan port 8080 (App) — tapi di plan free hanya **1 tunnel** yang bisa online bersamaan. Prioritas script adalah **SSH (port 22)**, jadi kalau butuh web tunnel, matikan SSH tunnel di `ngrok-setup.sh` atau upgrade ke plan berbayar.

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
├── Dockerfile                 # Ubuntu 20.04 + ngrok + supervisord
├── entrypoint.sh              # Startup config + auto password + supervisord
├── supervisord.conf           # Process manager (systemd alternative)
├── ngrok-setup.sh             # ngrok tunnels + ntfy + watchdog
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
│  │ SSH  │ │Nginx │ │ ngrok    │  │
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
    │  ngrok  │ ← Public TCP tunnel
    │  Cloud  │
    └─────────┘
    SSH / HTTPS
```

---

## ⚠️ Catatan Penting

- **NGROK_AUTHTOKEN WAJIB** — daftar gratis di https://dashboard.ngrok.com/signup
- **Tidak ada password default** — `ROOT_PASS` kosong = password acak dibuat otomatis saat start (lihat log/ntfy)
- Plan free ngrok: **1 tunnel online** — script memprioritaskan SSH (port 22)
- Endpoint TCP acak berubah tiap restart — selalu cek notifikasi/log terbaru
- **TIDAK pakai Ollama** — pure VPS + SSH + tunnel
- Semua service auto-restart via supervisord & watchdog
- Jangan pernah commit password/token ke repo

---

<div align="center">

**Dibuat dengan ❤️ oleh [DevCulture](https://github.com/clickmamaheti-prog)**

*Premium VPS via ngrok · No Ollama · Supervisord Powered*

⭐ **Star repo ini jika membantu!** ⭐

```
powered by: DevCulture ©2026 linux
```

</div>
