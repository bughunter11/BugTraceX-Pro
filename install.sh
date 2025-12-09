#!/bin/bash

echo ""
echo "🔧 Installing BugTraceX Secure VIP Version v2.0..."
sleep 1

ERROR_LOG="$HOME/.bgx_install_v2.log"
touch "$ERROR_LOG" 2>/dev/null
log(){ echo -e "$1"; }

# ====== UNIVERSAL ENV DETECTION ======
detect_environment() {
    # Termux Detection
    if [ -d "/data/data/com.termux/files/usr" ] && [ -n "$PREFIX" ]; then
        echo "TERMUX"
        return
    fi
    
    # Android without Termux
    if [ -d "/system" ] && [ -f "/system/build.prop" ]; then
        echo "ANDROID"
        return
    fi
    
    # Linux Distro Detection
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
        case $ID in
            ubuntu|debian|kali|parrot|mint)
                echo "DEBIAN"
                ;;
            fedora|centos|rhel|almalinux|rocky)
                echo "RHEL"
                ;;
            arch|manjaro|endeavouros)
                echo "ARCH"
                ;;
            alpine)
                echo "ALPINE"
                ;;
            *)
                echo "LINUX"
                ;;
        esac
        return
    fi
    
    # macOS Detection
    if [ "$(uname)" = "Darwin" ]; then
        echo "MACOS"
        return
    fi
    
    # FreeBSD/OpenBSD
    if [ "$(uname)" = "FreeBSD" ] || [ "$(uname)" = "OpenBSD" ]; then
        echo "BSD"
        return
    fi
    
    # WSL (Windows Subsystem for Linux)
    if [ -f "/proc/version" ] && grep -qi "microsoft" /proc/version; then
        echo "WSL"
        return
    fi
    
    # Default
    echo "UNKNOWN"
}

ENV=$(detect_environment)
log "📌 Environment Detected: $ENV"

# ====== SETUP FOR EACH ENVIRONMENT ======
setup_environment() {
    case $ENV in
        TERMUX|ANDROID)
            BIN_PATH="$PREFIX/bin"
            PKG_MANAGER="pkg"
            PKG_UPDATE="pkg update -y -q"
            PKG_INSTALL="pkg install -y -q"
            PY_CMD="python"
            PIP_CMD="pip"
            
            # Termux storage setup
            if [ "$ENV" = "TERMUX" ] && [ ! -d "$HOME/storage" ]; then
                log "📂 Granting Storage Access..."
                termux-setup-storage >/dev/null 2>&1
                sleep 2
            fi
            ;;
        
        DEBIAN|LINUX|WSL)
            if [ "$EUID" -eq 0 ]; then
                BIN_PATH="/usr/local/bin"
            else
                BIN_PATH="$HOME/.local/bin"
            fi
            PKG_MANAGER="apt"
            PKG_UPDATE="apt update -y -qq"
            PKG_INSTALL="apt install -y -qq"
            PY_CMD="python3"
            PIP_CMD="pip3"
            ;;
        
        RHEL)
            if [ "$EUID" -eq 0 ]; then
                BIN_PATH="/usr/local/bin"
            else
                BIN_PATH="$HOME/.local/bin"
            fi
            PKG_MANAGER="yum"
            PKG_UPDATE="yum check-update -q"
            PKG_INSTALL="yum install -y -q"
            PY_CMD="python3"
            PIP_CMD="pip3"
            ;;
        
        ARCH)
            if [ "$EUID" -eq 0 ]; then
                BIN_PATH="/usr/local/bin"
            else
                BIN_PATH="$HOME/.local/bin"
            fi
            PKG_MANAGER="pacman"
            PKG_UPDATE="pacman -Sy --noconfirm"
            PKG_INSTALL="pacman -S --noconfirm"
            PY_CMD="python"
            PIP_CMD="pip"
            ;;
        
        MACOS)
            BIN_PATH="/usr/local/bin"
            PKG_MANAGER="brew"
            PKG_UPDATE="brew update"
            PKG_INSTALL="brew install"
            PY_CMD="python3"
            PIP_CMD="pip3"
            ;;
        
        ALPINE)
            if [ "$EUID" -eq 0 ]; then
                BIN_PATH="/usr/local/bin"
            else
                BIN_PATH="$HOME/.local/bin"
            fi
            PKG_MANAGER="apk"
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PY_CMD="python3"
            PIP_CMD="pip3"
            ;;
        
        *)
            # Universal fallback
            BIN_PATH="$HOME/.local/bin"
            PKG_MANAGER="unknown"
            PY_CMD="python3"
            PIP_CMD="pip3"
            log "⚠️  Unknown environment, using fallback settings"
            ;;
    esac
    
    # Create bin directory
    mkdir -p "$BIN_PATH"
    chmod 755 "$BIN_PATH" 2>/dev/null || true
    
    # Add to PATH if not already
    if [[ ":$PATH:" != *":$BIN_PATH:"* ]]; then
        export PATH="$PATH:$BIN_PATH"
    fi
}

