#!/bin/bash

# ========== BugTraceX Automatic Installer ==========

echo "🔧 Installing BugTraceX..."
sleep 1

# Remove old installation
rm -rf $HOME/BugTraceX-Pro

# Clone tool
echo "📥 Downloading Tool..."
git clone https://github.com/bughunter11/BugTraceX-Pro $HOME/BugTraceX-Pro

cd $HOME/BugTraceX-Pro

# Install Python requirements
echo "📦 Installing dependencies..."
pip install -r requirements.txt > /dev/null 2>&1

# Create launcher
echo "⚙️ Creating launcher..."
cat <<EOF > /data/data/com.termux/files/usr/bin/bugtracex
#!/bin/bash
cd \$HOME/BugTraceX-Pro
python BugTraceX.py
EOF

chmod +x /data/data/com.termux/files/usr/bin/bugtracex

echo ""
echo "🎉 Installation Successful!"
echo "🚀 Run the tool using: bugtracex"
echo "🔐 VIP Protection Enabled!"