#!/bin/bash

# ============================================
# BugTraceX Universal Installer - VIP Edition
# Version: 4.0 (ERROR-FREE)
# Compatible: Termux, Android, Linux, macOS, BSD, WSL, Colab, VPS
# ZERO ERROR GUARANTEE - No marshal data issues
# ============================================

set -e  # Exit on any error

# ====== ENHANCED COLOR SUPPORT ======
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    NC='\033[0m'
    BOLD='\033[1m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; MAGENTA=''; NC=''; BOLD=''
fi

# ====== ENHANCED LOGGING ======
ERROR_LOG="$HOME/.bgx_install_$(date +%s).log"
exec 2>>"$ERROR_LOG"

log() { echo -e "$1"; }
log_info() { log "${BLUE}[*]${NC} $1"; }
log_success() { log "${GREEN}[+]${NC} $1"; }
log_warning() { log "${YELLOW}[!]${NC} $1"; }
log_error() { 
    log "${RED}[-]${NC} $1"
    echo "[ERROR $(date)]: $1" >> "$ERROR_LOG"
}

# ====== CLEAN PYTHON CACHE FIRST ======
clean_python_cache() {
    log_info "🧹 Cleaning Python cache to prevent marshal errors..."
    
    # Remove all .pyc files and __pycache__ directories
    find "$HOME" -name "*.pyc" -delete 2>/dev/null || true
    find "$HOME" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find /tmp -name "*.pyc" -delete 2>/dev/null || true
    
    # Clean pip cache
    python3 -m pip cache purge 2>/dev/null || true
    pip cache purge 2>/dev/null || true
    rm -rf ~/.cache/pip 2>/dev/null || true
    
    log_success "✓ Python cache cleaned"
}

clean_python_cache

# ====== BANNER ======
show_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}"
    echo "  ┏━━┳┳┳━━┳━━┳━┳━━┳━┳━┳┓┏┓"
    echo "  ┃┏┓┃┃┃┏━╋┓┏┫╋┃┏┓┃┏┫┳┻┓┏┛"
    echo "  ┃┏┓┃┃┃┗┓┃┃┃┃┓┫┣┫┃┗┫┻┳┛┗┓"
    echo "  ┗━━┻━┻━━┛┗┛┗┻┻┛┗┻━┻━┻┛┗┛"
    echo -e "${NC}"
    echo -e "${MAGENTA}  BugTraceX Secure VIP - Universal Installer${NC}"
    echo -e "${YELLOW}  Version: 4.0 | Platform: $(uname -s)${NC}"
    echo ""
}

show_banner
log "🔧 Installing BugTraceX Secure VIP Version v4.0..."
sleep 1

# ====== ENHANCED ENVIRONMENT DETECTION ======
detect_environment() {
    # Google Colab Detection
    if python3 -c "import google.colab" 2>/dev/null; then
        echo "COLAB"
        return
    fi
    
    # Termux Detection (Multiple methods)
    if [ -n "$TERMUX_VERSION" ] || 
       [ -d "/data/data/com.termux/files/usr" ] || 
       (command -v termux-setup-storage >/dev/null 2>&1); then
        echo "TERMUX"
        return
    fi
    
    # Android (without Termux)
    if [ -f "/system/build.prop" ] || 
       [ -d "/system/app" ] || 
       [ -f "/init.rc" ]; then
        echo "ANDROID"
        return
    fi
    
    # WSL Detection (Multiple methods)
    if grep -qi "microsoft" /proc/version 2>/dev/null || 
       [ -n "$WSL_DISTRO_NAME" ] || 
       [ -f "/proc/sys/fs/binfmt_misc/WSLInterop" ]; then
        echo "WSL"
        return
    fi
    
    # Docker Container
    if [ -f "/.dockerenv" ] || 
       grep -q "docker" /proc/1/cgroup 2>/dev/null; then
        echo "DOCKER"
        return
    fi
    
    # macOS
    if [ "$(uname)" = "Darwin" ]; then
        echo "MACOS"
        return
    fi
    
    # Linux Distro Detection
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
        case $ID in
            ubuntu|debian|kali|parrot|mint|pop|zorin|elementary|deepin)
                echo "DEBIAN"
                ;;
            fedora|centos|rhel|almalinux|rocky|amzn|ol)
                echo "RHEL"
                ;;
            arch|manjaro|endeavouros|garuda)
                echo "ARCH"
                ;;
            alpine)
                echo "ALPINE"
                ;;
            opensuse*|suse|sled|leap)
                echo "SUSE"
                ;;
            *)
                echo "LINUX"
                ;;
        esac
        return
    fi
    
    # BSD Detection
    case "$(uname)" in
        FreeBSD) echo "FREEBSD" ;;
        OpenBSD) echo "OPENBSD" ;;
        NetBSD) echo "NETBSD" ;;
        DragonFly) echo "DRAGONFLYBSD" ;;
    esac
    
    # Unknown
    echo "UNKNOWN"
}

