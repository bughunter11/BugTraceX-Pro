#!/bin/bash

# ============================================
# BugTraceX Universal Installer - VIP Edition
# Version: 3.0 (Ultra Compatible)
# Compatible: Termux, Android, Linux, macOS, BSD, WSL, Colab, VPS
# Zero Error Guarantee with Fallback Methods
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
ERROR_LOG="$HOME/.bgx_install_v3_$(date +%s).log"
touch "$ERROR_LOG" 2>/dev/null

log() { echo -e "$1"; }
log_info() { log "${BLUE}[*]${NC} $1"; }
log_success() { log "${GREEN}[+]${NC} $1"; }
log_warning() { log "${YELLOW}[!]${NC} $1"; }
log_error() { 
    log "${RED}[-]${NC} $1"
    echo "[ERROR $(date)]: $1" >> "$ERROR_LOG"
}

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
    echo -e "${YELLOW}  Version: 3.0 | Platform: $(uname -s)${NC}"
    echo ""
}

show_banner
log "🔧 Installing BugTraceX Secure VIP Version v3.0..."
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
        for cmd in python3 python python3.9 python3.8 python3.7 python2; do
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
    "https://gitlab.com/bughunter11/BugTraceX-Pro/-/raw/main/BugTraceX.py"
    "https://github.com/bughunter11/BugTraceX-Pro/raw/main/BugTraceX.py"
    "https://raw.githack.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py"
    "https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/refs/heads/main/BugTraceX.py"
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
        
        if [ -s "$FILE.tmp" ] && grep -q "import" "$FILE.tmp" 2>/dev/null; then
            mv "$FILE.tmp" "$FILE"
            DOWNLOAD_SUCCESS=1
            log_success "  ✓ Downloaded from $domain"
            break
        fi
    fi
    sleep 1
done

# Fallback: Create minimal version
if [ $DOWNLOAD_SUCCESS -eq 0 ]; then
    log_warning "⚠️  Download failed, creating basic version..."
    
    cat > "$FILE" << 'EOF'
#!/usr/bin/env python3
"""
BugTraceX - Bug Bounty Automation Tool
Fallback Version (Online download failed)
"""
import sys
import os
import subprocess
import tempfile

def check_dependencies():
    required = ['requests', 'tldextract', 'beautifulsoup4', 'colorama']
    missing = []
    
    for module in required:
        try:
            __import__(module)
        except ImportError:
            missing.append(module)
    
    return missing

def install_missing(missing):
    print("Installing missing modules:", missing)
    subprocess.check_call([sys.executable, '-m', 'pip', 'install'] + missing)

def main():
    print("""
    ╔══════════════════════════════════════╗
    ║      BugTraceX - Fallback Mode       ║
    ║  Online download failed!             ║
    ╚══════════════════════════════════════╝
    
    Steps to fix:
    1. Check internet connection
    2. Reinstall with: 
       curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/install.sh | bash
    3. Manual download:
       wget https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py
    
    Contact: @raj_maker
    """)
    
    # Check and install dependencies
    missing = check_dependencies()
    if missing:
        try:
            install_missing(missing)
        except:
            print("Failed to install modules. Run manually:")
            print(f"pip install {' '.join(missing)}")
    
    sys.exit(0)

if __name__ == "__main__":
    main()
EOF
fi

chmod +x "$FILE" 2>/dev/null

# ====== ENHANCED PYTHON MODULES INSTALLATION ======
log_info "🐍 Installing Python Modules..."

install_python_modules() {
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
        "lxml==4.9.4"
        "pyOpenSSL==23.2.0"
    )
    
    for module in "${modules[@]}"; do
        module_name=$(echo "$module" | cut -d'=' -f1)
        log_info "  Installing: $module_name"
        
        # Try multiple installation methods
        for method in 1 2 3; do
            case $method in
                1)
                    # Method 1: Standard pip
                    if $PIP_CMD install --quiet --no-warn-script-location --user "$module" 2>>"$ERROR_LOG"; then
                        log_success "    ✓ Installed $module_name"
                        break
                    fi
                    ;;
                2)
                    # Method 2: Python -m pip
                    if $PY_CMD -m pip install --quiet --no-warn-script-location --user "$module" 2>>"$ERROR_LOG"; then
                        log_success "    ✓ Installed $module_name"
                        break
                    fi
                    ;;
                3)
                    # Method 3: Without --user flag
                    if $PY_CMD -m pip install --quiet "$module" 2>>"$ERROR_LOG"; then
                        log_success "    ✓ Installed $module_name"
                        break
                    fi
                    ;;
            esac
            
            if [ $method -eq 3 ]; then
                log_warning "    ⚠️  Failed: $module_name"
                echo "Failed to install $module_name" >> "$ERROR_LOG"
            fi
        done
        sleep 0.5
    done
}

