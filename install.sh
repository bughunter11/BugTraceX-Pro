#!/bin/bash
# BugTraceX Installer - ULTIMATE FIXED VERSION
# No Hang, No Errors, Direct Installation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}┏━━┳┳┳━━┳━━┳━┳━━┳━┳━┳┓┏┓${NC}"
echo -e "${BLUE}┃┏┓┃┃┃┏━╋┓┏┫╋┃┏┓┃┏┫┳┻┓┏┛${NC}"
echo -e "${BLUE}┃┏┓┃┃┃┗┓┃┃┃┃┓┫┣┫┃┗┫┻┳┛┗┓${NC}"
echo -e "${BLUE}┗━━┻━┻━━┛┗┛┗┻┻┛┗┻━┻━┻┛┗┛${NC}"
echo ""
echo -e "${GREEN}BugTraceX Installer - Fast & Stable${NC}"
echo ""

# Step 1: Cleanup
echo -e "${YELLOW}[1] Cleaning old files...${NC}"
rm -rf ~/BugTraceX-Pro ~/.bugtracex 2>/dev/null
mkdir -p ~/BugTraceX-Pro
cd ~/BugTraceX-Pro

# Step 2: Install Python modules FIRST
echo -e "${YELLOW}[2] Installing Python modules...${NC}"
pip3 install --user requests tldextract beautifulsoup4 colorama 2>/dev/null || \
python3 -m pip install --user requests tldextract beautifulsoup4 colorama 2>/dev/null || \
echo "Install modules manually: pip3 install requests tldextract beautifulsoup4 colorama"

# Step 3: DIRECT DOWNLOAD (NO CURL HANG)
echo -e "${YELLOW}[3] Downloading BugTraceX...${NC}"

# Create a Python downloader script
cat > downloader.py << 'EOF'
import urllib.request
import sys
import os

urls = [
    "https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py",
    "https://cdn.jsdelivr.net/gh/bughunter11/BugTraceX-Pro/BugTraceX.py",
    "https://github.com/bughunter11/BugTraceX-Pro/raw/main/BugTraceX.py"
]

for url in urls:
    try:
        print(f"Trying: {url.split('/')[2]}")
        urllib.request.urlretrieve(url, "BugTraceX.py")
        
        # Check if file is valid
        with open("BugTraceX.py", "r") as f:
            content = f.read(100)
            if "import" in content or "def" in content:
                print("Download successful!")
                sys.exit(0)
    except:
        continue

print("All downloads failed, creating basic version...")
with open("BugTraceX.py", "w") as f:
    f.write('''#!/usr/bin/env python3
print("BugTraceX - Install Python modules first:")
print("pip3 install requests tldextract beautifulsoup4 colorama")
print("Then re-run installer")
''')
sys.exit(1)
EOF

# Run downloader
python3 downloader.py
rm -f downloader.py

# Step 4: Make executable
chmod +x BugTraceX.py 2>/dev/null || true

# Step 5: Create launcher
echo -e "${YELLOW}[4] Creating launcher...${NC}"
cat > ~/.local/bin/bugtracex << 'EOF'
#!/bin/bash
cd ~/BugTraceX-Pro
if [ -f "BugTraceX.py" ]; then
    python3 -B BugTraceX.py "$@"
else
    echo "BugTraceX not found!"
    echo "Reinstall with: curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/install.sh | bash"
fi
EOF

chmod +x ~/.local/bin/bugtracex

# Step 6: Setup PATH
mkdir -p ~/.local/bin
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc 2>/dev/null || true

# Step 7: Test
echo -e "${YELLOW}[5] Testing installation...${NC}"
if [ -f "BugTraceX.py" ]; then
    echo -e "${GREEN}✅ BugTraceX installed successfully!${NC}"
    echo ""
    echo -e "${BLUE}🚀 Quick Start:${NC}"
    echo "  bugtracex    # Run BugTraceX"
    echo "  cd ~/BugTraceX-Pro && python3 BugTraceX.py"
    echo ""
    echo -e "${BLUE}📁 Location:${NC} ~/BugTraceX-Pro/"
    echo ""
    
    # Quick test
    read -p "Run BugTraceX now? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        python3 -B BugTraceX.py --help 2>/dev/null || python3 BugTraceX.py
    fi
else
    echo -e "${RED}❌ Download failed!${NC}"
    echo "Manual install:"
    echo "1. pip3 install requests tldextract beautifulsoup4 colorama"
    echo "2. Download from: https://github.com/bughunter11/BugTraceX-Pro"
fi

echo ""
echo -e "${GREEN}✨ Installation process completed!${NC}"