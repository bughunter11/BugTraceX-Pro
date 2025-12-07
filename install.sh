#!/bin/bash

# ===== BugTraceX Pro Secure VIP Installer =====

echo ""
echo "🔧 Installing BugTraceX Secure VIP Version..."
sleep 1

# ===== System Update =====
echo "📦 Preparing Environment..."
pkg update -y > /dev/null 2>&1
pkg upgrade -y > /dev/null 2>&1

# ===== Required Packages =====
echo "📥 Installing Dependencies..."
pkg install python git curl wget golang -y > /dev/null 2>&1

# ===== Remove Old Tool =====
rm -rf $HOME/BugTraceX-Pro

# ===== Create Tool Folder =====
mkdir -p $HOME/BugTraceX-Pro

# ===== Download Main Script Only (No keys.json) =====
echo "📥 Fetching Secure Script..."
curl -s -L https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py \
-o $HOME/BugTraceX-Pro/BugTraceX.py

# ===== Python Requirements =====
pip install --upgrade pip > /dev/null 2>&1
pip install requests > /dev/null 2>&1

# ===== Install Subdomain Tools =====
echo "🌐 Installing Subdomain Tools..."

# --- Subfinder ---
GO111MODULE=on go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest > /dev/null 2>&1
mv $HOME/go/bin/subfinder /data/data/com.termux/files/usr/bin/ 2>/dev/null

# --- Assetfinder ---
go install github.com/tomnomnom/assetfinder@latest > /dev/null 2>&1
mv $HOME/go/bin/assetfinder /data/data/com.termux/files/usr/bin/ 2>/dev/null

chmod +x /data/data/com.termux/files/usr/bin/subfinder
chmod +x /data/data/com.termux/files/usr/bin/assetfinder

# ===== Create Launcher =====
echo "⚙️ Creating Launcher..."
cat <<EOF > /data/data/com.termux/files/usr/bin/bugtracex
#!/bin/bash
cd \$HOME/BugTraceX-Pro
python BugTraceX.py
EOF

chmod +x /data/data/com.termux/files/usr/bin/bugtracex

# ===== DONE =====
echo ""
echo "🎉 Secure Installation Completed Successfully!"
echo "🚀 Run The Tool Using:  bugtracex"
echo "🔐 VIP Key Required! If you don't have key → Contact @raj_maker"
echo ""