#!/bin/bash

echo ""
echo "🔧 Installing BugTraceX Secure VIP Version v2.0 (Fixed for Termux)..."
sleep 1

# ====== COLORS ======
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

ERROR_LOG="$HOME/.bgx_install_v2.log"
touch "$ERROR_LOG" 2>/dev/null
log(){ echo -e "$1"; }

# ====== UNIVERSAL ENV DETECTION ======
detect_environment() {
    # Termux Detection (Fixed)
    if [ -d "/data/data/com.termux/files/usr" ] || [ -n "$PREFIX" ] || echo "$PATH" | grep -q "com.termux"; then
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
            PKG_UPDATE="pkg update -y"
            PKG_INSTALL="pkg install -y"
            PY_CMD="python"
            PIP_CMD="pip"
            
            # Termux storage setup
            if [ "$ENV" = "TERMUX" ] && [ ! -d "$HOME/storage" ]; then
                log "📂 Granting Storage Access..."
                termux-setup-storage >/dev/null 2>&1
                sleep 1
            fi
            
            # Fix for Termux PATH
            export PATH="$PATH:$PREFIX/bin"
            ;;
        
        DEBIAN|LINUX|WSL)
            if [ "$EUID" -eq 0 ]; then
                BIN_PATH="/usr/local/bin"
            else
                BIN_PATH="$HOME/.local/bin"
            fi
            PKG_MANAGER="apt"
            PKG_UPDATE="apt update -y"
            PKG_INSTALL="apt install -y"
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
            PKG_UPDATE="yum check-update -y"
            PKG_INSTALL="yum install -y"
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
    mkdir -p "$BIN_PATH" 2>/dev/null
    chmod 755 "$BIN_PATH" 2>/dev/null || true
    
    # Add to PATH if not already
    if [[ ":$PATH:" != *":$BIN_PATH:"* ]]; then
        export PATH="$PATH:$BIN_PATH"
    fi
}

setup_environment

# ====== CHECK AND INSTALL SYSTEM DEPENDENCIES ======
install_system_deps() {
    log "📦 Installing System Dependencies for $ENV..."
    
    case $ENV in
        TERMUX|ANDROID)
            log "🔄 Updating Termux packages..."
            $PKG_UPDATE >> "$ERROR_LOG" 2>&1 || true
            
            log "📥 Installing Python and essentials..."
            $PKG_INSTALL python git curl wget libxml2 libxslt >> "$ERROR_LOG" 2>&1 || true
            
            # SPECIAL FIX FOR TERMUX: Python is always 'python' in Termux
            PY_CMD="python"
            
            # Verify Python installation
            if ! command -v python >/dev/null 2>&1; then
                log "❌ Python installation failed in Termux!"
                log "📌 Trying alternative method..."
                
                # Alternative install method
                pkg reinstall python -y >> "$ERROR_LOG" 2>&1
                
                if ! command -v python >/dev/null 2>&1; then
                    log "🔥 CRITICAL: Python not found!"
                    log "📋 Manual fix required:"
                    log "   1. pkg update && pkg upgrade"
                    log "   2. pkg install python -y"
                    log "   3. Then re-run this script"
                    return 1
                fi
            fi
            
            # Install pip if not present
            if ! command -v pip >/dev/null 2>&1; then
                log "📦 Installing pip for Termux..."
                $PKG_INSTALL python-pip >> "$ERROR_LOG" 2>&1 || \
                python -m ensurepip --upgrade >> "$ERROR_LOG" 2>&1
            fi
            
            PIP_CMD="pip"
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
    
    # Final Python verification
    if ! command -v $PY_CMD >/dev/null 2>&1; then
        log "⚠️  Python not found, trying all possibilities..."
        # Try all possible python commands
        for cmd in python python3 python3.11 python3.10 python3.9 python3.8; do
            if command -v $cmd >/dev/null 2>&1; then
                PY_CMD="$cmd"
                log "✓ Found Python: $PY_CMD"
                break
            fi
        done
        
        if [ "$PY_CMD" = "unknown" ]; then
            log "❌ Python installation failed completely!"
            return 1
        fi
    fi
    
    # Verify pip
    if ! command -v $PIP_CMD >/dev/null 2>&1; then
        log "📦 Installing pip via get-pip.py..."
        curl -sSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
        $PY_CMD /tmp/get-pip.py --user >> "$ERROR_LOG" 2>&1
        rm -f /tmp/get-pip.py
        
        # Update PIP_CMD based on PY_CMD
        if [[ "$PY_CMD" == *"3"* ]]; then
            PIP_CMD="pip3"
        else
            PIP_CMD="pip"
        fi
    fi
    
    log "✅ System dependencies check completed"
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
    if curl -s -L "$url" --connect-timeout 30 --retry 3 -o "$HOME/BugTraceX-Pro/BugTraceX.py"; then
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
    log "⚠️  Download failed, using fallback script..."
    
    # Create working fallback version
    cat > "$FILE" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import subprocess

