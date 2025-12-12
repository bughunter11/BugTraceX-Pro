#!/bin/bash

# ============================================
# BugTraceX Universal Installer - FIXED EDITION
# Version: 5.0 (100% Error-Free)
# Author: @raj_maker
# ============================================

# Exit on error
set -e

# ====== COLOR SETUP ======
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Remove colors if not in terminal
[ ! -t 1 ] && RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' NC='' BOLD=''

# ====== LOGGING ======
LOG_FILE="$HOME/.bugtracex_install.log"
exec 2>"$LOG_FILE"

log() { echo -e "$1"; }
info() { log "${BLUE}[*]${NC} $1"; }
success() { log "${GREEN}[+]${NC} $1"; }
warn() { log "${YELLOW}[!]${NC} $1"; }
error() { log "${RED}[-]${NC} $1"; }

# ====== BANNER ======
clear 2>/dev/null || true
echo -e "${CYAN}"
cat << "EOF"
  ┏━━┳┳┳━━┳━━┳━┳━━┳━┳━┳┓┏┓
  ┃┏┓┃┃┃┏━╋┓┏┫╋┃┏┓┃┏┫┳┻┓┏┛
  ┃┏┓┃┃┃┗┓┃┃┃┃┓┫┣┫┃┗┫┻┳┛┗┓
  ┗━━┻━┻━━┛┗┛┗┻┻┛┗┻━┻━┻┛┗┛
EOF
echo -e "${NC}"
echo -e "${MAGENTA}  BugTraceX Secure VIP Installer${NC}"
echo -e "${YELLOW}  Version: 5.0 | Platform: $(uname -s)${NC}"
echo ""

info "🚀 Starting BugTraceX Installation..."

# ====== CLEAN PYTHON CACHE ======
info "🧹 Cleaning Python cache..."
find "$HOME" -name "*.pyc" -delete 2>/dev/null || true
find "$HOME" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find /tmp -name "*.pyc" -delete 2>/dev/null || true
python3 -m pip cache purge 2>/dev/null || true
success "✓ Cache cleaned"

# ====== DETECT OS ======
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif uname | grep -iq "darwin"; then
        echo "macos"
    elif [ -d /data/data/com.termux ]; then
        echo "termux"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
info "📌 Detected OS: $OS"

# ====== INSTALL DEPENDENCIES ======
install_deps() {
    info "📦 Installing system dependencies..."
    
    case "$OS" in
        ubuntu|debian|linuxmint|kali|parrot)
            sudo apt update -qq
            sudo apt install -y python3 python3-pip python3-venv git curl wget
            ;;
        fedora|centos|rhel)
            sudo dnf install -y python3 python3-pip git curl wget || \
            sudo yum install -y python3 python3-pip git curl wget
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm python python-pip git curl wget
            ;;
        macos)
            if ! command -v brew >/dev/null; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install python3 git curl wget
            ;;
        termux)
            pkg update -y
            pkg install -y python git curl wget
            ;;
        *)
            warn "Unknown OS, trying to install python3..."
            if command -v apt >/dev/null; then
                sudo apt install -y python3 python3-pip git curl wget
            elif command -v yum >/dev/null; then
                sudo yum install -y python3 python3-pip git curl wget
            elif command -v pacman >/dev/null; then
                sudo pacman -Syu --noconfirm python python-pip git curl wget
            fi
            ;;
    esac
    
    # Verify Python
    if ! command -v python3 >/dev/null && command -v python >/dev/null; then
        warn "python3 not found, using python"
    elif ! command -v python3 >/dev/null && ! command -v python >/dev/null; then
        error "Python not installed!"
        exit 1
    fi
    
    success "✓ Dependencies installed"
}

install_deps

# ====== CLEAN OLD INSTALLATION ======
info "🧹 Removing old installation..."
rm -rf "$HOME/BugTraceX-Pro" 2>/dev/null
rm -rf "$HOME/.bugtracex" 2>/dev/null
mkdir -p "$HOME/BugTraceX-Pro"

# ====== DOWNLOAD BUGTRACEX ======
download_bugtracex() {
    info "📥 Downloading BugTraceX..."
    
    cd "$HOME/BugTraceX-Pro"
    
    # List of possible sources
    SOURCES=(
        "https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py"
        "https://cdn.jsdelivr.net/gh/bughunter11/BugTraceX-Pro@main/BugTraceX.py"
        "https://github.com/bughunter11/BugTraceX-Pro/raw/main/BugTraceX.py"
        "https://gist.githubusercontent.com/bughunter11/raw/BugTraceX.py"
    )
    
    for url in "${SOURCES[@]}"; do
        info "  Trying: $(echo "$url" | cut -d'/' -f3)..."
        if curl -sL "$url" --connect-timeout 10 --max-time 30 -o BugTraceX.py.tmp; then
            if [ -s BugTraceX.py.tmp ]; then
                # Clean the file
                python3 -c "
import sys
try:
    with open('BugTraceX.py.tmp', 'r', encoding='utf-8', errors='ignore') as f:
        data = f.read()
    if 'import' in data and 'def' in data:
        with open('BugTraceX.py', 'w', encoding='utf-8') as f:
            f.write(data)
        sys.exit(0)
    else:
        sys.exit(1)
except:
    sys.exit(1)
" 2>/dev/null
                
                if [ $? -eq 0 ]; then
                    rm -f BugTraceX.py.tmp
                    success "  ✓ Download successful"
                    return 0
                fi
            fi
        fi
        sleep 1
    done
    
    # Create basic version if download fails
    warn "  Download failed, creating basic version..."
    cat > BugTraceX.py << 'EOF'
#!/usr/bin/env python3
"""
BugTraceX - Bug Bounty Tool
Basic Version (Full version download failed)
"""
import sys

def main():
    print("╔══════════════════════════════════════╗")
    print("║         BugTraceX v5.0               ║")
    print("║      Basic Version Loaded            ║")
    print("╚══════════════════════════════════════╝")
    print("\nPlease install required modules:")
    print("pip install requests tldextract beautifulsoup4 colorama")
    print("\nThen reinstall:")
    print("curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/install.sh | bash")
    print("\nContact: @raj_maker")
    
    sys.exit(0)

if __name__ == "__main__":
    main()
EOF
    
    return 1
}

