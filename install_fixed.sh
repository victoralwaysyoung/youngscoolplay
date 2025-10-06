#!/bin/bash

# YoungsCoolPlay Installation Script for Ubuntu 24.04+ (Fixed Version)
# Author: victoralwaysyoung
# Version: 1.0.1 - Fixed dpkg interruption issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/victoralwaysyoung/youngscoolplay"
SERVICE_NAME="youngscoolplay"
INSTALL_DIR="/opt/youngscoolplay"
CONFIG_DIR="/etc/youngscoolplay"
LOG_DIR="/var/log/youngscoolplay"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

fix_dpkg_issues() {
    print_info "Fixing package manager issues..."
    
    # Kill any running dpkg processes
    pkill -f dpkg 2>/dev/null || true
    pkill -f apt 2>/dev/null || true
    
    # Remove lock files if they exist
    rm -f /var/lib/dpkg/lock-frontend 2>/dev/null || true
    rm -f /var/lib/dpkg/lock 2>/dev/null || true
    rm -f /var/cache/apt/archives/lock 2>/dev/null || true
    
    # Configure any unconfigured packages
    print_info "Configuring interrupted packages..."
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a
    
    # Fix broken packages
    print_info "Fixing broken packages..."
    apt --fix-broken install -y
    
    print_success "Package manager issues fixed"
}

check_system() {
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS version"
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        print_error "This script is designed for Ubuntu only. Detected: $ID"
        exit 1
    fi
    
    if [[ $(echo "$VERSION_ID >= 20.04" | bc -l) -ne 1 ]]; then
        print_error "Ubuntu 20.04 or higher is required. Current version: $VERSION_ID"
        exit 1
    fi
    
    if [[ $(echo "$VERSION_ID >= 24.04" | bc -l) -ne 1 ]]; then
        print_warning "This script is optimized for Ubuntu 24.04+. Current version: $VERSION_ID"
    fi
}

install_dependencies() {
    print_info "Installing dependencies..."
    
    # Clean package cache
    apt clean
    apt autoclean
    
    # Update package lists with retry
    for i in {1..3}; do
        print_info "Updating package lists (attempt $i/3)..."
        if apt update; then
            break
        else
            print_warning "Package update failed, retrying..."
            sleep 3
            if [[ $i -eq 3 ]]; then
                print_error "Failed to update package lists after 3 attempts"
                exit 1
            fi
        fi
    done
    
    # Install dependencies with error handling
    print_info "Installing required packages..."
    if ! DEBIAN_FRONTEND=noninteractive apt install -y curl wget tar unzip systemd bc; then
        print_error "Failed to install dependencies"
        print_info "Attempting to fix and retry..."
        apt --fix-broken install -y
        DEBIAN_FRONTEND=noninteractive apt install -y curl wget tar unzip systemd bc
    fi
    
    print_success "Dependencies installed successfully"
}

install_go() {
    print_info "Checking Go installation..."
    
    # Check if Go is already installed and version is sufficient
    if command -v go >/dev/null 2>&1; then
        GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
        MAJOR_VERSION=$(echo $GO_VERSION | cut -d. -f1)
        MINOR_VERSION=$(echo $GO_VERSION | cut -d. -f2)
        
        if [[ $MAJOR_VERSION -gt 1 ]] || [[ $MAJOR_VERSION -eq 1 && $MINOR_VERSION -ge 21 ]]; then
            print_success "Go $GO_VERSION is already installed"
            return 0
        else
            print_warning "Go version $GO_VERSION is too old, installing Go 1.21.5..."
        fi
    else
        print_info "Go not found, installing Go 1.21.5..."
    fi
    
    # Remove old Go installation if exists
    rm -rf /usr/local/go
    
    # Download and install Go 1.21.5
    GO_VERSION="1.21.5"
    GO_ARCH=""
    case $(uname -m) in
        x86_64)
            GO_ARCH="amd64"
            ;;
        aarch64)
            GO_ARCH="arm64"
            ;;
        armv7l)
            GO_ARCH="armv6l"
            ;;
        *)
            print_error "Unsupported architecture for Go: $(uname -m)"
            exit 1
            ;;
    esac
    
    GO_TARBALL="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    GO_URL="https://golang.org/dl/${GO_TARBALL}"
    
    print_info "Downloading Go ${GO_VERSION}..."
    if ! wget -q --show-progress "$GO_URL" -O "/tmp/${GO_TARBALL}"; then
        print_error "Failed to download Go"
        exit 1
    fi
    
    print_info "Installing Go ${GO_VERSION}..."
    tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
    
    # Add Go to PATH
    if ! grep -q "/usr/local/go/bin" /etc/environment; then
        echo 'PATH="/usr/local/go/bin:$PATH"' >> /etc/environment
    fi
    
    # Add Go to current session PATH
    export PATH="/usr/local/go/bin:$PATH"
    
    # Add Go to profile for all users
    cat > /etc/profile.d/go.sh << 'EOF'