setup_environment

# ====== CHECK AND INSTALL SYSTEM DEPENDENCIES ======
install_system_deps() {
    log "📦 Installing System Dependencies..."
    
    case $ENV in
        TERMUX|ANDROID)
            $PKG_UPDATE >> "$ERROR_LOG" 2>&1
            $PKG_INSTALL git curl wget python libxml2 libxslt >> "$ERROR_LOG" 2>&1 || true
            
            # Install Python if not present
            if ! command -v python >/dev/null 2>&1; then
                $PKG_INSTALL python >> "$ERROR_LOG" 2>&1
            fi
            ;;
        
        DEBIAN|LINUX|WSL)
            if command -v apt >/dev/null 2>&1; then
                $PKG_UPDATE >> "$ERROR_LOG" 2>&1
                $PKG_INSTALL git curl wget python3 python3-pip python3-venv >> "$ERROR_LOG" 2>&1 || true
                
                # Create python symlink
                if ! command -v python >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
                    ln -sf $(which python3) /usr/local/bin/python 2>/dev/null || true
                fi
            fi
            ;;
        
        RHEL)
            if command -v yum >/dev/null 2>&1; then
                $PKG_UPDATE >> "$ERROR_LOG" 2>&1
                $PKG_INSTALL git curl wget python3 python3-pip >> "$ERROR_LOG" 2>&1 || true
            elif command -v dnf >/dev/null 2>&1; then
                dnf update -y -q >> "$ERROR_LOG" 2>&1
                dnf install -y -q git curl wget python3 python3-pip >> "$ERROR_LOG" 2>&1 || true
            fi
            ;;
        
        ARCH)
            if command -v pacman >/dev/null 2>&1; then
                $PKG_UPDATE >> "$ERROR_LOG" 2>&1
                $PKG_INSTALL git curl wget python python-pip >> "$ERROR_LOG" 2>&1 || true
            fi
            ;;
        
        MACOS)
            if ! command -v brew >/dev/null 2>&1; then
                log "🍺 Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$ERROR_LOG" 2>&1
            fi
            $PKG_UPDATE >> "$ERROR_LOG" 2>&1
            $PKG_INSTALL git curl wget python3 >> "$ERROR_LOG" 2>&1 || true
            ;;
        
        ALPINE)
            if command -v apk >/dev/null 2>&1; then
                $PKG_UPDATE >> "$ERROR_LOG" 2>&1
                $PKG_INSTALL git curl wget python3 py3-pip >> "$ERROR_LOG" 2>&1 || true
            fi
            ;;
    esac
    
    # Verify Python installation
    if ! command -v $PY_CMD >/dev/null 2>&1; then
        log "⚠️  Python not found, trying alternative..."
        if command -v python3 >/dev/null 2>&1; then
            PY_CMD="python3"
        elif command -v python >/dev/null 2>&1; then
            PY_CMD="python"
        else
            log "❌ Python installation failed!"
            return 1
        fi
    fi
    
    # Verify pip
    if ! command -v $PIP_CMD >/dev/null 2>&1; then
        log "📦 Installing pip..."
        if [ "$PY_CMD" = "python3" ]; then
            curl -sSL https://bootstrap.pypa.io/get-pip.py | python3 >> "$ERROR_LOG" 2>&1
            PIP_CMD="pip3"
        else
            curl -sSL https://bootstrap.pypa.io/get-pip.py | python >> "$ERROR_LOG" 2>&1
            PIP_CMD="pip"
        fi
    fi
    
    log "✅ System dependencies installed"
    return 0
}

