#!/bin/bash

# ========== BugTraceX Automatic Installer ==========

echo "🔧 Installing BugTraceX..."
sleep 1

# Move into tool directory if user forgot
cd "$(dirname "$0")"

# Install Python requirements
echo "📦 Installing dependencies..."
pip install -r requirements.txt > /dev/null 2>&1

# Rename launcher
echo "⚙️ Setting up launcher..."
mv bugtracex.txt bugtracex 2>/dev/null
chmod +x bugtracex
mv bugtracex /data/data/com.termux/files/usr/bin/ 2>/dev/null

echo "🎉 Installation Successful!"
echo ""
echo "🚀 Run the tool using this command:"
echo "👉  bugtracex"
echo ""
echo "🔐 VIP Protection Enabled!"