export PATH="/usr/local/go/bin:$PATH"
export GOROOT="/usr/local/go"
export GOPATH="/root/go"
EOF
    
    # Source the profile
    source /etc/profile.d/go.sh
    
    # Clean up
    rm -f "/tmp/${GO_TARBALL}"
    
    # Verify installation
    if command -v go >/dev/null 2>&1; then
        GO_INSTALLED_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+')
        print_success "Go ${GO_INSTALLED_VERSION} installed successfully"
    else
        print_error "Go installation failed"
        exit 1
    fi
}

detect_architecture() {
    case $(uname -m) in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        *)
            print_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
    print_info "Detected architecture: $ARCH"
}

download_and_install() {
    print_info "Downloading YoungsCoolPlay..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download the latest release archive
    DOWNLOAD_URL="https://github.com/victoralwaysyoung/youngscoolplay/archive/refs/heads/master.tar.gz"
    
    if ! wget -q --show-progress "$DOWNLOAD_URL" -O "youngscoolplay.tar.gz"; then
        print_error "Failed to download YoungsCoolPlay"
        exit 1
    fi
    
    # Extract archive
    print_info "Extracting files..."
    tar -xzf youngscoolplay.tar.gz
    cd youngscoolplay-master
    
    # Create directories
    print_info "Creating directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    
    # Copy files
    print_info "Installing files..."
    cp -r web "$INSTALL_DIR/"
    cp -r config "$INSTALL_DIR/"
    cp .env.example "$INSTALL_DIR/"
    
    # Copy the config.json file to web/service directory for Go embed
    print_info "Setting up configuration files..."
    if [[ -f "../web/service/config.json" ]]; then
        cp "../web/service/config.json" "web/service/"
    elif [[ -f "../../web/service/config.json" ]]; then
        cp "../../web/service/config.json" "web/service/"
    else
        print_info "Creating default config.json for embed..."
        cat > "web/service/config.json" << 'EOF'
{
  "log": {
    "access": "none",
    "dnsLog": false,
    "error": "",
    "loglevel": "warning",
    "maskAddress": ""
  },
  "api": {
    "tag": "api",
    "services": [
      "HandlerService",
      "LoggerService",
      "StatsService"
    ]
  },
  "inbounds": [
    {
      "tag": "api",
      "listen": "127.0.0.1",
      "port": 62789,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs",
        "redirect": "",
        "noises": []
      }
    },
    {
      "tag": "blocked",
      "protocol": "blackhole",
      "settings": {}
    }
  ],
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink": true,
      "statsOutboundDownlink": true
    }
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api"
      }
    ]
  },
  "stats": {},
  "transport": {},
  "dns": {},
  "fakedns": {},
  "metrics": {
    "tag": "metrics_out",
    "listen": "127.0.0.1:11111"
  }
}
EOF
    fi
    
    # Copy geo files if they exist
    if [[ -d "bin" ]]; then
        cp -r bin "$INSTALL_DIR/"
    fi
    
    # Build the binary
    print_info "Building YoungsCoolPlay binary..."
    
    # Ensure Go is in PATH
    export PATH="/usr/local/go/bin:$PATH"
    export GOROOT="/usr/local/go"
    export GOPROXY="https://goproxy.cn,direct"
    export GO111MODULE=on
    
    # Verify Go is available
    if ! command -v go >/dev/null 2>&1; then
        print_error "Go compiler not found in PATH"
        exit 1
    fi
    
    print_info "Using Go version: $(go version)"
    
    # Initialize Go module if go.mod doesn't exist
    if [[ ! -f "go.mod" ]]; then
        print_info "Initializing Go module..."
        go mod init youngscoolplay
    fi
    
    # Download dependencies
    print_info "Downloading Go dependencies..."
    if ! go mod tidy; then
        print_error "Failed to download Go dependencies"
        exit 1
    fi
    
    # Build with proper flags
    print_info "Compiling binary..."
    if ! go build -ldflags "-s -w" -o "$INSTALL_DIR/youngscoolplay" .; then
        print_error "Failed to build YoungsCoolPlay"
        print_error "Build output above may contain more details"
        exit 1
    fi
    
    # Set permissions
    chmod +x "$INSTALL_DIR/youngscoolplay"
    chown -R root:root "$INSTALL_DIR"
    
    # Clean up
    cd /
    rm -rf "$TEMP_DIR"
    
    print_success "YoungsCoolPlay installed successfully"
}

