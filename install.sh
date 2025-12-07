#!/bin/bash

# ========== BugTraceX Secure Installer (No JSON Download) ==========

echo "🔧 Installing BugTraceX Secure VIP Version..."
sleep 1

# Remove any old folder
rm -rf $HOME/BugTraceX-Pro

# Create directory
mkdir -p $HOME/BugTraceX-Pro

# Download ONLY the main tool (not keys.json)
echo "📥 Fetching Secure Script..."
curl -s -L https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py -o $HOME/BugTraceX-Pro/BugTraceX.py

# Install Python requirements
echo "📦 Installing dependencies..."
pkg install python -y > /dev/null 2>&1
pip install requests > /dev/null 2>&1

# Create launcher
echo "⚙️ Creating launcher..."
cat <<EOF > /data/data/com.termux/files/usr/bin/bugtracex
#!/bin/bash
cd \$HOME/BugTraceX-Pro
python BugTraceX.py
EOF

chmod +x /data/data/com.termux/files/usr/bin/bugtracex

echo ""
echo "🎉 Secure Installation Successful!"
echo "🚀 Run the tool using: bugtracex"
echo "🔐 VIP Cloud Protection Enabled (No Local Keys)!"