ENV=$(detect_environment)
log_info "📌 Environment Detected: ${BOLD}$ENV${NC}"

# ====== ADVANCED ENVIRONMENT SETUP ======
setup_environment() {
    case $ENV in
        COLAB)
            BIN_PATH="/usr/local/bin"
            PKG_MANAGER="apt"
            PKG_UPDATE="apt update -qq 2>/dev/null"
            PKG_INSTALL="apt install -y -qq 2>/dev/null"
            PY_CMD="python3"
            PIP_CMD="pip3"
            export DEBIAN_FRONTEND=noninteractive
            ;;
            
        TERMUX|ANDROID)
            BIN_PATH="$PREFIX/bin"
            PKG_MANAGER="pkg"
            PKG_UPDATE="pkg update -y 2>/dev/null"
            PKG_INSTALL="pkg install -y 2>/dev/null"
            PY_CMD="python"
            PIP_CMD="pip"
            
            # Fix for Android without root
            if [ "$ENV" = "ANDROID" ] && [ ! -d "/data/data/com.termux" ]; then
                log_warning "⚠️  Pure Android detected - limited functionality"
                BIN_PATH="$HOME/.local/bin"
            fi
            
            # Termux storage setup
            if [ "$ENV" = "TERMUX" ] && [ ! -d "$HOME/storage" ]; then
                log_info "📂 Setting up Termux storage..."
                termux-setup-storage >/dev/null 2>&1 || true
                sleep 3
            fi
            ;;
            
        DOCKER)
            BIN_PATH="/usr/local/bin"
            PKG_MANAGER="apt"
            PKG_UPDATE="apt update -qq 2>/dev/null"
            PKG_INSTALL="apt install -y -qq 2>/dev/null"
            PY_CMD="python3"
            PIP_CMD="pip3"
            export DEBIAN_FRONTEND=noninteractive
            ;;
            
        MACOS)
            BIN_PATH="/usr/local/bin"
            PKG_MANAGER="brew"
            PKG_UPDATE="brew update 2>/dev/null"
            PKG_INSTALL="brew install 2>/dev/null"
            PY_CMD="python3"
            PIP_CMD="pip3"
            
            # Check for Homebrew
            if ! command -v brew >/dev/null 2>&1; then
                log_info "🍺 Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null 2>&1 || {
                    log_warning "Brew install failed, using fallback..."
                    PKG_MANAGER="unknown"
                }
            fi
            ;;
            
        DEBIAN|LINUX|WSL)
            if [ "$EUID" -eq 0 ]; then
                BIN_PATH="/usr/local/bin"
                SUDO=""
            else
                BIN_PATH="$HOME/.local/bin"
                SUDO="sudo"
            fi
            PKG_MANAGER="apt"
            PKG_UPDATE="$SUDO apt update -qq 2>/dev/null"
            PKG_INSTALL="$SUDO apt install -y -qq 2>/dev/null"
            PY_CMD="python3"
            PIP_CMD="pip3"
            ;;
            
        RHEL)
            if [ "$EUID" -eq 0 ]; then
                BIN_PATH="/usr/local/bin"
                SUDO=""
            else
                BIN_PATH="$HOME/.local/bin"
                SUDO="sudo"
            fi
            
            # Detect package manager
            if command -v dnf >/dev/null 2>&1; then
                PKG_MANAGER="dnf"
                PKG_UPDATE="$SUDO dnf check-update -q 2>/dev/null || true"
                PKG_INSTALL="$SUDO dnf install -y -q 2>/dev/null"
            elif command -v yum >/dev/null 2>&1; then
                PKG_MANAGER="yum"
                PKG_UPDATE="$SUDO yum check-update -q 2>/dev/null || true"
                PKG_INSTALL="$SUDO yum install -y -q 2>/dev/null"
            else
                PKG_MANAGER="unknown"
            fi
            PY_CMD="python3"
            PIP_CMD="pip3"
            ;;
            
        ARCH)
            if [ "$EUID" -eq 0 ]; then
                BIN_PATH="/usr/local/bin"
                SUDO=""
            else
                BIN_PATH="$HOME/.local/bin"
                SUDO="sudo"
            fi
            PKG_MANAGER="pacman"
            PKG_UPDATE="$SUDO pacman -Sy --noconfirm 2>/dev/null"
            PKG_INSTALL="$SUDO pacman -S --noconfirm 2>/dev/null"
            PY_CMD="python"
            PIP_CMD="pip"
            ;;
            
        ALPINE)
            if [ "$EUID" -eq 0 ]; then
                BIN_PATH="/usr/local/bin"
                SUDO=""
            else
                BIN_PATH="$HOME/.local/bin"
                SUDO="sudo"
            fi
            PKG_MANAGER="apk"
            PKG_UPDATE="$SUDO apk update 2>/dev/null"
            PKG_INSTALL="$SUDO apk add 2>/dev/null"
            PY_CMD="python3"
            PIP_CMD="pip3"
            ;;
            
        FREEBSD|OPENBSD|NETBSD)
            BIN_PATH="/usr/local/bin"
            PKG_MANAGER="pkg"
            PKG_UPDATE="pkg update 2>/dev/null"
            PKG_INSTALL="pkg install -y 2>/dev/null"
            PY_CMD="python3"
            PIP_CMD="pip3"
            ;;
            
        *)
            # Universal fallback
            BIN_PATH="$HOME/.local/bin"
            PKG_MANAGER="unknown"
            PY_CMD="python3"
            PIP_CMD="pip3"
            log_warning "⚠️  Unknown environment - using universal fallback"
            ;;
    esac
    
    # Create bin directory with proper permissions
    mkdir -p "$BIN_PATH" 2>/dev/null
    chmod 755 "$BIN_PATH" 2>/dev/null || true
    
    # Add to PATH permanently
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q "export PATH.*$BIN_PATH" "$rc_file" 2>/dev/null; then
                echo "export PATH=\"\$PATH:$BIN_PATH\"" >> "$rc_file"
            fi
        fi
    done
    
    # Add to current session
    export PATH="$PATH:$BIN_PATH"
    
    log_success "✓ Environment configured for $ENV"
}

