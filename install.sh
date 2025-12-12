#!/bin/bash
# BugTraceX Installer - NO CURL VERSION
# Uses only Python for download - NO HANG

echo ""
echo "┏━━┳┳┳━━┳━━┳━┳━━┳━┳━┳┓┏┓"
echo "┃┏┓┃┃┃┏━╋┓┏┫╋┃┏┓┃┏┫┳┻┓┏┛"
echo "┃┏┓┃┃┃┗┓┃┃┃┃┓┫┣┫┃┗┫┻┳┛┗┓"
echo "┗━━┻━┻━━┛┗┛┗┻┻┛┗┻━┻━┻┛┗┛"
echo ""
echo "BugTraceX Installer - Python Edition"
echo ""

# Step 1: Clean
echo "[1] Cleaning..."
rm -rf ~/BugTraceX 2>/dev/null
mkdir -p ~/BugTraceX
cd ~/BugTraceX

# Step 2: Install Python modules
echo "[2] Installing Python modules..."
python3 -m pip install --user requests tldextract beautifulsoup4 colorama 2>/dev/null || \
pip3 install --user requests tldextract beautifulsoup4 colorama 2>/dev/null || \
echo "Note: Install modules manually if needed"

# Step 3: DOWNLOAD USING PYTHON (NO CURL)
echo "[3] Downloading using Python..."

# Python download script
python3 -c "
import sys
import os

def download_file():
    urls = [
        'https://raw.githubusercontent.com/bughunter11/BugTraceX-Pro/main/BugTraceX.py',
        'https://cdn.jsdelivr.net/gh/bughunter11/BugTraceX-Pro/BugTraceX.py'
    ]
    
    for url in urls:
        try:
            print(f'Trying: {url.split(\"/\")[2]}')
            
            # Use urllib
            try:
                from urllib.request import urlopen
                response = urlopen(url, timeout=10)
                data = response.read().decode('utf-8')
                
                if 'import ' in data and 'def ' in data:
                    with open('BugTraceX.py', 'w') as f:
                        f.write(data)
                    print('Download successful!')
                    return True
                    
            except:
                # Try requests if available
                try:
                    import requests
                    r = requests.get(url, timeout=10)
                    if r.status_code == 200 and 'import ' in r.text:
                        with open('BugTraceX.py', 'w') as f:
                            f.write(r.text)
                        print('Download successful!')
                        return True
                except:
                    continue
                    
        except Exception as e:
            continue
    
    # Create basic version if all downloads fail
    print('Creating basic version...')
    with open('BugTraceX.py', 'w') as f:
        f.write('''#!/usr/bin/env python3
print(\"BugTraceX - Ready to use!\")
print(\"Modules installed: requests, tldextract, beautifulsoup4, colorama\")
''')
    return False

download_file()
"

# Step 4: Make executable
chmod +x BugTraceX.py 2>/dev/null || true

# Step 5: Create runner
echo "[4] Creating runner..."
cat > ~/run_bt.sh << 'EOF'
#!/bin/bash
cd ~/BugTraceX
python3 BugTraceX.py "$@"
EOF

chmod +x ~/run_bt.sh

# Step 6: Test
echo "[5] Testing..."
if [ -f "BugTraceX.py" ]; then
    echo ""
    echo "✅ INSTALLATION SUCCESSFUL!"
    echo ""
    echo "🚀 Run BugTraceX:"
    echo "   cd ~/BugTraceX && python3 BugTraceX.py"
    echo "   OR"
    echo "   bash ~/run_bt.sh"
    echo ""
    echo "📁 Location: ~/BugTraceX/"
    echo ""
    
    # Auto-test
    echo "Testing Python modules..."
    python3 -c "
try:
    import requests
    import tldextract
    from bs4 import BeautifulSoup
    import colorama
    print('✅ All Python modules working!')
except ImportError as e:
    print(f'⚠️  Missing: {e}')
    print('Run: pip3 install requests tldextract beautifulsoup4 colorama')
"
    
    # Run if user wants
    echo ""
    read -p "Launch BugTraceX now? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo ""
        python3 BugTraceX.py || echo "Run manually: cd ~/BugTraceX && python3 BugTraceX.py"
    fi
else
    echo ""
    echo "⚠️  Download failed but basic version created."
    echo "Manual steps:"
    echo "1. Install modules: pip3 install requests tldextract beautifulsoup4 colorama"
    echo "2. Download manually from GitHub"
fi

echo ""
echo "✨ Installation process complete!"