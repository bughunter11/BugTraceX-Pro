#!/bin/bash

# ===== BugTraceX Pro Secure VIP Installer (Universal + Auto Fix) =====

set -e  # Stop on error
trap 'echo -e "\n❌ Installation Failed! Auto Fixing..."; sleep 1; bash <(curl -s https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/install.sh)' ERR

echo ""
echo "🔧 Installing BugTraceX Secure VIP Version..."
sleep 1

# ===== Detect Environment =====
if grep -qi "android" /proc/version; then
    ENV="TERMUX"
    BIN_PATH="/data/data/com.termux/files/usr/bin"
    PKG_UPDATE="pkg update -y"
    PKG_INSTALL="pkg install -y"
    PY_CMD="python"
    echo "📌 Environment Detected: Termux (Android)"
else
    ENV="LINUX"
    BIN_PATH="/usr/local/bin"
    PKG_UPDATE="apt update -y"
    PKG_INSTALL="apt install -y"
    PY_CMD="python3"
    echo "📌 Environment Detected: Linux (Ubuntu/Kali/Debian)"
fi

# ===== APT/DPKG AUTO FIX =====
if [ "$ENV" = "LINUX" ]; then
    echo "🔓 Fixing Package Manager Lock..."
    killall apt apt-get >/dev/null 2>&1 || true
    rm -f /var/lib/apt/lists/lock >/dev/null 2>&1
    rm -f /var/lib/dpkg/lock >/dev/null 2>&1
    rm -f /var/lib/dpkg/lock-frontend >/dev/null 2>&1
    dpkg --configure -a >/dev/null 2>&1 || true
fi

# ===== System Update =====
echo "📦 Preparing Environment..."
$PKG_UPDATE >/dev/null 2>&1 || true

# ===== Required Packages =====
echo "📥 Installing Dependencies..."
$PKG_INSTALL git curl wget golang >/dev/null 2>&1 || true

# ===== Python Fix =====
if [ "$ENV" = "LINUX" ]; then
    $PKG_INSTALL python3 python3-pip >/dev/null 2>&1 || true
    ln -sf /usr/bin/python3 /usr/bin/python >/dev/null 2>&1 || true
else
    $PKG_INSTALL python >/dev/null 2>&1 || true
fi

# ===== Remove Old Tool & Create Folder =====
rm -rf $HOME/BugTraceX-Pro >/dev/null 2>&1
mkdir -p $HOME/BugTraceX-Pro

# ===== Fetch Main Script =====
echo "📥 Fetching Secure Script..."
curl -s -L https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py \
-o $HOME/BugTraceX-Pro/BugTraceX.py

# ===== Python Requirements =====
echo "🐍 Installing Python Modules..."
pip install --upgrade pip >/dev/null 2>&1 || true
pip install requests tldextract bs4 colorama certifi chardet idna urllib3 >/dev/null 2>&1 || true

# ===== Install Subdomain Tools =====
echo "🌐 Installing Subdomain Tools..."

GO111MODULE=on go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest >/dev/null 2>&1 || true
go install github.com/tomnomnom/assetfinder@latest >/dev/null 2>&1 || true

# ===== Move Binaries Safely =====
[ -f "$HOME/go/bin/subfinder" ] && cp -f $HOME/go/bin/subfinder $BIN_PATH && chmod +x $BIN_PATH/subfinder
[ -f "$HOME/go/bin/assetfinder" ] && cp -f $HOME/go/bin/assetfinder $BIN_PATH && chmod +x $BIN_PATH/assetfinder

# ===== Create Launcher =====
echo "⚙️ Creating Launcher..."
cat <<EOF > $BIN_PATH/bugtracex
#!/bin/bash
cd \$HOME/BugTraceX-Pro
$PY_CMD BugTraceX.py
EOF

chmod +x $BIN_PATH/bugtracex >/dev/null 2>&1 || true

# ===== Done =====
echo ""
echo "🎉 Secure Installation Completed Successfully!"
echo "🚀 Run Now Using:  bugtracex"
echo "🔐 VIP Key Required! If you don't have key → Contact @raj_maker"
echo ""