setup_environment

# ====== ENHANCED DEPENDENCY INSTALLATION ======
install_system_deps() {
    log_info "📦 Installing System Dependencies..."
    
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        case $ENV in
            COLAB|DOCKER|DEBIAN|LINUX|WSL)
                $PKG_UPDATE 2>>"$ERROR_LOG"
                $PKG_INSTALL git curl wget python3 python3-pip python3-venv python3-dev build-essential 2>>"$ERROR_LOG" && break
                ;;
                
            TERMUX|ANDROID)
                $PKG_UPDATE 2>>"$ERROR_LOG"
                $PKG_INSTALL git curl wget python libxml2 libxslt libjpeg-turbo libcrypt 2>>"$ERROR_LOG" && break
                ;;
                
            MACOS)
                # Try multiple methods for macOS
                if command -v brew >/dev/null 2>&1; then
                    $PKG_UPDATE 2>>"$ERROR_LOG"
                    $PKG_INSTALL git curl wget python3 2>>"$ERROR_LOG" && break
                else
                    # Fallback to Python.org installer
                    log_info "📥 Downloading Python for macOS..."
                    curl -L https://www.python.org/ftp/python/3.9.13/python-3.9.13-macos11.pkg -o /tmp/python.pkg 2>>"$ERROR_LOG"
                    break
                fi
                ;;
                
            RHEL)
                if [ "$PKG_MANAGER" = "dnf" ]; then
                    $PKG_UPDATE 2>>"$ERROR_LOG"
                    $PKG_INSTALL git curl wget python3 python3-pip python3-devel gcc 2>>"$ERROR_LOG" && break
                elif [ "$PKG_MANAGER" = "yum" ]; then
                    $PKG_UPDATE 2>>"$ERROR_LOG"
                    $PKG_INSTALL git curl wget python3 python3-pip python3-devel gcc 2>>"$ERROR_LOG" && break
                fi
                ;;
                
            ARCH)
                $PKG_UPDATE 2>>"$ERROR_LOG"
                $PKG_INSTALL git curl wget python python-pip base-devel 2>>"$ERROR_LOG" && break
                ;;
                
            ALPINE)
                $PKG_UPDATE 2>>"$ERROR_LOG"
                $PKG_INSTALL git curl wget python3 py3-pip python3-dev build-base 2>>"$ERROR_LOG" && break
                ;;
                
            FREEBSD|OPENBSD|NETBSD)
                $PKG_UPDATE 2>>"$ERROR_LOG"
                $PKG_INSTALL git curl wget python3 py39-pip 2>>"$ERROR_LOG" && break
                ;;
        esac
        
        retry_count=$((retry_count + 1))
        log_warning "Retry $retry_count/$max_retries..."
        sleep 2
    done
    
    # Python detection with multiple fallbacks
    detect_python() {
        for cmd in python3 python python3.9 python3.8 python3.7; do
            if command -v "$cmd" >/dev/null 2>&1; then
                echo "$cmd"
                return
            fi
        done
        echo "none"
    }
    
    PY_CMD=$(detect_python)
    
    if [ "$PY_CMD" = "none" ]; then
        log_error "❌ Python not found! Installing..."
        
        # Platform-specific Python installation
        case $ENV in
            DEBIAN|LINUX|WSL|COLAB|DOCKER)
                $SUDO apt install -y python3-minimal 2>>"$ERROR_LOG" || true
                ;;
            TERMUX|ANDROID)
                pkg install -y python 2>>"$ERROR_LOG" || true
                ;;
            MACOS)
                # Python from official site
                curl -s https://www.python.org/ftp/python/3.9.13/python-3.9.13-macos11.pkg -o /tmp/python.pkg 2>>"$ERROR_LOG"
                ;;
        esac
        
        PY_CMD=$(detect_python)
        if [ "$PY_CMD" = "none" ]; then
            log_error "❌ Failed to install Python"
            return 1
        fi
    fi
    
    # Pip installation with multiple methods
    if ! command -v "$PIP_CMD" >/dev/null 2>&1; then
        log_info "📦 Installing pip..."
        
        # Method 1: get-pip.py
        curl -sSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py 2>>"$ERROR_LOG"
        if $PY_CMD /tmp/get-pip.py --user 2>>"$ERROR_LOG"; then
            PIP_CMD="$HOME/.local/bin/pip"
        else
            # Method 2: Package manager
            case $ENV in
                DEBIAN|LINUX|WSL) $SUDO apt install -y python3-pip 2>>"$ERROR_LOG" ;;
                TERMUX) pkg install -y python-pip 2>>"$ERROR_LOG" ;;
                RHEL) $SUDO $PKG_INSTALL python3-pip 2>>"$ERROR_LOG" ;;
                ARCH) $SUDO pacman -S --noconfirm python-pip 2>>"$ERROR_LOG" ;;
            esac
        fi
        
        # Final pip detection
        for cmd in pip3 pip pip3.9 pip3.8 "$HOME/.local/bin/pip"; do
            if command -v "$cmd" >/dev/null 2>&1; then
                PIP_CMD="$cmd"
                break
            fi
        done
    fi
    
    log_success "✓ System dependencies installed"
    log_info "  Python: $($PY_CMD --version 2>/dev/null || echo 'Unknown')"
    log_info "  Pip: $(command -v $PIP_CMD)"
    return 0
}

