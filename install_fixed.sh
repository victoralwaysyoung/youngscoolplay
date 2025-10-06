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
    
    # Copy geo files if they exist
    if [[ -d "bin" ]]; then
        cp -r bin "$INSTALL_DIR/"
    fi
    
    # Build the binary
    print_info "Building YoungsCoolPlay binary..."
    export GOROOT=""
    export GOPROXY="https://goproxy.cn,direct"
    export GO111MODULE=on
    
    if ! go build -ldflags "-s -w" -o "$INSTALL_DIR/youngscoolplay" main.go; then
        print_error "Failed to build YoungsCoolPlay"
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
    download_and_install
    create_service
    configure_firewall
    start_service
    show_info
}

# Run main function
main "$@"