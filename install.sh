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
    # 跨发行版系统检测，对齐原作者逻辑
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        RELEASE_ID="$ID"
    elif [[ -f /usr/lib/os-release ]]; then
        . /usr/lib/os-release
        RELEASE_ID="$ID"
    else
        print_error "无法识别系统类型，请联系作者"
        exit 1
    fi
    print_info "检测到系统: ${RELEASE_ID}"
}

# 安装基础依赖（对齐原作者 install_base）
install_base() {
    case "${RELEASE_ID}" in
        ubuntu|debian|armbian)
            apt-get update && apt-get install -y -q wget curl tar tzdata unzip bc
            ;;
        centos|rhel|almalinux|rocky|ol)
            yum -y update && yum install -y -q wget curl tar tzdata unzip bc
            ;;
        fedora|amzn|virtuozzo)
            dnf -y update && dnf install -y -q wget curl tar tzdata unzip bc
            ;;
        arch|manjaro|parch)
            pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata unzip bc
            ;;
        opensuse-tumbleweed|opensuse-leap)
            zypper refresh && zypper -q install -y wget curl tar timezone unzip bc
            ;;
        alpine)
            apk update && apk add wget curl tar tzdata unzip bc
            ;;
        *)
            # 默认按Debian系处理
            apt-get update && apt-get install -y -q wget curl tar tzdata unzip bc
            ;;
    esac
}

install_dependencies() {
    print_info "安装依赖..."
    # 先尝试修复Debian系的dpkg状态（非Debian系忽略）
    dpkg --configure -a 2>/dev/null || true
    
    # 跨发行版安装基础依赖
    install_base
    
    # 安装Go（若未安装），保持与原作者一致的下载方式
    if ! command -v go &> /dev/null; then
        print_info "安装Go..."
        GO_VERSION="1.21.5"
        wget --inet4-only -q "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
        tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
        export PATH=$PATH:/usr/local/go/bin
        rm "go${GO_VERSION}.linux-amd64.tar.gz"
    fi
    print_success "依赖安装完成"
}

detect_architecture() {
    # 双映射：发布资产架构 ASSET_ARCH，程序期望的Xray可执行命名 XRAY_NAME_ARCH，Xray压缩包架构 XRAY_ZIP_ARCH
    case "$(uname -m)" in
        x86_64|x64|amd64)
            ASSET_ARCH="amd64"; XRAY_NAME_ARCH="amd64"; XRAY_ZIP_ARCH="64";
            ;;
        i*86|x86)
            ASSET_ARCH="386"; XRAY_NAME_ARCH="386"; XRAY_ZIP_ARCH="32";
            ;;
        aarch64|arm64|armv8|armv8*)
            ASSET_ARCH="arm64"; XRAY_NAME_ARCH="arm64"; XRAY_ZIP_ARCH="arm64-v8a";
            ;;
        armv7l|armv7|arm)
            # 发布资产沿用 armv7；程序运行期望为 arm；Xray压缩包使用 arm32-v7a
            ASSET_ARCH="armv7"; XRAY_NAME_ARCH="arm"; XRAY_ZIP_ARCH="arm32-v7a";
            ;;
        s390x)
            ASSET_ARCH="s390x"; XRAY_NAME_ARCH="s390x"; XRAY_ZIP_ARCH="s390x";
            ;;
        *)
            print_error "不支持的架构: $(uname -m)"
            exit 1
            ;;
    esac
    print_info "发布资产架构: ${ASSET_ARCH}；Xray命名架构: ${XRAY_NAME_ARCH}；Xray压缩包架构: ${XRAY_ZIP_ARCH}"
}

download_release() {
    print_info "下载 YoungsCoolPlay 发布包..."
    # 获取最新版本；失败时回退到IPv4
    LATEST_RELEASE=$(curl -Ls "https://api.github.com/repos/victoralwaysyoung/youngscoolplay/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -z "$LATEST_RELEASE" ]]; then
        print_warning "尝试使用IPv4获取版本信息..."
        LATEST_RELEASE=$(curl -4 -Ls "https://api.github.com/repos/victoralwaysyoung/youngscoolplay/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ -z "$LATEST_RELEASE" ]]; then
            print_error "获取最新版本失败，可能GitHub API受限"
            exit 1
        fi
    fi
    print_info "最新版本: ${LATEST_RELEASE}"
    
    DOWNLOAD_URL="https://github.com/victoralwaysyoung/youngscoolplay/releases/download/${LATEST_RELEASE}/youngscoolplay-linux-${ASSET_ARCH}.tar.gz"
    cd /tmp
    wget --inet4-only -q --show-progress "$DOWNLOAD_URL" -O "youngscoolplay-linux-${ASSET_ARCH}.tar.gz" || {
        print_error "发布包下载失败"
        exit 1
    }
    print_success "发布包下载完成"
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
    tar -xzf "youngscoolplay-linux-${ASSET_ARCH}.tar.gz"
    
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
    print_info "下载 Xray 核心..."
    XRAY_VERSION="v1.8.24"
    cd "$INSTALL_DIR/bin"
    
    local XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-${XRAY_ZIP_ARCH}.zip"
    print_info "Xray 下载地址: ${XRAY_URL}"
    wget --inet4-only -q --show-progress "$XRAY_URL" -O "Xray-linux-${XRAY_ZIP_ARCH}.zip" || {
        print_error "Xray 下载失败"
        exit 1
    }
    unzip -q "Xray-linux-${XRAY_ZIP_ARCH}.zip"
    rm "Xray-linux-${XRAY_ZIP_ARCH}.zip"
    
    # 按程序期望重命名
    mv xray "xray-linux-${XRAY_NAME_ARCH}"
    chmod +x "xray-linux-${XRAY_NAME_ARCH}"
    
    # 下载 geo 数据（可选）
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat || true
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat || true
    
    print_success "Xray 核心安装完成"
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