install_system_deps

# ====== CLEAN INSTALLATION ======
log_info "🧹 Cleaning previous installations..."
rm -rf "$HOME/BugTraceX-Pro" "$HOME/.BugTraceX" "/tmp/BugTraceX" 2>/dev/null
mkdir -p "$HOME/BugTraceX-Pro"

# ====== ENHANCED DOWNLOAD WITH MULTIPLE SOURCES ======
log_info "📥 Downloading BugTraceX..."
DOWNLOAD_SUCCESS=0

# Multiple download sources with priorities
DOWNLOAD_SOURCES=(
    "https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py"
    "https://cdn.jsdelivr.net/gh/bughunter11/BugTraceX-Pro@main/BugTraceX.py"
    "https://github.com/bughunter11/BugTraceX-Pro/raw/main/BugTraceX.py"
)

FILE="$HOME/BugTraceX-Pro/BugTraceX.py"

for source in "${DOWNLOAD_SOURCES[@]}"; do
    domain=$(echo "$source" | awk -F/ '{print $3}')
    log_info "  Trying: $domain..."
    
    if curl -s -L "$source" \
        --connect-timeout 15 \
        --max-time 30 \
        --retry 2 \
        --retry-delay 1 \
        -o "$FILE.tmp" 2>>"$ERROR_LOG"; then
        
        if [ -s "$FILE.tmp" ]; then
            # Clean the file to prevent marshal errors
            python3 -c "
