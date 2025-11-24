#!/bin/bash
# ============================================================
# REALITY FALLBACK SITE SETUP
# Features:
# - iOS Style Status Page (Dark Mode)
# - Optimized Nginx Config (TLS 1.3, ChaCha20, HSTS)
# - Privacy Focused (No Access Logs)
# - Xray Reality Ready (Proxy Protocol Support)
# ============================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- 1. INPUT ---
echo -e "${GREEN}=== REALITY FALLBACK SITE SETUP ===${NC}"
read -p "Enter DOMAIN (e.g., node.mysite.com): " DOMAIN
read -p "Enter EMAIL (for Let's Encrypt): " EMAIL

echo -e "${YELLOW}--- Site Customization ---${NC}"
read -p "Enter Node Name (e.g., Node USA-01): " NODE_NAME
read -p "Enter Region (e.g., Chicago (US)): " NODE_REGION

# Set defaults
NODE_NAME=${NODE_NAME:-"System Node"}
NODE_REGION=${NODE_REGION:-"Global Edge"}
FALLBACK_PORT="9000"

if [[ -z "$DOMAIN" || -z "$EMAIL" ]]; then
    echo -e "${RED}Error: Domain and Email are required.${NC}"
    exit 1
fi

# --- 2. INSTALL ---
echo -e "${YELLOW}[INFO] Installing Nginx and Certbot...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt update -q
apt install -y nginx certbot python3-certbot-nginx

# Clean default config
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

# --- 3. DEPLOY TEMPLATE ---
echo -e "${YELLOW}[INFO] Deploying System Status Template...${NC}"
WEB_ROOT="/var/www/html/site"

# Clean old files
rm -rf "$WEB_ROOT"
mkdir -p "$WEB_ROOT"