def check_dependencies():
    missing = []
    try:
        import requests
    except:
        missing.append("requests")
    try:
        import tldextract
    except:
        missing.append("tldextract")
    try:
        from bs4 import BeautifulSoup
    except:
        missing.append("beautifulsoup4")
    try:
        import colorama
    except:
        missing.append("colorama")
    
    return missing

def main():
    print("╔══════════════════════════════════════════╗")
    print("║         BugTraceX VIP Edition           ║")
    print("╚══════════════════════════════════════════╝")
    print()
    print("⚠️  Online download incomplete")
    print()
    
    missing = check_dependencies()
    if missing:
        print("❌ Missing dependencies:")
        for dep in missing:
            print(f"   - {dep}")
        print()
        print("📦 Install manually:")
        print("   pip install " + " ".join(missing))
        print()
        print("🔄 Then re-run: bugtracex")
    else:
        print("✅ All dependencies installed!")
        print("📞 Contact: @raj_maker")
        print("🌐 Reinstall: curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/install.sh | bash")
    
    sys.exit(1)

if __name__ == "__main__":
    main()
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

# Improved module installation with better error handling
install_python_modules() {
    local modules_installed=0
    local modules_failed=0
    
    for module in "${PYTHON_MODULES[@]}"; do
        log "  Installing: $module"
        
        # Method 1: Using pip with --user flag
        if $PIP_CMD install "$module" --upgrade --user --quiet >> "$ERROR_LOG" 2>&1; then
            ((modules_installed++))
            continue
        fi
        
        # Method 2: Using python -m pip
        if $PY_CMD -m pip install "$module" --upgrade --user --quiet >> "$ERROR_LOG" 2>&1; then
            ((modules_installed++))
            continue
        fi
        
        # Method 3: Without --user (for system-wide or virtual envs)
        if $PY_CMD -m pip install "$module" --upgrade --quiet >> "$ERROR_LOG" 2>&1; then
            ((modules_installed++))
            continue
        fi
        
        # Method 4: Last resort - try with --break-system-packages (for newer pip)
        if $PIP_CMD install "$module" --break-system-packages --quiet >> "$ERROR_LOG" 2>&1; then
            ((modules_installed++))
            continue
        fi
        
        ((modules_failed++))
        log "  ⚠️  Failed: $module"
    done
    
    log "  📊 Result: $modules_installed installed, $modules_failed failed"
    
    # If all failed, try one essential module with verbose output
    if [ $modules_installed -eq 0 ]; then
        log "  🔧 Trying emergency install of requests..."
        $PIP_CMD install requests 2>&1 | tail -5 >> "$ERROR_LOG"
    fi
    
    return $modules_failed
}

log "📦 Installing required Python packages..."
install_python_modules

# ====== CREATE UNIVERSAL LAUNCHER ======
log "⚙️ Creating universal launcher..."

