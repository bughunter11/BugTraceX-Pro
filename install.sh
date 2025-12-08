#!/bin/bash

echo ""
echo "🔧 Installing BugTraceX Secure VIP Version..."
sleep 1

# ====== SAFE LOG ======
ERROR_LOG="$HOME/.bgx_install.log"
touch "$ERROR_LOG" 2>/dev/null
log(){ echo -e "$1"; }

# ====== REAL DETECTION (NO FALSE TERMUX) ======
if [ -d "/data/data/com.termux/files/usr" ] && [ -n "$PREFIX" ] && [[ "$PREFIX" == "/data/data/com.termux/files/usr" ]]; then
    ENV="TERMUX"
    BIN_PATH="$PREFIX/bin"
    PKG_UPDATE="pkg update -y"
    PKG_INSTALL="pkg install -y"
    PY_CMD="python"
    log "📌 Environment Detected: Termux (Android)"

    # ====== AUTO STORAGE PERMISSION SAFE ======
    if [ ! -d "$HOME/storage" ]; then
        log "📂 Granting Storage Access..."
        termux-setup-storage >/dev/null 2>&1
        sleep 2
    else
        log "📂 Storage Access Already Granted ✔"
    fi

else
    ENV="LINUX"
    [ "$EUID" -eq 0 ] && BIN_PATH="/usr/local/bin" || BIN_PATH="$HOME/.local/bin"
    PKG_UPDATE="apt update -y"
    PKG_INSTALL="apt install -y"
    PY_CMD="python3"
    log "📌 Environment Detected: Linux/Server (Ubuntu/Kali/Debian/SSH/Termius)"
fi

# ====== ENSURE BIN EXISTS ======
mkdir -p "$BIN_PATH"
chmod 755 "$BIN_PATH"

# ====== FIX PACKAGE MANAGER LOCK ======
if [ "$ENV" = "LINUX" ]; then
    log "🔓 Fixing Package Manager Locks..."
    killall apt apt-get >/dev/null 2>&1
    rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock* /var/cache/apt/archives/lock 2>/dev/null
    dpkg --configure -a >/dev/null 2>&1
fi

# ====== INSTALL PACKAGES ======
log "📦 Preparing Environment..."
$PKG_UPDATE >> "$ERROR_LOG" 2>&1
log "📥 Installing Dependencies..."
$PKG_INSTALL git curl wget golang openssl >> "$ERROR_LOG" 2>&1

# ====== PYTHON FIX ======
if [ "$ENV" = "LINUX" ]; then
    $PKG_INSTALL python3 python3-pip >> "$ERROR_LOG" 2>&1
    command -v python >/dev/null 2>&1 || ln -sf /usr/bin/python3 /usr/bin/python
else
    $PKG_INSTALL python >> "$ERROR_LOG" 2>&1
fi

command -v pip >/dev/null 2>&1 || ln -sf /usr/bin/pip3 /usr/bin/pip

# ====== CLEAN OLD TOOL ======
rm -rf "$HOME/BugTraceX-Pro"
mkdir -p "$HOME/BugTraceX-Pro"

# ====== DOWNLOAD SCRIPT ======
log "📥 Fetching Secure Script..."
curl -s -L https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py \
-o "$HOME/BugTraceX-Pro/BugTraceX.py"

# ====== PYTHON MODULES ======
log "🐍 Installing Python Modules..."
MODULES="requests tldextract bs4 colorama certifi chardet idna urllib3"
for M in $MODULES; do
    $PY_CMD -m pip install $M --upgrade --no-warn-script-location >> "$ERROR_LOG" 2>&1 || true
done

# ====== SUBDOMAIN TOOLS ======
log "🌐 Installing Subdomain Tools..."
GO111MODULE=on go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest >> "$ERROR_LOG" 2>&1 || true
go install github.com/tomnomnom/assetfinder@latest >> "$ERROR_LOG" 2>&1 || true

# ====== COPY BINARIES (Silent Safe) ======
[ -f "$HOME/go/bin/subfinder" ] && cp "$HOME/go/bin/subfinder" "$BIN_PATH" && chmod +x "$BIN_PATH/subfinder"
[ -f "$HOME/go/bin/assetfinder" ] && cp "$HOME/go/bin/assetfinder" "$BIN_PATH" && chmod +x "$BIN_PATH/assetfinder"

# ====== CREATE LAUNCHER ======
log "⚙️ Creating Launcher..."
cat <<EOF > "$BIN_PATH/bugtracex"
#!/bin/bash
export PATH=\$PATH:\$HOME/go/bin
cd \$HOME/BugTraceX-Pro
$PY_CMD BugTraceX.py
EOF
chmod +x "$BIN_PATH/bugtracex"

# ====== ADD TO PATH SAFE ======
if [[ ":$PATH:" != *":$BIN_PATH:"* ]]; then
    echo "export PATH=\$PATH:$BIN_PATH" >> "$HOME/.bashrc"
    echo "export PATH=\$PATH:$BIN_PATH" >> "$HOME/.profile"
    echo "export PATH=\$PATH:$BIN_PATH" >> "$HOME/.zshrc" 2>/dev/null
fi

echo ""
log "🎉 Secure Installation Completed Successfully!"
log "🚀 Run Tool Using:  bugtracex"
log "🔐 VIP Key Required → Contact @raj_maker"
echo ""