create_service() {
    print_info "Creating systemd service..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=YoungsCoolPlay - Advanced Xray Panel
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/youngscoolplay run
Restart=always
RestartSec=5
Environment=XUI_LOG_LEVEL=info

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    
    print_success "Service created and enabled"
}

configure_firewall() {
    print_info "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 2053/tcp comment "YoungsCoolPlay Panel"
        ufw allow 443/tcp comment "HTTPS"
        ufw allow 80/tcp comment "HTTP"
        print_success "UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=2053/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --reload
        print_success "Firewalld configured"
    else
        print_warning "No firewall detected. Please manually open ports 2053, 443, and 80"
    fi
}

start_service() {
    print_info "Starting YoungsCoolPlay service..."
    
    if systemctl start "$SERVICE_NAME"; then
        print_success "YoungsCoolPlay started successfully"
    else
        print_error "Failed to start YoungsCoolPlay"
        print_info "Checking service status..."
        systemctl status "$SERVICE_NAME" --no-pager
        exit 1
    fi
}

show_info() {
    print_success "Installation completed successfully!"
    echo
    echo "=========================================="
    echo "  YoungsCoolPlay Installation Complete"
    echo "=========================================="
    echo
    echo "Panel URL: http://$(hostname -I | awk '{print $1}'):2053"
    echo "Default Username: admin"
    echo "Default Password: admin"
    echo
    echo "Service Commands:"
    echo "  Start:   systemctl start $SERVICE_NAME"
    echo "  Stop:    systemctl stop $SERVICE_NAME"
    echo "  Restart: systemctl restart $SERVICE_NAME"
    echo "  Status:  systemctl status $SERVICE_NAME"
    echo "  Logs:    journalctl -u $SERVICE_NAME -f"
    echo
    echo "Configuration:"
    echo "  Install Directory: $INSTALL_DIR"
    echo "  Config Directory:  $CONFIG_DIR"
    echo "  Log Directory:     $LOG_DIR"
    echo
    echo "⚠️  IMPORTANT: Please change the default password after first login!"
    echo
}

# Main installation process
main() {
    echo "========================================"
    echo "  YoungsCoolPlay Installation Script"
    echo "========================================"
    echo
    
    check_root
    fix_dpkg_issues
    check_system
    detect_architecture
    install_dependencies
    install_go
    download_and_install
    create_service
    configure_firewall
    start_service
    show_info
}

# Run main function
main "$@"