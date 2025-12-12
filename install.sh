#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║      BugTraceX-Pro - Universal Installation          ║"
echo "║          RAJ_MAKER's Professional Toolkit            ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to check and install dependencies
install_dependencies() {
    echo -e "${YELLOW}[*] Checking and installing dependencies...${NC}"
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}[!] Python3 not found! Installing...${NC}"
        if command -v apt &> /dev/null; then
            apt update && apt install -y python3 python3-pip
        elif command -v pkg &> /dev/null; then
            pkg update && pkg install -y python python-pip
        elif command -v brew &> /dev/null; then
            brew install python3
        elif command -v yum &> /dev/null; then
            yum install -y python3 python3-pip
        elif command -v dnf &> /dev/null; then
            dnf install -y python3 python3-pip
        elif command -v pacman &> /dev/null; then
            pacman -Syu --noconfirm python python-pip
        else
            echo -e "${RED}[!] Could not install Python3 automatically${NC}"
            echo "Please install Python3 manually and run again"
            exit 1
        fi
    fi
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        echo -e "${RED}[!] pip3 not found! Installing...${NC}"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case $ID in
                debian|ubuntu|kali)
                    apt install -y python3-pip
                    ;;
                fedora)
                    dnf install -y python3-pip
                    ;;
                arch|manjaro)
                    pacman -S --noconfirm python-pip
                    ;;
                *)
                    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
                    python3 get-pip.py
                    rm get-pip.py
                    ;;
            esac
        else
            # For Termux
            if command -v pkg &> /dev/null; then
                pkg install -y python-pip
            fi
        fi
    fi
    
    # Check git
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}[*] Installing git...${NC}"
        if command -v apt &> /dev/null; then
            apt install -y git
        elif command -v pkg &> /dev/null; then
            pkg install -y git
        elif command -v brew &> /dev/null; then
            brew install git
        fi
    fi
}

# Function to install Python requirements
install_python_requirements() {
    echo -e "${YELLOW}[*] Installing Python requirements...${NC}"
    
    # Check if requirements.txt exists
    if [ -f "requirements.txt" ]; then
        pip3 install --upgrade pip
        pip3 install -r requirements.txt
        
        # If pip fails, try with --user flag
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}[*] Trying alternative installation method...${NC}"
            pip3 install --user -r requirements.txt
        fi
    else
        # Install common requirements if requirements.txt doesn't exist
        echo -e "${YELLOW}[*] requirements.txt not found, installing common packages...${NC}"
        pip3 install --upgrade pip
        pip3 install requests beautifulsoup4 colorama
        
        # Create requirements.txt for future
        echo "requests" > requirements.txt
        echo "beautifulsoup4" >> requirements.txt
        echo "colorama" >> requirements.txt
    fi
}

# Function to setup BugTraceX
setup_bugtracex() {
    echo -e "${YELLOW}[*] Setting up BugTraceX-Pro...${NC}"
    
    # Create necessary directories
    mkdir -p logs results config
    
    # Check if BugTraceX.py exists
    if [ ! -f "BugTraceX.py" ]; then
        echo -e "${RED}[!] BugTraceX.py not found! Downloading...${NC}"
        
        # Try to download from GitHub if not present
        if command -v wget &> /dev/null; then
            wget https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py
        elif command -v curl &> /dev/null; then
            curl -O https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py
        else
            echo -e "${RED}[!] Could not download BugTraceX.py${NC}"
            echo "Please download it manually from:"
            echo "https://github.com/bughunter11/BugTraceX-Pro"
            exit 1
        fi
    fi
    
    # Make scripts executable
    chmod +x BugTraceX.py install.sh 2>/dev/null || true
    
    # Create run script
    echo '#!/bin/bash
cd "$(dirname "$0")"
python3 BugTraceX.py "$@"' > run.sh
    chmod +x run.sh
    
    # Create alias for easy access
    echo -e "${GREEN}[+] Creating easy run command...${NC}"
    echo 'alias bugtracex="cd '$(pwd)' && python3 BugTraceX.py"' >> ~/.bashrc 2>/dev/null
    echo 'alias bugtracex="cd '$(pwd)' && python3 BugTraceX.py"' >> ~/.zshrc 2>/dev/null
    
    # For Termux
    if [ -d "$HOME/.termux" ]; then
        echo 'alias bugtracex="cd '$(pwd)' && python3 BugTraceX.py"' >> $HOME/.bash_profile
    fi
}

