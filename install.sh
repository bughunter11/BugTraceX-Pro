#!/bin/bash

# ===== BugTraceX Pro Secure VIP Installer (Universal + No Module Error) =====

echo ""
echo "🔧 Installing BugTraceX Secure VIP Version..."
sleep 1

ERROR_LOG="/tmp/bgx_fix.log"
touch $ERROR_LOG

log(){ echo -e "$1"; }

# ===== Detect Environment =====
if grep -qi "android" /proc/version; then
    ENV="TERMUX"
    BIN_PATH="/data/data/com.termux/files/usr/bin"
    PKG_UPDATE="pkg update -y"
    PKG_INSTALL="pkg install -y"
    PY_CMD="python"
    PIP_CMD="pip"
    log "📌 Environment Detected: Termux (Android)"
else
    ENV="LINUX"
    BIN_PATH="/usr/local/bin"
    PKG_UPDATE="apt update -y"
    PKG_INSTALL="apt install -y"
    PY_CMD="python3"
    PIP_CMD="pip3"
    log "📌 Environment Detected: Linux (Ubuntu/Kali/Debian/VPS)"
fi

# ===== Fix Package Locks =====
if [ "$ENV" = "LINUX" ]; then
  log "🔓 Fixing Package Manager Locks..."
  killall apt apt-get >/dev/null 2>&1
  rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock* /var/cache/apt/archives/lock
  dpkg --configure -a >/dev/null 2>&1
fi

# ===== Update + Dependency Install =====
log "📦 Preparing Environment..."
$PKG_UPDATE >> $ERROR_LOG 2>&1 || true

log "📥 Installing Dependencies..."
$PKG_INSTALL curl wget git golang >> $ERROR_LOG 2>&1 || true

# ===== Python + Pip Fix =====
if [ "$ENV" = "LINUX" ]; then
  $PKG_INSTALL python3 python3-pip >> $ERROR_LOG 2>&1 || true
  command -v python >/dev/null 2>&1 || ln -sf /usr/bin/python3 /usr/bin/python
else
  $PKG_INSTALL python python-pip >> $ERROR_LOG 2>&1 || true
fi

command -v pip >/dev/null 2>&1 || ln -sf /usr/bin/pip3 /usr/bin/pip

# ===== Remove Old Tool & Download =====
rm -rf $HOME/BugTraceX-Pro
mkdir -p $HOME/BugTraceX-Pro

log "📥 Downloading Secure Script..."
curl -s -L https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py \
-o $HOME/BugTraceX-Pro/BugTraceX.py

# ===== Python Modules (FULL SAFE INSTALL) =====
log "🐍 Installing Python Modules..."
MODULES="requests tldextract bs4 colorama certifi chardet idna urllib3"

for M in $MODULES; do
  $PIP_CMD install $M --upgrade --break-system-packages >/dev/null 2>&1 || $PY_CMD -m pip install $M >/dev/null 2>&1 || true
done

# ===== Subdomain Tools =====
log "🌐 Installing Subdomain Tools..."
GO111MODULE=on go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest >/dev/null 2>&1 || true
go install github.com/tomnomnom/assetfinder@latest >/dev/null 2>&1 || true

# ===== Move & Fix Path =====
export PATH=$PATH:$HOME/go/bin

[ -f "$HOME/go/bin/subfinder" ] && cp -f $HOME/go/bin/subfinder $BIN_PATH && chmod +x $BIN_PATH/subfinder
[ -f "$HOME/go/bin/assetfinder" ] && cp -f $HOME/go/bin/assetfinder $BIN_PATH && chmod +x $BIN_PATH/assetfinder

# ===== Create Launcher =====
log "⚙️ Creating Launcher..."
cat <<EOF > $BIN_PATH/bugtracex
#!/bin/bash
export PATH=\$PATH:\$HOME/go/bin
cd \$HOME/BugTraceX-Pro
$PY_CMD BugTraceX.py
EOF
chmod +x $BIN_PATH/bugtracex

# ===== Done =====
echo ""
log "🎉 Secure Installation Completed Successfully!"
log "🚀 Run Tool Using:  bugtracex"
log "🔐 VIP Key Required → Contact @raj_maker"
echo ""
