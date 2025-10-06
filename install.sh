#!/bin/bash

# YoungsCoolPlay Installation Script for Ubuntu 24.04+
# Author: victoralwaysyoung
# Version: 1.0.0

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

check_system() {
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS version"
        exit 1
    fi
    
    . /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        print_warning "This script is designed for Ubuntu. Proceeding anyway..."
    fi
    
    if [[ $(echo "$VERSION_ID >= 24.04" | bc -l) -ne 1 ]]; then
        print_warning "This script is optimized for Ubuntu 24.04+. Current version: $VERSION_ID"
    fi
}

install_dependencies() {
    print_info "Installing dependencies..."
    
    apt update
    apt install -y curl wget tar unzip systemd bc
    
    # Install Go if not present
    if ! command -v go &> /dev/null; then
        print_info "Installing Go..."
        GO_VERSION="1.21.5"
        wget -q "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
        tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
        export PATH=$PATH:/usr/local/go/bin
        rm "go${GO_VERSION}.linux-amd64.tar.gz"
    fi
    
    print_success "Dependencies installed"
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

download_release() {
    print_info "Downloading YoungsCoolPlay..."
    
    # Get latest release info
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/victoralwaysyoung/youngscoolplay/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$LATEST_RELEASE" ]]; then
        print_error "Failed to get latest release information"
        exit 1
    fi
    
    print_info "Latest version: $LATEST_RELEASE"
    
    # Download release
    DOWNLOAD_URL="https://github.com/victoralwaysyoung/youngscoolplay/releases/download/${LATEST_RELEASE}/youngscoolplay-linux-${ARCH}.tar.gz"
    
    cd /tmp
    wget -q --show-progress "$DOWNLOAD_URL" -O "youngscoolplay-linux-${ARCH}.tar.gz"
    
    if [[ ! -f "youngscoolplay-linux-${ARCH}.tar.gz" ]]; then
        print_error "Failed to download YoungsCoolPlay"
        exit 1
    fi
    
    print_success "Download completed"
}

install_application() {
    print_info "Installing YoungsCoolPlay..."
    
    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$INSTALL_DIR/bin"
    mkdir -p "$INSTALL_DIR/db"
    
    # Extract application
    cd /tmp
    tar -xzf "youngscoolplay-linux-${ARCH}.tar.gz"
    
    # Copy files
    cp youngscoolplay "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/youngscoolplay"
    
    # Copy configuration files if they exist
    if [[ -f ".env.example" ]]; then
        cp .env.example "$CONFIG_DIR/"
    fi
    
    print_success "Application installed to $INSTALL_DIR"
}

download_xray() {
    print_info "Downloading Xray core..."
    
    # Get Xray version from go.mod or use latest
    XRAY_VERSION="v1.8.3"  # This should match the version in go.mod
    
    cd "$INSTALL_DIR/bin"
    
    # Download Xray
    XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip"
    wget -q --show-progress "$XRAY_URL" -O "Xray-linux-64.zip"
    
    unzip -q "Xray-linux-64.zip"
    rm "Xray-linux-64.zip"
    
    # Rename binary to expected name
    if [[ "$ARCH" == "amd64" ]]; then
        mv xray "xray-linux-amd64"
    elif [[ "$ARCH" == "arm64" ]]; then
        mv xray "xray-linux-arm64"
    else
        mv xray "xray-linux-${ARCH}"
    fi
    
    chmod +x "xray-linux-${ARCH}"
    
    print_success "Xray core installed"
}

create_service() {
    print_info "Creating systemd service..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=YoungsCoolPlay Web Panel
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/youngscoolplay run
Restart=on-failure
RestartSec=5s
Environment=XUI_BIN_FOLDER=$INSTALL_DIR/bin
Environment=XUI_DB_FOLDER=$INSTALL_DIR/db
Environment=XUI_LOG_FOLDER=$LOG_DIR

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
        ufw allow 2053/tcp
        print_success "UFW rule added for port 2053"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=2053/tcp
        firewall-cmd --reload
        print_success "Firewalld rule added for port 2053"
    else
        print_warning "No firewall detected. Please manually open port 2053"
    fi
}

start_service() {
    print_info "Starting YoungsCoolPlay service..."
    
    systemctl start "$SERVICE_NAME"
    
    # Wait a moment and check status
    sleep 3
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_success "YoungsCoolPlay started successfully"
    else
        print_error "Failed to start YoungsCoolPlay"
        print_info "Check logs with: journalctl -u $SERVICE_NAME -f"
        exit 1
    fi
}

show_info() {
    print_success "Installation completed!"
    echo
    echo "========================================"
    echo "  YoungsCoolPlay Installation Complete"
    echo "========================================"
    echo
    echo "Web Panel: http://$(curl -s ifconfig.me):2053"
    echo "Username: admin"
    echo "Password: admin"
    echo
    echo "Service Management:"
    echo "  Start:   systemctl start $SERVICE_NAME"
    echo "  Stop:    systemctl stop $SERVICE_NAME"
    echo "  Restart: systemctl restart $SERVICE_NAME"
    echo "  Status:  systemctl status $SERVICE_NAME"
    echo "  Logs:    journalctl -u $SERVICE_NAME -f"
    echo
    echo "Configuration:"
    echo "  Install Dir: $INSTALL_DIR"
    echo "  Config Dir:  $CONFIG_DIR"
    echo "  Log Dir:     $LOG_DIR"
    echo
    print_warning "Please change the default password after first login!"
    echo
}

cleanup() {
    print_info "Cleaning up temporary files..."
    rm -f /tmp/youngscoolplay-linux-*.tar.gz
    rm -rf /tmp/youngscoolplay*
}

main() {
    echo "========================================"
    echo "  YoungsCoolPlay Installation Script"
    echo "========================================"
    echo
    
    check_root
    check_system
    detect_architecture
    install_dependencies
    download_release
    install_application
    download_xray
    create_service
    configure_firewall
    start_service
    cleanup
    show_info
}

# Handle script interruption
trap 'print_error "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"