install_system_deps

# ====== CLEAN INSTALLATION ======
log "🧹 Cleaning old installation..."
rm -rf "$HOME/BugTraceX-Pro" 2>/dev/null
mkdir -p "$HOME/BugTraceX-Pro"

# ====== DOWNLOAD TOOL ======
log "📥 Downloading BugTraceX..."
DOWNLOAD_URLS=(
    "https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py"
    "https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/refs/heads/main/BugTraceX.py"
    "https://cdn.jsdelivr.net/gh/bughunter11/BugTraceX-Pro@main/BugTraceX.py"
)

DOWNLOAD_SUCCESS=0
for url in "${DOWNLOAD_URLS[@]}"; do
    log "  Trying: $(echo $url | cut -d'/' -f3)..."
    if curl -s -L "$url" --connect-timeout 20 --retry 2 -o "$HOME/BugTraceX-Pro/BugTraceX.py"; then
        if [ -s "$HOME/BugTraceX-Pro/BugTraceX.py" ]; then
            DOWNLOAD_SUCCESS=1
            log "  ✓ Download successful"
            break
        fi
    fi
    sleep 1
done

FILE="$HOME/BugTraceX-Pro/BugTraceX.py"

# Fallback if download fails
if [ $DOWNLOAD_SUCCESS -eq 0 ] || [ ! -s "$FILE" ]; then
    log "⚠️  Download failed, creating basic version..."
    
    # Create minimal working version
    cat > "$FILE" << 'EOF'
#!/usr/bin/env python3
import sys
import os

print("⚠️  Online download failed. Please check internet connection.")
print("📦 Reinstall with: curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/install.sh | bash")
print("📞 Contact: @raj_maker")
sys.exit(1)
EOF
fi

# Make executable
chmod +x "$FILE" 2>/dev/null

# ====== INSTALL PYTHON MODULES ======
log "🐍 Installing Python Modules..."

PYTHON_MODULES=(
    "requests"
    "tldextract"
    "beautifulsoup4"
    "colorama"
    "certifi"
    "chardet"
    "idna"
    "urllib3"
    "bs4"
)

# Try different pip installation methods
install_python_modules() {
    for module in "${PYTHON_MODULES[@]}"; do
        log "  Installing: $module"
        
        # Method 1: Using system pip
        if $PIP_CMD install "$module" --upgrade --user --quiet >> "$ERROR_LOG" 2>&1; then
            continue
        fi
        
        # Method 2: Using python -m pip
        if $PY_CMD -m pip install "$module" --upgrade --user --quiet >> "$ERROR_LOG" 2>&1; then
            continue
        fi
        
        # Method 3: Without --user (for virtual envs)
        if $PY_CMD -m pip install "$module" --upgrade --quiet >> "$ERROR_LOG" 2>&1; then
            continue
        fi
        
        log "  ⚠️  Failed: $module (check $ERROR_LOG)"
    done
}

install_python_modules

# ====== INSTALL GO TOOLS (OPTIONAL) ======
log "🌐 Installing optional security tools..."

