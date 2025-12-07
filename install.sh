#!/bin/bash

# ===== BugTraceX Pro Secure VIP Installer (Universal) =====

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
    echo "📌 Environment: Termux (Android)"
else
    ENV="LINUX"
    BIN_PATH="/usr/local/bin"
    PKG_UPDATE="apt update -y"
    PKG_INSTALL="apt install -y"
    PY_CMD="python3"
    echo "📌 Environment: Linux (Ubuntu/Kali/Debian)"
fi

# ===== System Update =====
echo "📦 Preparing Environment..."
$PKG_UPDATE >/dev/null 2>&1

# ===== Required Packages =====
echo "📥 Installing Dependencies..."
$PKG_INSTALL curl wget git golang >/dev/null 2>&1

# ===== Python Fix =====
if [ "$ENV" = "LINUX" ]; then
    $PKG_INSTALL python3 python3-pip >/dev/null 2>&1
    ln -sf /usr/bin/python3 /usr/bin/python >/dev/null 2>&1
else
    $PKG_INSTALL python >/dev/null 2>&1
fi

# ===== Remove Old Tool =====
rm -rf $HOME/BugTraceX-Pro
mkdir -p $HOME/BugTraceX-Pro

# ===== Download Main Script Only (No keys.json) =====
echo "📥 Fetching Secure Script..."
curl -s -L https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py \
-o $HOME/BugTraceX-Pro/BugTraceX.py

# ===== Python Requirements =====
echo "🐍 Installing Python Modules..."
pip install --upgrade pip >/dev/null 2>&1
pip install requests tldextract bs4 colorama certifi chardet idna urllib3 >/dev/null 2>&1

# ===== Install Subdomain Tools =====
echo "🌐 Installing Subdomain Tools..."

# --- Subfinder Fix ---
GO111MODULE=on go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest >/dev/null 2>&1
cp -f $HOME/go/bin/subfinder $BIN_PATH >/dev/null 2>&1

# --- Assetfinder Fix ---
go install github.com/tomnomnom/assetfinder@latest >/dev/null 2>&1
cp -f $HOME/go/bin/assetfinder $BIN_PATH >/dev/null 2>&1

chmod +x $BIN_PATH/subfinder >/dev/null 2>&1
chmod +x $BIN_PATH/assetfinder >/dev/null 2>&1

# ===== Create Launcher =====
echo "⚙️ Creating Launcher..."
cat <<EOF > $BIN_PATH/bugtracex
#!/bin/bash
cd \$HOME/BugTraceX-Pro
$PY_CMD BugTraceX.py
EOF

chmod +x $BIN_PATH/bugtracex

# ===== DONE =====
echo ""
echo "🎉 Secure Installation Completed Successfully!"
echo "🚀 Run The Tool Using:  bugtracex"
echo "🔐 VIP Key Required! If you don't have key → Contact @raj_maker"
echo ""