install_python_modules

# ====== OPTIONAL TOOLS INSTALLATION ======
install_optional_tools() {
    log_info "🌐 Installing optional security tools..."
    
    # Go installation (if not present)
    if ! command -v go >/dev/null 2>&1; then
        log_info "  Installing Go..."
        case $ENV in
            DEBIAN|LINUX|WSL)
                $SUDO apt install -y golang-go 2>>"$ERROR_LOG" || true
                ;;
            TERMUX)
                pkg install -y golang 2>>"$ERROR_LOG" || true
                ;;
            MACOS)
                brew install go 2>>"$ERROR_LOG" || true
                ;;
            RHEL)
                $SUDO $PKG_INSTALL golang 2>>"$ERROR_LOG" || true
                ;;
        esac
    fi
    
    # Set Go environment
    export GOPATH="$HOME/go"
    export PATH="$PATH:$GOPATH/bin"
    mkdir -p "$GOPATH"
    
    # Install subfinder (with retry)
    for tool in "subfinder" "assetfinder" "httpx" "nuclei"; do
        log_info "  Installing $tool..."
        
        case $tool in
            subfinder)
                go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>>"$ERROR_LOG" || true
                ;;
            assetfinder)
                go install -v github.com/tomnomnom/assetfinder@latest 2>>"$ERROR_LOG" || true
                ;;
            httpx)
                go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest 2>>"$ERROR_LOG" || true
                ;;
            nuclei)
                go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest 2>>"$ERROR_LOG" || true
                ;;
        esac
        
        # Copy to bin directory
        local tool_path="$GOPATH/bin/$tool"
        if [ -f "$tool_path" ]; then
            cp "$tool_path" "$BIN_PATH/" 2>/dev/null && chmod +x "$BIN_PATH/$tool"
            log_success "    ✓ $tool installed"
        fi
    done
    
    # Install additional Python tools
    $PIP_CMD install --quiet --user waybackpy dnspython 2>>"$ERROR_LOG" || true
}

install_optional_tools

# ====== CREATE UNIVERSAL LAUNCHER ======
create_universal_launcher() {
    log_info "⚙️ Creating universal launcher..."
    
    cat > "$BIN_PATH/bugtracex" << 'EOF'
#!/bin/bash
# BugTraceX Universal Launcher v3.0
# Compatible with ALL platforms
# Auto-fixes common issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "  ┏━━┳┳┳━━┳━━┳━┳━━┳━┳━┳┓┏┓"
    echo "  ┃┏┓┃┃┃┏━╋┓┏┫╋┃┏┓┃┏┫┳┻┓┏┛"
    echo "  ┃┏┓┃┃┃┗┓┃┃┃┃┓┫┣┫┃┗┫┻┳┛┗┓"
    echo "  ┗━━┻━┻━━┛┗┛┗┻┻┛┗┻━┻━┻┛┗┛"
    echo -e "${NC}"
    echo -e "${MAGENTA}  BugTraceX VIP - Universal Edition v3.0${NC}"
    echo ""
}

# Clean Python cache
clean_python_cache() {
    find "$HOME" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$HOME" -name "*.pyc" -delete 2>/dev/null || true
    find /tmp -name "*.pyc" -delete 2>/dev/null || true
}

# Fix PATH issues
fix_path() {
    export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"
    export PYTHONPATH="$HOME/.local/lib/python*/site-packages:$PYTHONPATH"
    
    # Add missing paths
    for dir in "/usr/local/bin" "/usr/bin" "/bin" "/usr/sbin" "/sbin"; do
        if [[ ":$PATH:" != *":$dir:"* ]]; then
            export PATH="$PATH:$dir"
        fi
    done
}