# Function to check platform
check_platform() {
    echo -e "${BLUE}[*] Platform Detection${NC}"
    
    if [ -d "/data/data/com.termux" ]; then
        echo -e "${GREEN}[+] Platform: Termux (Android)${NC}"
        PLATFORM="termux"
    elif [ "$(uname)" == "Darwin" ]; then
        echo -e "${GREEN}[+] Platform: macOS${NC}"
        PLATFORM="macos"
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        echo -e "${GREEN}[+] Platform: Linux${NC}"
        PLATFORM="linux"
    else
        echo -e "${YELLOW}[!] Unknown platform, trying Linux mode${NC}"
        PLATFORM="linux"
    fi
}

# Function to fix common issues
fix_issues() {
    echo -e "${YELLOW}[*] Fixing common issues...${NC}"
    
    # Fix for Termux storage permission
    if [ "$PLATFORM" == "termux" ]; then
        echo -e "${BLUE}[*] Setting up Termux storage...${NC}"
        termux-setup-storage 2>/dev/null || true
    fi
    
    # Fix Python path issues
    if [ ! -f "/usr/bin/python3" ] && [ -f "/usr/local/bin/python3" ]; then
        ln -s /usr/local/bin/python3 /usr/local/bin/python 2>/dev/null || true
    fi
    
    # Fix pip path
    export PATH="$HOME/.local/bin:$PATH"
}

# Main installation
main() {
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then 
        echo -e "${RED}[!] Warning: Running as root${NC}"
        read -p "Continue? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Detect platform
    check_platform
    
    # Update package lists
    echo -e "${YELLOW}[*] Updating package lists...${NC}"
    if [ "$PLATFORM" == "termux" ]; then
        pkg update -y 2>/dev/null || true
    elif [ "$PLATFORM" == "linux" ]; then
        apt update 2>/dev/null || yum check-update 2>/dev/null || true
    fi
    
    # Install dependencies
    install_dependencies
    install_python_requirements
    fix_issues
    setup_bugtracex
    
    # Final output
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║         Installation Completed Successfully!         ║"
    echo "╠══════════════════════════════════════════════════════╣"
    echo "║ To run BugTraceX-Pro:                                ║"
    echo "║                                                      ║"
    echo "║ Method 1: python3 BugTraceX.py                       ║"
    echo "║ Method 2: ./run.sh                                   ║"
    echo "║ Method 3: bugtracex (after restarting terminal)      ║"
    echo "║                                                      ║"
    echo "║ Directory: $(pwd)         ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}[*] Testing installation...${NC}"
    if command -v python3 &> /dev/null; then
        python3 --version
        echo -e "${GREEN}[+] Python is working${NC}"
        
        # Quick test of the script
        if [ -f "BugTraceX.py" ]; then
            echo -e "${GREEN}[+] BugTraceX.py found${NC}"
            echo -e "${BLUE}[*] You can now run:${NC}"
            echo -e "    ${GREEN}cd $(pwd)${NC}"
            echo -e "    ${GREEN}python3 BugTraceX.py --help${NC}"
        fi
    else
        echo -e "${RED}[!] Python installation failed${NC}"
    fi
    
    echo -e "\n${YELLOW}[!] Please restart your terminal or run:${NC}"
    echo -e "    ${GREEN}source ~/.bashrc${NC}"
}

# Run main function
main "$@"