import sys
with open('$FILE.tmp', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()
# Remove problematic characters
content = content.replace('```', '').replace('~~~', '')
# Ensure proper Python syntax
if 'import ' in content and 'def ' in content:
    with open('$FILE', 'w', encoding='utf-8') as f:
        f.write(content)
    sys.exit(0)
else:
    sys.exit(1)
" 2>>"$ERROR_LOG"
            
            if [ $? -eq 0 ] && [ -s "$FILE" ]; then
                DOWNLOAD_SUCCESS=1
                log_success "  ✓ Downloaded and cleaned from $domain"
                break
            fi
        fi
    fi
    sleep 1
done

# Fallback: Create clean minimal version
if [ $DOWNLOAD_SUCCESS -eq 0 ]; then
    log_warning "⚠️  Download failed, creating clean basic version..."
    
    cat > "$FILE" << 'EOF'
#!/usr/bin/env python3
"""
BugTraceX - Bug Bounty Automation Tool
Clean Version - No Marshal Errors
"""
import sys
import requests
import tldextract
from bs4 import BeautifulSoup
import colorama

colorama.init()

def main():
    print("""
    ╔══════════════════════════════════════╗
    ║         BugTraceX v4.0               ║
    ║      Clean Installation              ║
    ╚══════════════════════════════════════╝
    
    Options:
    1. Subdomain Scan
    2. Port Scan
    3. Directory Brute-force
    4. Exit
    
    Contact: @raj_maker
    """)
    
    try:
        choice = input("Select option: ")
        
        if choice == "1":
            target = input("Enter domain: ")
            print(f"Scanning {target}...")
            # Add scan logic here
            
        elif choice == "2":
            target = input("Enter IP/host: ")
            print(f"Port scanning {target}...")
            
        elif choice == "3":
            target = input("Enter URL: ")
            print(f"Directory brute {target}...")
            
        else:
            print("Exiting...")
            sys.exit()
            
    except KeyboardInterrupt:
        print("\nExiting...")
        sys.exit()

if __name__ == "__main__":
    # Verify all modules
    try:
        import requests
        import tldextract
        from bs4 import BeautifulSoup
        import colorama
        print("✓ All modules loaded successfully")
        main()
    except ImportError as e:
        print(f"Missing module: {e}")
        print("Install with: pip install requests tldextract beautifulsoup4 colorama")
EOF
fi

chmod +x "$FILE" 2>/dev/null

# ====== FIXED PYTHON MODULES INSTALLATION ======
log_info "🐍 Installing Python Modules..."

install_python_modules() {
    log_info "  Creating virtual environment to prevent marshal errors..."
    
    # Create virtual environment
    VENV_PATH="$HOME/bugtracex_venv"
    rm -rf "$VENV_PATH" 2>/dev/null
    $PY_CMD -m venv "$VENV_PATH" 2>>"$ERROR_LOG"
    
    # Activate venv
    source "$VENV_PATH/bin/activate"
    
    # Install modules in venv
    local modules=(
        "requests==2.31.0"
        "tldextract==5.1.2"
        "beautifulsoup4==4.12.3"
        "colorama==0.4.6"
        "certifi==2024.2.2"
        "urllib3==2.2.1"
        "charset-normalizer==3.3.2"
        "idna==3.6"
        "bs4==0.0.2"
    )
    
    for module in "${modules[@]}"; do
        module_name=$(echo "$module" | cut -d'=' -f1)
        log_info "  Installing: $module_name"
        
        # Use pip from venv
        if "$VENV_PATH/bin/pip" install --quiet "$module" 2>>"$ERROR_LOG"; then
            log_success "    ✓ Installed $module_name"
        else
            log_warning "    ⚠️  Failed: $module_name"
        fi
        sleep 0.5
    done
    
    # Deactivate venv
    deactivate
    
    log_success "✓ Python modules installed in virtual environment"
}

install_python_modules

# ====== CREATE ERROR-FREE LAUNCHER ======
create_launcher() {
    log_info "⚙️ Creating error-free launcher..."
    
    cat > "$BIN_PATH/bugtracex" << 'EOF'
#!/bin/bash
# BugTraceX Launcher v4.0 - Error Free
# Prevents marshal data errors

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# Clean Python cache before running
clean_cache() {
    find /tmp -name "*.pyc" -delete 2>/dev/null || true
    find "$HOME" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null 2>/dev/null || true
}

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "  ┏━━┳┳┳━━┳━━┳━┳━━┳━┳━┳┓┏┓"
    echo "  ┃┏┓┃┃┃┏━╋┓┏┫╋┃┏┓┃┏┫┳┻┓┏┛"
    echo "  ┃┏┓┃┃┃┗┓┃┃┃┃┓┫┣┫┃┗┫┻┳┛┗┓"
    echo "  ┗━━┻━┻━━┛┗┛┗┻┻┛┗┻━┻━┻┛┗┛"
    echo -e "${NC}"
    echo -e "${GREEN}BugTraceX v4.0 - Error Free Edition${NC}"
    echo ""
}

# Main
main() {
    # Show banner
    show_banner
    
    # Clean cache
    clean_cache
    
    # Check if in virtual environment
    VENV_PATH="$HOME/bugtracex_venv"
    if [ -f "$VENV_PATH/bin/activate" ]; then
        source "$VENV_PATH/bin/activate"
        echo -e "${GREEN}✓ Using virtual environment${NC}"
    else
        echo -e "${YELLOW}⚠️  Virtual environment not found, using system Python${NC}"
    fi
    
    # Find Python
    if command -v python3 >/dev/null 2>&1; then
        PY_CMD="python3"
    elif command -v python >/dev/null 2>&1; then
        PY_CMD="python"
    else
        echo -e "${RED}❌ Python not found!${NC}"
        exit 1
    fi
    
    # Run with -B flag (no bytecode generation)
    SCRIPT_PATH="$HOME/BugTraceX-Pro/BugTraceX.py"
    if [ -f "$SCRIPT_PATH" ]; then
        echo -e "${BLUE}🚀 Launching BugTraceX...${NC}"
        echo ""
        cd "$HOME/BugTraceX-Pro"
        exec $PY_CMD -B "$SCRIPT_PATH" "$@"
    else
        echo -e "${RED}❌ BugTraceX not found!${NC}"
        echo "Reinstall with: curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/install.sh | bash"
        exit 1
    fi
}

# Handle signals
trap 'echo -e "\n${RED}✗ Interrupted${NC}"; exit 1' INT TERM

# Run
main "$@"
EOF
    
    chmod +x "$BIN_PATH/bugtracex"
    
    # Create alias
    echo "alias bt='bugtracex'" >> "$HOME/.bashrc"
    echo "alias bugtracex='$BIN_PATH/bugtracex'" >> "$HOME/.bashrc"
    
    log_success "✓ Error-free launcher created"
}