# Generate HTML
cat > "$WEB_ROOT/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Status</title>
    <style>
        :root {
            --bg-color: #000000;
            --card-bg: #1c1c1e;
            --text-primary: #ffffff;
            --text-secondary: #86868b;
            --accent-green: #30d158;
            --divider: #38383a;
            --font-stack: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
        }
        body {
            background-color: var(--bg-color);
            color: var(--text-primary);
            font-family: var(--font-stack);
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            -webkit-font-smoothing: antialiased;
        }
        .container { width: 100%; max-width: 480px; padding: 20px; }
        header { text-align: center; margin-bottom: 40px; }
        h1 { font-size: 34px; font-weight: 700; margin: 0 0 8px 0; }
        .subtitle { color: var(--text-secondary); font-size: 17px; }
        .card-group {
            background-color: var(--card-bg);
            border-radius: 12px;
            overflow: hidden;
            margin-bottom: 30px;
        }
        .row {
            display: flex; justify-content: space-between; align-items: center;
            padding: 16px 20px; border-bottom: 0.5px solid var(--divider);
        }
        .row:last-child { border-bottom: none; }
        .row-label { font-size: 17px; }
        .row-value { color: var(--text-secondary); font-size: 17px; display: flex; align-items: center; }
        .row-value.active { color: var(--accent-green); }
        .status-indicator {
            width: 8px; height: 8px; background-color: var(--accent-green);
            border-radius: 50%; margin-right: 8px;
            box-shadow: 0 0 8px rgba(48, 209, 88, 0.4);
        }
        .hero-status { display: flex; flex-direction: column; align-items: center; margin-bottom: 40px; }
        .big-icon {
            font-size: 64px; margin-bottom: 16px;
            background: linear-gradient(180deg, #63E684 0%, #30D158 100%);
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            color: var(--accent-green);
        }
        .status-text { font-size: 22px; font-weight: 600; }
        footer { text-align: center; color: var(--text-secondary); font-size: 13px; margin-top: 40px; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="hero-status">
                <div class="big-icon">●</div>
                <div class="status-text">All Systems Operational</div>
            </div>
            <div class="subtitle">$NODE_NAME</div>
        </header>
        <div class="card-group">
            <div class="row"><span class="row-label">Region</span><span class="row-value">$NODE_REGION</span></div>
            <div class="row"><span class="row-label">Status</span><span class="row-value active">Active</span></div>
            <div class="row"><span class="row-label">Uptime</span><span class="row-value">99.9%</span></div>
        </div>
        <div class="card-group">
            <div class="row"><span class="row-label">API Gateway</span><span class="row-value active"><div class="status-indicator"></div>Operational</span></div>
            <div class="row"><span class="row-label">Database</span><span class="row-value active"><div class="status-indicator"></div>Operational</span></div>
            <div class="row"><span class="row-label">CDN</span><span class="row-value active"><div class="status-indicator"></div>Operational</span></div>
        </div>
        <footer>System Status • Updated <span id="time">Just now</span></footer>
    </div>
    <script>
        const now = new Date();
        document.getElementById('time').textContent = "at " + now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    </script>
</body>
</html>
EOF

# Set Permissions
chown -R www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

# --- 4. TEMP CONFIG FOR CERTBOT ---
echo -e "${YELLOW}[INFO] Creating temporary config for Certbot...${NC}"
cat > "/etc/nginx/sites-available/$DOMAIN" <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    root $WEB_ROOT;
    index index.html;
}
EOF
ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/"
systemctl restart nginx

# --- 5. SSL ISSUANCE ---
echo -e "${YELLOW}[INFO] Requesting SSL Certificate...${NC}"
# Force renewal to ensure paths are correct if run multiple times
if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect; then
    echo -e "${GREEN}[OK] SSL Certificate received.${NC}"
else
    echo -e "${RED}[ERROR] Certbot failed! Check DNS for $DOMAIN.${NC}"
    exit 1
fi

# --- 6. FINAL CONFIG (OPTIMIZED) ---
echo -e "${YELLOW}[INFO] Applying Final Nginx Configuration...${NC}"
cat > "/etc/nginx/sites-available/$DOMAIN" <<EOF
server {
    # Listen on Localhost + SSL + HTTP/2 + PROXY Protocol
    # "proxy_protocol" is required because Xray (Reality) sends the real client IP via this protocol.
    listen 127.0.0.1:$FALLBACK_PORT ssl http2 proxy_protocol;
    
    server_name $DOMAIN;
    
    root $WEB_ROOT;
    index index.html;

    # Privacy: Disable Access Logs
    access_log off;
    error_log /var/log/nginx/error.log warn;

    # SSL Config (Modern & Fast)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # SSL Cache Optimization
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;

    # Proxy Protocol (For Xray)
    set_real_ip_from 127.0.0.1;
    real_ip_header proxy_protocol; 

    # Security Headers
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# --- 7. VALIDATION ---
nginx -t
systemctl restart nginx

# Wait a moment for Nginx to bind
sleep 2

# Check if Nginx is listening on the fallback port
if ss -tulpn | grep -q ":$FALLBACK_PORT"; then
    echo ""
    echo -e "${GREEN}=== [SUCCESS] STEALTH SITE DEPLOYED ===${NC}"
    echo -e "${YELLOW}Template:${NC} iOS System Status (Dark)"
    echo -e "${YELLOW}Domain:${NC} $DOMAIN"
    echo -e "${YELLOW}Fallback Dest:${NC} 127.0.0.1:$FALLBACK_PORT"
    echo -e "${YELLOW}SSL Path:${NC} /etc/letsencrypt/live/$DOMAIN/"
    echo -e "${GREEN}=======================================${NC}"
    echo -e "Action: Configure Xray Fallback -> ${YELLOW}127.0.0.1:$FALLBACK_PORT${NC}"
else
    echo -e "${RED}[ERROR] Nginx is NOT listening on port $FALLBACK_PORT.${NC}"
    echo -e "Check logs: journalctl -u nginx --no-pager | tail -n 20"
    exit 1
fi