create_launcher() {
    cat <<EOF > "$BIN_PATH/bugtracex"
#!/bin/bash
# BugTraceX Universal Launcher v2.1 (Termux Fixed)
# Works on: Termux, Android, Linux, macOS, BSD, WSL

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
# Banner
echo -e "\${CYAN}"
echo "  ┏━━┳┳┳━━┳━━┳━┳━━┳━┳━┳┓┏┓"
echo "  ┃┏┓┃┃┃┏━╋┓┏┫╋┃┏┓┃┏┫┳┻┓┏┛"
echo "  ┃┏┓┃┃┃┗┓┃┃┃┃┓┫┣┫┃┗┫┻┳┛┗┓"
echo "  ┗━━┻━┻━━┛┗┛┗┻┻┛┗┻━┻━┻┛┗┛"
echo -e "\${NC}"
echo -e "\${YELLOW}  BugTraceX VIP - Termux Edition v2.1\${NC}"

# Detect environment
if [ -d "/data/data/com.termux/files/usr" ]; then
    echo -e "\${BLUE}  Platform: Termux (Android)\${NC}"
elif [ "$(uname)" = "Linux" ]; then
    echo -e "\${BLUE}  Platform: Linux\${NC}"
elif [ "$(uname)" = "Darwin" ]; then
    echo -e "\${BLUE}  Platform: macOS\${NC}"
else
    echo -e "\${BLUE}  Platform: $(uname)\${NC}"
fi

# Detect Python
detect_python() {
    # Try multiple python commands
    for cmd in python python3 python3.11 python3.10 python3.9; do
        if command -v \$cmd >/dev/null 2>&1; then
            echo "\$cmd"
            return
        fi
    done
    echo "none"
}

PY=\$(detect_python)
if [ "\$PY" = "none" ]; then
    echo -e "\n\${RED}❌ Python not found!\${NC}"
    echo -e "\${YELLOW}💡 Install Python first:\${NC}"
    if [ -d "/data/data/com.termux/files/usr" ]; then
        echo "  Termux: pkg install python -y"
    elif [ -f "/etc/debian_version" ]; then
        echo "  Debian/Ubuntu: sudo apt install python3 -y"
    elif [ -f "/etc/redhat-release" ]; then
        echo "  RHEL/Fedora: sudo yum install python3 -y"
    else
        echo "  Install Python 3 from: https://python.org"
    fi
    exit 1
fi

# Show Python version
PY_VERSION=\$(\$PY --version 2>&1 || echo "Unknown")
echo -e "\${BLUE}  Python: \$PY_VERSION\${NC}"
echo ""

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
    echo -e "\${YELLOW}📥 Download manually:\${NC}"
    echo "  curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py -o ~/BugTraceX-Pro/BugTraceX.py"
    exit 1
fi

# Check dependencies
echo -e "\${YELLOW}🔍 Checking dependencies...\${NC}"
if \$PY -c "import requests, tldextract, bs4, colorama" 2>/dev/null; then
    echo -e "\${GREEN}✓ All dependencies installed\${NC}"
else
    echo -e "\${RED}⚠️  Some dependencies missing\${NC}"
    echo -e "\${YELLOW}Installing missing dependencies...\${NC}"
    
    # Try to install missing modules
    for module in requests tldextract beautifulsoup4 colorama; do
        if ! \$PY -c "import \$module" 2>/dev/null; then
            echo -n "  Installing \$module... "
            if pip install \$module --user 2>/dev/null || pip3 install \$module --user 2>/dev/null; then
                echo -e "\${GREEN}✓\${NC}"
            else
                echo -e "\${RED}✗\${NC}"
            fi
        fi
    done
fi

# Set environment
export PATH="\$HOME/.local/bin:\$PATH"
if [ -d "/data/data/com.termux/files/usr" ]; then
    export PATH="\$PATH:/data/data/com.termux/files/usr/bin"
fi

# Run
echo ""
echo -e "\${GREEN}🚀 Launching BugTraceX...\${NC}"
echo -e "\${CYAN}══════════════════════════════════\${NC}"
echo ""
cd "\$TOOL_DIR" || { echo -e "\${RED}Failed to enter tool directory\${NC}"; exit 1; }

# Execute with proper python
exec \$PY "\$MAIN_SCRIPT" "\$@"
EOF

    chmod +x "$BIN_PATH/bugtracex"
    log "✓ Launcher created at: $BIN_PATH/bugtracex"
}