# Check dependencies
check_dependencies() {
    local missing=()
    local python_ok=0
    
    # Check Python
    for py in python3 python python3.9 python3.8; do
        if command -v "$py" >/dev/null 2>&1; then
            PY_CMD="$py"
            python_ok=1
            break
        fi
    done
    
    if [ $python_ok -eq 0 ]; then
        echo -e "${RED}❌ Python not found!${NC}"
        echo "Install Python first:"
        echo "  Termux: pkg install python"
        echo "  Ubuntu: sudo apt install python3"
        echo "  macOS: brew install python3"
        return 1
    fi
    
    # Check required modules
    local required_modules=("requests" "tldextract" "bs4" "colorama")
    for module in "${required_modules[@]}"; do
        if ! "$PY_CMD" -c "import $module" 2>/dev/null; then
            missing+=("$module")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Missing modules: ${missing[*]}${NC}"
        echo -e "${BLUE}Installing missing modules...${NC}"
        "$PY_CMD" -m pip install --user "${missing[@]}" 2>/dev/null || {
            echo -e "${RED}Failed to install modules. Run manually:${NC}"
            echo "pip install ${missing[*]}"
        }
    fi
    
    return 0
}

# Main execution
main() {
    show_banner
    
    # Platform info
    echo -e "${BLUE}Platform:${NC} $(uname -s) | ${BLUE}Python:${NC} $(python3 --version 2>/dev/null || echo 'Not found')"
    echo ""
    
    # Clean cache
    clean_python_cache
    
    # Fix PATH
    fix_path
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    # Find tool directory
    TOOL_DIR="$HOME/BugTraceX-Pro"
    if [ ! -d "$TOOL_DIR" ]; then
        echo -e "${RED}❌ Installation not found!${NC}"
        echo -e "${YELLOW}Run installer:${NC}"
        echo "curl -sL https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/install.sh | bash"
        exit 1
    fi
    
    MAIN_SCRIPT="$TOOL_DIR/BugTraceX.py"
    if [ ! -f "$MAIN_SCRIPT" ]; then
        echo -e "${RED}❌ Main script missing!${NC}"
        exit 1
    fi
    
    # Launch
    echo -e "${GREEN}🚀 Launching BugTraceX...${NC}"
    echo -e "${CYAN}══════════════════════════════════${NC}"
    echo ""
    
    cd "$TOOL_DIR" || exit 1
    exec "$PY_CMD" "$MAIN_SCRIPT" "$@"
}

# Handle signals
trap 'echo -e "\n${RED}✗ Interrupted${NC}"; exit 1' INT TERM

# Run
main "$@"
EOF
    
    chmod +x "$BIN_PATH/bugtracex"
    chmod +x "$BIN_PATH/bt" 2>/dev/null || true
    
    # Create shortcut alias
    ln -sf "$BIN_PATH/bugtracex" "$BIN_PATH/bt" 2>/dev/null || true
    
    log_success "✓ Universal launcher created"
}

create_universal_launcher

# ====== CREATE SHELL INTEGRATION ======
setup_shell_integration() {
    log_info "🔗 Setting up shell integration..."
    
    # Function to add to shell config
    add_to_shell() {
        local shell_rc="$1"
        local marker="# BugTraceX Configuration v3.0"
        
        if [ -f "$shell_rc" ]; then
            # Remove old entries
            sed -i '/# BugTraceX Configuration/d' "$shell_rc" 2>/dev/null
            sed -i '/alias bugtracex=/d' "$shell_rc" 2>/dev/null
            sed -i '/alias bt=/d' "$shell_rc" 2>/dev/null
            
            # Add new configuration
            {
                echo ""
                echo "$marker"
                echo "export PATH=\"\$PATH:$BIN_PATH\""
                echo "export BGX_HOME=\"$HOME/BugTraceX-Pro\""
                echo "alias bugtracex=\"$BIN_PATH/bugtracex\""
                echo "alias bt=\"bugtracex\""
                echo "complete -W \"scan subdomain port whois ssl headers\" bugtracex"
                echo ""
            } >> "$shell_rc"
        fi
    }
    
    # Add to all shell configs
    for rc in ".bashrc" ".zshrc" ".bash_profile" ".profile"; do
        add_to_shell "$HOME/$rc"
    done
    
    # Fish shell
    if [ -d "$HOME/.config/fish" ]; then
        fish_config="$HOME/.config/fish/config.fish"
        mkdir -p "$(dirname "$fish_config")"
        {
            echo ""
            echo "# BugTraceX Configuration"
            echo "set -gx PATH \$PATH $BIN_PATH"
            echo "set -gx BGX_HOME $HOME/BugTraceX-Pro"
            echo "alias bugtracex='$BIN_PATH/bugtracex'"
            echo "alias bt='bugtracex'"
            echo ""
        } >> "$fish_config"
    fi
    
    # Source current bashrc
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
}

