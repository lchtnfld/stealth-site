# 🕵️‍♂️ Stealth Site Deployer

Automated deployment of a high-quality **"System Status" decoy page** for Xray Reality fallback.  
Designed to look like a legitimate infrastructure status page (iOS/Apple style, Dark Mode).

## ✨ Features

- **🎨 Realistic Decoy:** Deploys a professional "System Status" HTML template.
- **🔒 SSL/TLS Hardening:** Configures Nginx with **TLS 1.3**, **ChaCha20**, and **HSTS**.
- **🤐 Privacy First:** Disables Nginx access logs (error logs only).
- **🚀 Xray Ready:** Configures Nginx to accept PROXY protocol from Xray on `127.0.0.1:9000`.
- **🤖 Automated:** Installs Nginx, Certbot, issues SSL, and configures everything in one go.

---

## 🛠️ Quick Start

Run this command on your server (Ubuntu 20.04/22.04/24.04).  
*You will be asked for your domain, email, and node name.*

```
bash <(curl -Ls https://raw.githubusercontent.com/lchtnfld/stealth-site/main/install.sh)
```

### Inputs Required:
1.  **Domain:** (e.g., `node.example.com`) — *Must point to your server IP!*
2.  **Email:** (for Let's Encrypt notifications)
3.  **Node Name:** (e.g., `Node USA-01`) — *Displayed on the status page.*
4.  **Region:** (e.g., `Chicago, US`) — *Displayed on the status page.*

---

## ⚙️ Xray Configuration

After installation, Nginx will listen on `127.0.0.1:9000` and expect PROXY protocol.  
Configure your Xray/Remnawave Reality fallback as follows:

| Setting | Value |
| :--- | :--- |
| **Dest** | `127.0.0.1:9000` |
| **SNI** | *Your Domain* |
| **xver** | `1` (Enable PROXY protocol sending) |

---

## 🔍 Technical Details

- **Nginx Port:** `9000` (Localhost only)
- **Web Root:** `/var/www/html/site`
- **SSL Path:** `/etc/letsencrypt/live/<YOUR_DOMAIN>/`
- **Security Headers:** `X-Frame-Options`, `X-Content-Type-Options`, `HSTS` enabled.

## 📸 Preview

The generated site looks like a modern SaaS status page:
- **Header:** "All Systems Operational"
- **Metrics:** Region, Status, Uptime (Static values for decoy)
- **Footer:** "System Status • Updated just now"