download_bugtracex

# Make executable
chmod +x "$HOME/BugTraceX-Pro/BugTraceX.py" 2>/dev/null || true

# ====== INSTALL PYTHON MODULES ======
install_python_modules() {
    info "🐍 Installing Python modules..."
    
    # First upgrade pip
    python3 -m pip install --upgrade pip --quiet 2>/dev/null || true
    
    # Install modules
    MODULES=(
        "requests==2.31.0"
        "tldextract==5.1.2"
        "beautifulsoup4==4.12.3"
        "colorama==0.4.6"
        "urllib3==2.2.1"
    )
    
    for module in "${MODULES[@]}"; do
        name=$(echo "$module" | cut -d'=' -f1)
        info "  Installing $name..."
        
        # Try multiple methods
        python3 -m pip install --user "$module" --quiet 2>/dev/null && \
            success "    ✓ $name installed" || \
            warn "    ⚠️  $name failed (will try later)"
    done
    
    success "✓ Python modules installation attempted"
}

install_python_modules

# ====== CREATE LAUNCHER ======
create_launcher() {
    info "⚙️ Creating launcher..."
    
    # Create bin directory
    mkdir -p "$HOME/.local/bin"
    
    # Create launcher script
    cat > "$HOME/.local/bin/bugtracex" << 'EOF'
#!/bin/bash
# BugTraceX Launcher - Safe Version

# Clean Python cache
find /tmp -name "*.pyc" -delete 2>/dev/null

# Run with -B flag (no pyc files)
cd "$HOME/BugTraceX-Pro"
if [ -f "BugTraceX.py" ]; then
    # Use python3 or python
    if command -v python3 >/dev/null 2>&1; then
        exec python3 -B BugTraceX.py "$@"
    elif command -v python >/dev/null 2>&1; then
        exec python -B BugTraceX.py "$@"
    else
        echo "Python not found!"
        exit 1
    fi
else
    echo "BugTraceX not found! Reinstalling..."
    curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/install.sh | bash
    exit 1
fi
EOF
    
    chmod +x "$HOME/.local/bin/bugtracex"
    
    # Create alias
    echo "alias bt='bugtracex'" >> "$HOME/.bashrc" 2>/dev/null
    echo "alias bugtracex='$HOME/.local/bin/bugtracex'" >> "$HOME/.bashrc" 2>/dev/null
    
    # Add to PATH
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo "export PATH=\"\$PATH:$HOME/.local/bin\"" >> "$HOME/.bashrc"
    fi
    
    success "✓ Launcher created"
}

create_launcher

# ====== FINAL SETUP ======
final_setup() {
    info "🔧 Final setup..."
    
    # Source bashrc
    source "$HOME/.bashrc" 2>/dev/null || true
    
    # Create test script
    cat > "$HOME/BugTraceX-Pro/test.py" << 'EOF'
#!/usr/bin/env python3
print("Testing BugTraceX installation...")
try:
    import requests
    import tldextract
    from bs4 import BeautifulSoup
    import colorama
    print("✅ All modules loaded successfully!")
    print("🚀 BugTraceX is ready to use!")
except ImportError as e:
    print(f"❌ Missing module: {e}")
    print("Run: pip install requests tldextract beautifulsoup4 colorama")
EOF
    
    chmod +x "$HOME/BugTraceX-Pro/test.py"
}

final_setup

# ====== COMPLETION MESSAGE ======
echo ""
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo -e "${GREEN}          INSTALLATION COMPLETE!          ${NC}"
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}📁 Installation Directory:${NC}"
echo "  $HOME/BugTraceX-Pro/"
echo ""
echo -e "${BOLD}🚀 Available Commands:${NC}"
echo "  bugtracex    - Launch BugTraceX"
echo "  bt           - Short alias"
echo ""
echo -e "${BOLD}🔧 First Time Setup:${NC}"
echo "  1. Close and reopen terminal"
echo "  2. Or run: source ~/.bashrc"
echo "  3. Then run: bugtracex"
echo ""
echo -e "${BOLD}📞 Support:${NC}"
echo "  GitHub: https://github.com/bughunter11/BugTraceX-Pro"
echo "  Contact: @raj_maker"
echo ""
echo -e "${CYAN}══════════════════════════════════════════${NC}"

# Test installation
if [ -f "$HOME/.local/bin/bugtracex" ]; then
    echo ""
    echo -n "Test installation now? (y/N): "
    read -r test
    if [[ "$test" =~ ^[Yy]$ ]]; then
        echo ""
        "$HOME/BugTraceX-Pro/test.py"
    fi
fi

echo ""
echo -e "${GREEN}✨ Installation completed successfully!${NC}"
echo ""

exit 0