install_go_tools() {
    # Check if Go is available
    if ! command -v go >/dev/null 2>&1; then
        log "  ⚠️  Go not installed (optional)"
        return 0
    fi
    
    # Set Go environment
    export GOPATH="$HOME/go"
    export PATH="$PATH:$GOPATH/bin"
    mkdir -p "$GOPATH"
    
    # Install subfinder
    log "  Installing subfinder..."
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest >> "$ERROR_LOG" 2>&1 || \
    echo "  ⚠️  Subfinder install failed" >> "$ERROR_LOG"
    
    # Install assetfinder
    log "  Installing assetfinder..."
    go install -v github.com/tomnomnom/assetfinder@latest >> "$ERROR_LOG" 2>&1 || \
    echo "  ⚠️  Assetfinder install failed" >> "$ERROR_LOG"
    
    # Copy to bin directory
    if [ -f "$GOPATH/bin/subfinder" ]; then
        cp "$GOPATH/bin/subfinder" "$BIN_PATH/" 2>/dev/null && chmod +x "$BIN_PATH/subfinder"
    fi
    if [ -f "$GOPATH/bin/assetfinder" ]; then
        cp "$GOPATH/bin/assetfinder" "$BIN_PATH/" 2>/dev/null && chmod +x "$BIN_PATH/assetfinder"
    fi
    
    return 0
}

install_go_tools

# ====== CREATE UNIVERSAL LAUNCHER ======
log "⚙️ Creating universal launcher..."

create_launcher() {
    cat <<EOF > "$BIN_PATH/bugtracex"
#!/bin/bash
# BugTraceX Universal Launcher v2.0
# Works on: Termux, Android, Linux, macOS, BSD, WSL

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
echo -e "\${CYAN}"
echo "  ┏━━┳┳┳━━┳━━┳━┳━━┳━┳━┳┓┏┓"
echo "  ┃┏┓┃┃┃┏━╋┓┏┫╋┃┏┓┃┏┫┳┻┓┏┛"
echo "  ┃┏┓┃┃┃┗┓┃┃┃┃┓┫┣┫┃┗┫┻┳┛┗┓"
echo "  ┗━━┻━┻━━┛┗┛┗┻┻┛┗┻━┻━┻┛┗┛"
echo -e "\${NC}"
echo -e "\${YELLOW}  BugTraceX VIP - Universal Edition\${NC}"
echo -e "\${BLUE}  Platform: \$(uname -s) | Python: \$(python3 --version 2>/dev/null || echo 'Not found')\${NC}"
echo ""

# Debug mode check
if [[ "\$1" == *debug* ]] || [[ "\$2" == *debug* ]]; then
    echo -e "\${RED}❌ Debug mode not allowed\${NC}"
    exit 1
fi

# Detect Python
detect_python() {
    if command -v python3 >/dev/null 2>&1; then
        echo "python3"
    elif command -v python >/dev/null 2>&1; then
        echo "python"
    elif command -v python2 >/dev/null 2>&1; then
        echo "python2"
    else
        echo "none"
    fi
}

PY=\$(detect_python)
if [ "\$PY" = "none" ]; then
    echo -e "\${RED}❌ Python not found!\${NC}"
    echo -e "\${YELLOW}💡 Install Python first:\${NC}"
    echo "  Termux: pkg install python"
    echo "  Ubuntu: sudo apt install python3"
    echo "  macOS: brew install python"
    exit 1
fi

# Check installation
TOOL_DIR="\$HOME/BugTraceX-Pro"
if [ ! -d "\$TOOL_DIR" ]; then
    echo -e "\${RED}❌ Installation not found!\${NC}"
    echo -e "\${YELLOW}📦 Install with:\${NC}"
    echo "  curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/install.sh | bash"
    exit 1
fi

MAIN_SCRIPT="\$TOOL_DIR/BugTraceX.py"
if [ ! -f "\$MAIN_SCRIPT" ]; then
    echo -e "\${RED}❌ Main script missing!\${NC}"
    exit 1
fi

# Set environment
export PATH="\$HOME/go/bin:\$HOME/.local/bin:\$PATH"
export PYTHONPATH="\$HOME/.local/lib/python*/site-packages:\$PYTHONPATH"

# Run
echo -e "\${GREEN}🚀 Launching BugTraceX...\${NC}"
echo -e "\${CYAN}══════════════════════════════════\${NC}"
cd "\$TOOL_DIR" || exit 1
exec \$PY "\$MAIN_SCRIPT"
EOF

    chmod +x "$BIN_PATH/bugtracex"
}

