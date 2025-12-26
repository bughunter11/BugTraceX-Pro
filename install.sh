#!/bin/bash

# ====== SIMPLE ONE-CLICK INSTALL ======
clear
echo ""
echo "╔══════════════════════════════════════╗"
echo "║    BugTraceX - One Click Install    ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Function to print status
print_status() {
    echo -e "📦 $1"
}

# Function to check command
check_cmd() {
    command -v $1 >/dev/null 2>&1
}

# Check if Termux
if [ -d "/data/data/com.termux" ]; then
    print_status "Termux Environment Detected"
    
    # Install Python
    if ! check_cmd python; then
        print_status "Installing Python..."
        pkg update -y && pkg install python -y
    fi
    
    # Install pip
    if ! check_cmd pip; then
        print_status "Installing pip..."
        pkg install python-pip -y
    fi
    
    # Install required modules
    print_status "Installing dependencies..."
    pip install requests tldextract beautifulsoup4 colorama
    
else
    # For Linux/Mac
    print_status "Linux/Mac Environment Detected"
    
    if ! check_cmd python3 && ! check_cmd python; then
        print_status "Please install Python first!"
        echo "Linux: sudo apt install python3 python3-pip"
        echo "Mac: brew install python"
        exit 1
    fi
    
    # Use python3 if available, else python
    if check_cmd python3; then
        PY="python3"
        PIP="pip3"
    else
        PY="python"
        PIP="pip"
    fi
    
    print_status "Installing dependencies..."
    $PIP install requests tldextract beautifulsoup4 colorama
fi

# Download BugTraceX
print_status "Downloading BugTraceX..."
mkdir -p ~/BugTraceX-Pro
curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py -o ~/BugTraceX-Pro/BugTraceX.py

# Make executable
chmod +x ~/BugTraceX-Pro/BugTraceX.py

# Create launcher
print_status "Creating launcher..."
if [ -d "/data/data/com.termux" ]; then
    BIN_PATH="/data/data/com.termux/files/usr/bin"
else
    BIN_PATH="$HOME/.local/bin"
    mkdir -p $BIN_PATH
fi

cat > $BIN_PATH/bugtracex << 'EOF'
#!/bin/bash
cd ~/BugTraceX-Pro
if command -v python3 >/dev/null 2>&1; then
    python3 BugTraceX.py
else
    python BugTraceX.py
fi
EOF

chmod +x $BIN_PATH/bugtracex

# Add to PATH if needed
if [[ ":$PATH:" != *":$BIN_PATH:"* ]]; then
    echo "export PATH=\"\$PATH:$BIN_PATH\"" >> ~/.bashrc
    export PATH="$PATH:$BIN_PATH"
fi

# Create alias
echo "alias bt='bugtracex'" >> ~/.bashrc
source ~/.bashrc 2>/dev/null

# Success message
echo ""
echo "✅ INSTALLATION COMPLETE!"
echo ""
echo "📁 Installation: ~/BugTraceX-Pro/"
echo "🚀 Run: bugtracex"
echo "🔧 Shortcut: bt"
echo ""
echo "📞 Support: @raj_maker"
echo ""

# Auto-run
read -p "🚀 Run BugTraceX now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bugtracex
fi