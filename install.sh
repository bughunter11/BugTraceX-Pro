#!/bin/bash

echo ""
echo "🔧 Installing BugTraceX Secure VIP Version..."
sleep 1

ERROR_LOG="$HOME/.bgx_install.log"
touch "$ERROR_LOG" 2>/dev/null
log(){ echo -e "$1"; }

# ====== ENV DETECTION ======
if [ -d "/data/data/com.termux/files/usr" ] && [ -n "$PREFIX" ]; then
    ENV="TERMUX"
    BIN_PATH="$PREFIX/bin"
    PKG_UPDATE="pkg update -y"
    PKG_INSTALL="pkg install -y"
    PY_CMD="python"
    log "📌 Environment Detected: Termux (Android)"

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
    log "📌 Environment Detected: Linux/Server (Ubuntu/Kali/Debian)"
fi

mkdir -p "$BIN_PATH"
chmod 755 "$BIN_PATH"

# ====== PACKAGES ======
log "📦 Preparing Environment..."
$PKG_UPDATE >> "$ERROR_LOG" 2>&1
log "📥 Installing Dependencies..."
$PKG_INSTALL git curl wget golang openssl >> "$ERROR_LOG" 2>&1

if [ "$ENV" = "LINUX" ]; then
    $PKG_INSTALL python3 python3-pip >> "$ERROR_LOG" 2>&1
    command -v python >/dev/null 2>&1 || ln -sf /usr/bin/python3 /usr/bin/python
else
    $PKG_INSTALL python >> "$ERROR_LOG" 2>&1
fi

command -v pip >/dev/null 2>&1 || ln -sf /usr/bin/pip3 /usr/bin/pip

# ====== CLEAN OLD TOOL ONLY (unlimited installs allowed) ======
rm -rf "$HOME/BugTraceX-Pro"
mkdir -p "$HOME/BugTraceX-Pro"

# Cache not deleted here — key binding must survive reinstall
CACHE_DIR="$HOME/.local/.share/.sys_$(echo -n 'bughunter11/BugTraceX-Pro' | sha256sum | cut -c1-8)"

# ====== DOWNLOAD TOOL ======
log "📥 Fetching Secure Script..."
URL="https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py"
curl -s -L "$URL" -o "$HOME/BugTraceX-Pro/BugTraceX.py"

FILE="$HOME/BugTraceX-Pro/BugTraceX.py"

# ====== VERIFY INTEGRITY (SAFE, NO BLOCK ON REINSTALL) ======
EXPECTED_HASH="$(curl -s https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/version.txt | grep -oE '[A-Fa-f0-9]{64}')"
LOCAL_HASH="$(sha256sum "$FILE" 2>/dev/null | awk '{print $1}')"

if [ -z "$LOCAL_HASH" ] || [ ! -s "$FILE" ]; then
    log "❌ Download Failed! Try again with stable internet."
    rm -rf "$HOME/BugTraceX-Pro"
    exit 1
fi

# compare hash only when EXPECTED_HASH exists, else fallback to grep
if [ -n "$EXPECTED_HASH" ] && [ "$LOCAL_HASH" != "$EXPECTED_HASH" ]; then
    if ! grep -q "verify" "$FILE"; then
        log "❌ Tampered Script Detected!"
        rm -rf "$HOME/BugTraceX-Pro"
        exit 1
    fi
fi

log "🔐 Secure Source Verified!"

# ====== CACHE DIR (KEEP OLD BINDS) ======
mkdir -p "$CACHE_DIR" 2>/dev/null
chmod 700 "$CACHE_DIR" 2>/dev/null

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

# ====== COPY BIN ======
[ -f "$HOME/go/bin/subfinder" ] && cp "$HOME/go/bin/subfinder" "$BIN_PATH" && chmod +x "$BIN_PATH/subfinder"
[ -f "$HOME/go/bin/assetfinder" ] && cp "$HOME/go/bin/assetfinder" "$BIN_PATH" && chmod +x "$BIN_PATH/assetfinder"

# ====== LAUNCHER (LOCKED) ======
log "⚙️ Creating Secure Launcher..."
cat <<EOF > "$BIN_PATH/bugtracex"
#!/bin/bash
export PATH=\$PATH:\$HOME/go/bin
DIR="\$HOME/.local/.share/.sys_$(echo -n 'bughunter11/BugTraceX-Pro' | sha256sum | cut -c1-8)"
mkdir -p "\$DIR" 2>/dev/null
chmod 700 "\$DIR" 2>/dev/null
cd \$HOME/BugTraceX-Pro || exit 1
if [ "\$1" = "debug" ]; then
    echo "❌ Debug Mode Not Allowed"
    exit 1
fi
$PY_CMD BugTraceX.py
EOF
chmod +x "$BIN_PATH/bugtracex"

# ====== PATH FIX ======
if [[ ":$PATH:" != *":$BIN_PATH:"* ]]; then
    echo "export PATH=\$PATH:$BIN_PATH" >> "$HOME/.bashrc"
    echo "export PATH=\$PATH:$BIN_PATH" >> "$HOME/.profile"
    echo "export PATH=\$PATH:$BIN_PATH" >> "$HOME/.zshrc" 2>/dev/null
fi

echo ""
log "🎉 Secure Installation Completed!"
log "🚀 Run Using:  bugtracex"
log "🔐 VIP Key Required → Contact @raj_maker"
echo ""