create_launcher

# ====== CREATE ALIASES FOR DIFFERENT SHELLS ======
log "🔗 Creating shell aliases..."

create_aliases() {
    # Bash
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "alias bugtracex=" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# BugTraceX Aliases" >> "$HOME/.bashrc"
            echo "alias bugtracex='$BIN_PATH/bugtracex'" >> "$HOME/.bashrc"
            echo "alias bt='bugtracex'" >> "$HOME/.bashrc"
        fi
    fi
    
    # Zsh
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "alias bugtracex=" "$HOME/.zshrc" 2>/dev/null; then
            echo "" >> "$HOME/.zshrc"
            echo "# BugTraceX Aliases" >> "$HOME/.zshrc"
            echo "alias bugtracex='$BIN_PATH/bugtracex'" >> "$HOME/.zshrc"
            echo "alias bt='bugtracex'" >> "$HOME/.zshrc"
        fi
    fi
    
    # Fish
    if [ -d "$HOME/.config/fish" ]; then
        echo "alias bugtracex='$BIN_PATH/bugtracex'" >> "$HOME/.config/fish/config.fish" 2>/dev/null
        echo "alias bt='bugtracex'" >> "$HOME/.config/fish/config.fish" 2>/dev/null
    fi
}

create_aliases

# ====== VERIFICATION ======
log "✅ Verification..."
echo ""

# Check installation
if [ -f "$BIN_PATH/bugtracex" ] && [ -f "$HOME/BugTraceX-Pro/BugTraceX.py" ]; then
    echo -e "🎉 ${GREEN}INSTALLATION SUCCESSFUL!${NC}"
    echo ""
    echo "📁 Installation: $HOME/BugTraceX-Pro/"
    echo "🚀 Launcher: $BIN_PATH/bugtracex"
    echo "🔧 Python: $($PY_CMD --version 2>/dev/null || echo 'Not found')"
    echo ""
    
    # Test Python modules
    echo "🔍 Testing dependencies..."
    if $PY_CMD -c "import requests, tldextract, bs4, colorama" 2>/dev/null; then
        echo "  ✓ All Python modules installed"
    else
        echo "  ⚠️  Some modules missing"
        echo "  Run: $PIP_CMD install requests tldextract beautifulsoup4 colorama"
    fi
    
    echo ""
    echo "💡 Quick Start:"
    echo "  1. Run: bugtracex"
    echo "  2. Or use alias: bt"
    echo ""
    echo "📞 Support: @raj_maker"
    echo "🌐 GitHub: https://github.com/bughunter11/BugTraceX-Pro"
    echo ""
    
    # Auto-run if in interactive terminal
    if [ -t 0 ]; then
        read -p "🚀 Run BugTraceX now? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Starting..."
            $BIN_PATH/bugtracex
        fi
    fi
    
else
    echo -e "⚠️ ${YELLOW}Installation partially completed${NC}"
    echo "Some components might be missing."
    echo "Check error log: $ERROR_LOG"
    echo ""
    echo "Manual fixes:"
    echo "1. Ensure Python is installed"
    echo "2. Run: pip install requests tldextract beautifulsoup4 colorama"
    echo "3. Download script manually from GitHub"
fi

echo ""
echo "══════════════════════════════════════════"
echo ""