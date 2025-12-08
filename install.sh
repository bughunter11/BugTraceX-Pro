#!/bin/bash

echo ""
echo "🔧 Installing BugTraceX Secure VIP Version..."
sleep 1

# ===== SAFE LOG LOCATION =====
ERROR_LOG="$HOME/.bgx_install.log"
touch "$ERROR_LOG" 2>/dev/null

log(){ echo -e "$1"; }

# ===== Detect TERMUX or LINUX (Fixed SSH/TRemius detection) =====
if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux/files/usr" ]; then
    ENV="TERMUX"
    BIN_PATH="$PREFIX/bin"
    PKG_UPDATE="pkg update -y"
    PKG_INSTALL="pkg install -y"
    PY_CMD="python"
    log "📌 Environment Detected: Termux (Android)"
else
    ENV="LINUX"
    if [ "$EUID" -eq 0 ]; then BIN_PATH="/usr/local/bin"; else BIN_PATH="$HOME/.local/bin"; fi
    PKG_UPDATE="apt update -y"
    PKG_INSTALL="apt install -y"
    PY_CMD="python3"
    log "📌 Environment Detected: Linux (Ubuntu/Kali/Debian/VPS)"
fi

# ===== Ensure BIN Exists =====
mkdir -p "$BIN_PATH"
chmod 755 "$BIN_PATH"

# ===== Fix Package Manager Locks =====
if [ "$ENV" = "LINUX" ]; then
    log "🔓 Fixing Package Manager Locks..."
    killall apt apt-get >/dev/null 2>&1
    rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock* /var/cache/apt/archives/lock 2>/dev/null
    dpkg --configure -a >/dev/null 2>&1
fi

# ===== Install Dependencies =====
log "📦 Preparing Environment..."
$PKG_UPDATE >> "$ERROR_LOG" 2>&1
log "📥 Installing Dependencies..."
$PKG_INSTALL git curl wget golang openssl >> "$ERROR_LOG" 2>&1

# ===== Python Fix =====
if [ "$ENV" = "LINUX" ]; then
    $PKG_INSTALL python3 python3-pip >> "$ERROR_LOG" 2>&1
    command -v python >/dev/null 2>&1 || ln -sf /usr/bin/python3 /usr/bin/python
else
    $PKG_INSTALL python >> "$ERROR_LOG" 2>&1
fi

# ===== Fallback PIP =====
command -v pip >/dev/null 2>&1 || ln -sf /usr/bin/pip3 /usr/bin/pip

# ===== Clean Old Tool =====
rm -rf "$HOME/BugTraceX-Pro"
mkdir -p "$HOME/BugTraceX-Pro"

# ===== Download Tool =====
log "📥 Fetching Secure Script..."
curl -s -L https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py \
-o "$HOME/BugTraceX-Pro/BugTraceX.py"

# ===== Install Python Modules =====
log "🐍 Installing Python Modules..."
MODULES="requests tldextract bs4 colorama certifi chardet idna urllib3"
for M in $MODULES; do
    $PY_CMD -m pip install $M --upgrade --no-warn-script-location >> "$ERROR_LOG" 2>&1 || true
done

# ===== Install Subdomain Tools =====
log "🌐 Installing Subdomain Tools..."
GO111MODULE=on go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest >> "$ERROR_LOG" 2>&1 || true
go install github.com/tomnomnom/assetfinder@latest >> "$ERROR_LOG" 2>&1 || true

# ===== Copy Binaries Safe (no error) =====
[ -f "$HOME/go/bin/subfinder" ] && cp "$HOME/go/bin/subfinder" "$BIN_PATH" && chmod +x "$BIN_PATH/subfinder"
[ -f "$HOME/go/bin/assetfinder" ] && cp "$HOME/go/bin/assetfinder" "$BIN_PATH" && chmod +x "$BIN_PATH/assetfinder"

# ===== Create Launcher =====
log "⚙️ Creating Launcher..."
cat <<EOF > "$BIN_PATH/bugtracex"
#!/bin/bash
export PATH=\$PATH:\$HOME/go/bin
cd \$HOME/BugTraceX-Pro
$PY_CMD BugTraceX.py
EOF
chmod +x "$BIN_PATH/bugtracex"

# ===== Add PATH For All Users/Shells =====
if [[ ":$PATH:" != *":$BIN_PATH:"* ]]; then
    echo "export PATH=\$PATH:$BIN_PATH" >> "$HOME/.bashrc"
    echo "export PATH=\$PATH:$BIN_PATH" >> "$HOME/.profile"
    echo "export PATH=\$PATH:$BIN_PATH" >> "$HOME/.zshrc" 2>/dev/null
fi

# ===== Verify Launcher =====
if [ ! -f "$BIN_PATH/bugtracex" ]; then
    echo "❌ Installation Failed (Launcher Not Found)"
    echo "🔧 Fix Manually: export PATH=\$PATH:$BIN_PATH"
    exit 1
fi

# ===== END =====
echo ""
log "🎉 Secure Installation Completed Successfully!"
log "🚀 Run Tool Using:  bugtracex"
log "🔐 VIP Key Required → Contact @raj_maker"
echo ""