setup_shell_integration

# ====== FINAL VERIFICATION ======
final_verification() {
    log_info "🔍 Final verification..."
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo -e "${BOLD}          INSTALLATION SUMMARY           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo ""
    
    local checks=()
    
    # Check 1: Main script
    if [ -f "$FILE" ]; then
        echo -e "${GREEN}✓ Main script: $FILE${NC}"
        checks+=("main_script")
    else
        echo -e "${RED}✗ Main script missing${NC}"
    fi
    
    # Check 2: Launcher
    if [ -f "$BIN_PATH/bugtracex" ]; then
        echo -e "${GREEN}✓ Launcher: $BIN_PATH/bugtracex${NC}"
        checks+=("launcher")
    else
        echo -e "${RED}✗ Launcher missing${NC}"
    fi
    
    # Check 3: Python
    if command -v "$PY_CMD" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Python: $(command -v $PY_CMD)${NC}"
        checks+=("python")
    else
        echo -e "${RED}✗ Python not found${NC}"
    fi
    
    # Check 4: Key modules
    if $PY_CMD -c "import requests, tldextract, bs4" 2>/dev/null; then
        echo -e "${GREEN}✓ Core Python modules installed${NC}"
        checks+=("modules")
    else
        echo -e "${YELLOW}⚠️  Some modules missing${NC}"
    fi
    
    # Check 5: PATH
    if [[ ":$PATH:" == *":$BIN_PATH:"* ]]; then
        echo -e "${GREEN}✓ PATH configured correctly${NC}"
        checks+=("path")
    else
        echo -e "${YELLOW}⚠️  PATH may need manual setup${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    
    # Overall status
    if [ ${#checks[@]} -ge 4 ]; then
        echo -e "${GREEN}🎉 INSTALLATION SUCCESSFUL!${NC}"
    else
        echo -e "${YELLOW}⚠️  INSTALLATION PARTIALLY COMPLETED${NC}"
    fi
    
    echo ""
    echo -e "${BOLD}📋 Quick Commands:${NC}"
    echo "  bugtracex    # Launch BugTraceX"
    echo "  bt           # Shortcut"
    echo "  bugtracex scan example.com"
    echo ""
    
    echo -e "${BOLD}📁 Installation Directory:${NC}"
    echo "  $HOME/BugTraceX-Pro/"
    echo ""
    
    echo -e "${BOLD}🔧 Troubleshooting:${NC}"
    echo "  Check error log: $ERROR_LOG"
    echo "  Manual fix: pip install requests tldextract beautifulsoup4 colorama"
    echo ""
    
    echo -e "${BOLD}📞 Support:${NC}"
    echo "  GitHub: https://github.com/bughunter11/BugTraceX-Pro"
    echo "  Contact: @raj_maker"
    echo ""
    
    # Auto-launch prompt
    if [ -t 0 ] && [ ${#checks[@]} -ge 3 ]; then
        echo -n "🚀 Launch BugTraceX now? (Y/n): "
        read -r -n 1 response
        echo ""
        if [[ "$response" =~ ^[Yy]$ ]] || [[ -z "$response" ]]; then
            echo "Launching..."
            sleep 1
            "$BIN_PATH/bugtracex"
        fi
    fi
}

final_verification

echo ""
echo -e "${GREEN}✨ Installation completed!${NC}"
echo ""

# Cleanup
rm -f /tmp/get-pip.py /tmp/python.pkg 2>/dev/null

exit 0