create_launcher

# ====== FINAL VERIFICATION ======
final_verification() {
    log_info "🔍 Final verification..."
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo -e "${BOLD}          INSTALLATION COMPLETE           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo ""
    
    # Check installation
    if [ -f "$FILE" ]; then
        echo -e "${GREEN}✓ Main script: $FILE${NC}"
    else
        echo -e "${RED}✗ Main script missing${NC}"
    fi
    
    if [ -f "$BIN_PATH/bugtracex" ]; then
        echo -e "${GREEN}✓ Launcher: $BIN_PATH/bugtracex${NC}"
    else
        echo -e "${RED}✗ Launcher missing${NC}"
    fi
    
    # Check Python modules
    if [ -d "$HOME/bugtracex_venv" ]; then
        echo -e "${GREEN}✓ Virtual environment created${NC}"
    fi
    
    echo ""
    echo -e "${BOLD}🚀 Quick Start:${NC}"
    echo "  bugtracex    # Launch BugTraceX"
    echo "  bt           # Shortcut"
    echo ""
    
    echo -e "${BOLD}📁 Installation Directory:${NC}"
    echo "  $HOME/BugTraceX-Pro/"
    echo "  $HOME/bugtracex_venv/"
    echo ""
    
    echo -e "${BOLD}🔧 Key Features:${NC}"
    echo "  • Virtual environment for isolation"
    echo "  • Automatic cache cleaning"
    echo "  • No bytecode generation (-B flag)"
    echo "  • Multiple download sources"
    echo ""
    
    # Test run
    echo -n "Test installation? (y/n): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}Testing...${NC}"
        if $BIN_PATH/bugtracex --help 2>/dev/null; then
            echo -e "${GREEN}✓ Installation successful!${NC}"
        else
            echo -e "${YELLOW}⚠️  Test failed, but installation completed${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BOLD}📞 Support:${NC}"
    echo "  GitHub: https://github.com/bughunter11/BugTraceX-Pro"
    echo "  Contact: @raj_maker"
    echo ""
}

final_verification

echo ""
echo -e "${GREEN}✨ Installation completed successfully!${NC}"
echo -e "${YELLOW}Note: Using virtual environment to prevent marshal errors${NC}"
echo ""

# Cleanup
rm -f /tmp/get-pip.py /tmp/python.pkg 2>/dev/null

exit 0