create_launcher

# ====== CREATE ALIASES FOR DIFFERENT SHELLS ======
log "🔗 Creating shell aliases..."

create_aliases() {
    # Bash (Termux uses bash by default)
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "alias bugtracex=" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# BugTraceX Aliases" >> "$HOME/.bashrc"
            echo "alias bugtracex='$BIN_PATH/bugtracex'" >> "$HOME/.bashrc"
            echo "alias bt='bugtracex'" >> "$HOME/.bashrc"
            echo "alias bugtracex-update='curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/install.sh | bash'" >> "$HOME/.bashrc"
        fi
    else
        # Create .bashrc if not exists
        echo "# BugTraceX Aliases" > "$HOME/.bashrc"
        echo "alias bugtracex='$BIN_PATH/bugtracex'" >> "$HOME/.bashrc"
        echo "alias bt='bugtracex'" >> "$HOME/.bashrc"
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
    
    # Fish (unlikely in Termux, but just in case)
    if [ -d "$HOME/.config/fish" ]; then
        echo "alias bugtracex='$BIN_PATH/bugtracex'" >> "$HOME/.config/fish/config.fish" 2>/dev/null
        echo "alias bt='bugtracex'" >> "$HOME/.config/fish/config.fish" 2>/dev/null
    fi
    
    # Apply aliases to current session
    alias bugtracex="$BIN_PATH/bugtracex" 2>/dev/null
    alias bt="$BIN_PATH/bugtracex" 2>/dev/null
}

create_aliases

# ====== VERIFICATION ======
echo ""
log "✅ Verification..."
echo ""

# Check installation
if [ -f "$BIN_PATH/bugtracex" ] && [ -f "$HOME/BugTraceX-Pro/BugTraceX.py" ]; then
    echo -e "${GREEN}🎉 INSTALLATION SUCCESSFUL!${NC}"
    echo ""
    echo "📁 Installation: $HOME/BugTraceX-Pro/"
    echo "🚀 Launcher: $BIN_PATH/bugtracex"
    
    # Show Python info
    if command -v $PY_CMD >/dev/null 2>&1; then
        echo "🔧 Python: $($PY_CMD --version 2>&1)"
    else
        echo "🔧 Python: Not found (please install manually)"
    fi
    
    echo ""
    echo "🔍 Testing dependencies..."
    if $PY_CMD -c "import requests, tldextract, bs4, colorama" 2>/dev/null; then
        echo -e "  ${GREEN}✓ All Python modules installed${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Some modules missing${NC}"
        echo "  Run manually: $PIP_CMD install requests tldextract beautifulsoup4 colorama"
    fi
    
    echo ""
    echo -e "${CYAN}💡 Quick Start:${NC}"
    echo "  1. Run: ${GREEN}bugtracex${NC}"
    echo "  2. Or use alias: ${GREEN}bt${NC}"
    echo ""
    echo "📞 Support: @raj_maker"
    echo "🌐 GitHub: https://github.com/bughunter11/BugTraceX-Pro"
    echo ""
    
    # Auto-run if in interactive terminal
    if [ -t 0 ] && [ -f "$BIN_PATH/bugtracex" ]; then
        read -p "🚀 Run BugTraceX now? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Starting BugTraceX..."
            sleep 1
            $BIN_PATH/bugtracex
        else
            echo ""
            echo -e "${YELLOW}💡 You can run it later with: bugtracex${NC}"
        fi
    fi
    
else
    echo -e "${YELLOW}⚠️ Installation partially completed${NC}"
    echo "Some components might be missing."
    echo "Check error log: $ERROR_LOG"
    echo ""
    echo -e "${RED}Manual fixes:${NC}"
    echo "1. Install Python: pkg install python -y"
    echo "2. Install pip: pkg install python-pip -y"
    echo "3. Install modules: pip install requests tldextract beautifulsoup4 colorama"
    echo "4. Download script:"
    echo "   curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py -o ~/BugTraceX-Pro/BugTraceX.py"
fi

echo ""
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo ""

# Clean up
rm -f /tmp/get-pip.py 2>/dev/null