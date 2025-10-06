#!/bin/bash

# 3x-ui Server Download Script
# 服务器端一键下载安装脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
GITHUB_USER="victoralwaysyoung"
GITHUB_REPO="youngscoolplay"
PROJECT_NAME="youngscoolplay"
INSTALL_DIR="/usr/local/x-ui"

# 打印信息函数
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

# 检查系统要求
check_system() {
    print_info "检查系统环境..."
    
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本需要root权限运行"
        print_info "请使用: sudo $0"
        exit 1
    fi
    
    # 检查系统类型
    if [[ -f /etc/redhat-release ]]; then
        SYSTEM="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        SYSTEM="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        SYSTEM="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        SYSTEM="centos"
    elif cat /proc/version | grep -Eqi "debian"; then
        SYSTEM="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        SYSTEM="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        SYSTEM="centos"
    else
        print_warning "未能识别系统类型，将尝试通用安装方式"
        SYSTEM="unknown"
    fi
    
    print_success "系统检查完成: $SYSTEM"
}

# 安装依赖
install_dependencies() {
    print_info "安装必要依赖..."
    
    case $SYSTEM in
        "centos")
            yum update -y
            yum install -y curl wget tar unzip git
            ;;
        "ubuntu"|"debian")
            apt-get update -y
            apt-get install -y curl wget tar unzip git
            ;;
        *)
            print_warning "请手动安装以下依赖: curl wget tar unzip git"
            ;;
    esac
    
    print_success "依赖安装完成"
}

# 获取最新版本
get_latest_version() {
    print_info "获取最新版本信息..."
    
    # 尝试从GitHub API获取最新版本
    LATEST_VERSION=$(curl -s "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$LATEST_VERSION" ]]; then
        print_warning "无法获取最新版本，使用master分支"
        LATEST_VERSION="master"
    fi
    
    print_success "最新版本: $LATEST_VERSION"
}

# 下载项目
download_project() {
    print_info "下载项目文件..."
    
    # 创建临时目录
    TEMP_DIR="/tmp/${PROJECT_NAME}_install"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # 下载源码
    if [[ "$LATEST_VERSION" == "master" ]]; then
        DOWNLOAD_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/archive/refs/heads/master.zip"
        print_info "下载地址: $DOWNLOAD_URL"
        wget -O "${PROJECT_NAME}.zip" "$DOWNLOAD_URL" || {
            print_error "下载失败，请检查网络连接"
            exit 1
        }
        unzip -q "${PROJECT_NAME}.zip"
        mv "${GITHUB_REPO}-master" "$PROJECT_NAME"
    else
        DOWNLOAD_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/archive/refs/tags/$LATEST_VERSION.zip"
        print_info "下载地址: $DOWNLOAD_URL"
        wget -O "${PROJECT_NAME}.zip" "$DOWNLOAD_URL" || {
            print_error "下载失败，请检查网络连接"
            exit 1
        }
        unzip -q "${PROJECT_NAME}.zip"
        mv "${GITHUB_REPO}-${LATEST_VERSION#v}" "$PROJECT_NAME"
    fi
    
    print_success "项目下载完成"
}

# 下载Xray核心
download_xray() {
    print_info "下载Xray核心..."
    
    cd "$TEMP_DIR/$PROJECT_NAME"
    
    # 获取系统架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            XRAY_ARCH="64"
            BINARY_ARCH="amd64"
            ;;
        aarch64|arm64)
            XRAY_ARCH="arm64-v8a"
            BINARY_ARCH="arm64"
            ;;
        armv7l)
            XRAY_ARCH="arm32-v7a"
            BINARY_ARCH="armv7"
            ;;
        armv6l)
            XRAY_ARCH="arm32-v6"
            BINARY_ARCH="armv6"
            ;;
        *)
            print_error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac
    
    # 创建bin目录
    mkdir -p bin
    cd bin
    
    # 下载Xray核心 (使用最新稳定版本)
    XRAY_VERSION="v1.8.24"
    XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-${XRAY_ARCH}.zip"
    
    print_info "下载地址: $XRAY_URL"
    wget -q --show-progress "$XRAY_URL" -O "Xray-linux-${XRAY_ARCH}.zip" || {
        print_error "Xray核心下载失败"
        exit 1
    }
    
    # 解压并重命名
    unzip -q "Xray-linux-${XRAY_ARCH}.zip"
    rm "Xray-linux-${XRAY_ARCH}.zip"
    
    # 重命名为期望的文件名
    mv xray "xray-linux-${BINARY_ARCH}"
    chmod +x "xray-linux-${BINARY_ARCH}"
    
    # 下载geo数据文件
    print_info "下载geo数据文件..."
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat || {
        print_warning "geoip.dat下载失败，将使用默认文件"
    }
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat || {
        print_warning "geosite.dat下载失败，将使用默认文件"
    }
    
    cd ..
    print_success "Xray核心安装完成"
}

# 安装Go环境
install_go() {
    print_info "检查Go环境..."
    
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        print_success "Go已安装，版本: $GO_VERSION"
        return
    fi
    
    print_info "安装Go环境..."
    
    # 获取系统架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            GO_ARCH="amd64"
            ;;
        aarch64|arm64)
            GO_ARCH="arm64"
            ;;
        armv7l)
            GO_ARCH="armv6l"
            ;;
        *)
            print_error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac
    
    # 下载并安装Go
    GO_VERSION="1.21.5"
    GO_TAR="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    
    cd /tmp
    wget "https://golang.org/dl/$GO_TAR" || {
        print_error "Go下载失败"
        exit 1
    }
    
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "$GO_TAR"
    
    # 设置环境变量
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    export PATH=$PATH:/usr/local/go/bin
    
    print_success "Go安装完成"
}

# 编译项目
compile_project() {
    print_info "编译项目..."
    
    cd "$TEMP_DIR/$PROJECT_NAME"
    
    # 设置Go环境
    export GO111MODULE=on
    export GOPROXY=https://goproxy.cn,direct
    
    # 编译
    print_info "开始编译..."
    go mod tidy
    go build -o "${PROJECT_NAME}" main.go || {
        print_error "编译失败"
        exit 1
    }
    
    print_success "编译完成"
}

# 安装项目
install_project() {
    print_info "安装项目到系统..."
    
    # 停止现有服务
    if systemctl is-active --quiet x-ui; then
        print_info "停止现有x-ui服务..."
        systemctl stop x-ui
    fi
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    # 复制文件
    cd "$TEMP_DIR/$PROJECT_NAME"
    cp "$PROJECT_NAME" "$INSTALL_DIR/"
    cp -r bin "$INSTALL_DIR/"
    cp -r web "$INSTALL_DIR/"
    cp .env.example "$INSTALL_DIR/"
    
    # 设置权限
    chmod +x "$INSTALL_DIR/$PROJECT_NAME"
    
    # 创建符号链接
    ln -sf "$INSTALL_DIR/$PROJECT_NAME" /usr/local/bin/x-ui
    
    print_success "项目安装完成"
}

# 创建系统服务
create_service() {
    print_info "创建系统服务..."
    
    cat > /etc/systemd/system/x-ui.service << EOF
[Unit]
Description=3x-ui web panel
After=network.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStart=$INSTALL_DIR/$PROJECT_NAME run
WorkingDirectory=$INSTALL_DIR
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable x-ui
    
    print_success "系统服务创建完成"
}

# 启动服务
start_service() {
    print_info "启动x-ui服务..."
    
    systemctl start x-ui
    
    if systemctl is-active --quiet x-ui; then
        print_success "x-ui服务启动成功"
    else
        print_error "x-ui服务启动失败"
        print_info "请检查日志: journalctl -u x-ui -f"
        exit 1
    fi
}

# 显示安装信息
show_info() {
    print_success "安装完成！"
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  3x-ui 安装成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${BLUE}安装目录:${NC} $INSTALL_DIR"
    echo -e "${BLUE}配置文件:${NC} $INSTALL_DIR/x-ui.db"
    echo -e "${BLUE}访问地址:${NC} http://your-server-ip:2053"
    echo -e "${BLUE}默认用户名:${NC} admin"
    echo -e "${BLUE}默认密码:${NC} admin"
    echo
    echo -e "${YELLOW}常用命令:${NC}"
    echo -e "  启动服务: ${GREEN}systemctl start x-ui${NC}"
    echo -e "  停止服务: ${GREEN}systemctl stop x-ui${NC}"
    echo -e "  重启服务: ${GREEN}systemctl restart x-ui${NC}"
    echo -e "  查看状态: ${GREEN}systemctl status x-ui${NC}"
    echo -e "  查看日志: ${GREEN}journalctl -u x-ui -f${NC}"
    echo -e "  管理面板: ${GREEN}x-ui${NC}"
    echo
    echo -e "${RED}重要提示:${NC}"
    echo -e "1. 请及时修改默认用户名和密码"
    echo -e "2. 建议配置防火墙规则"
    echo -e "3. 定期备份配置文件"
    echo
}

# 清理临时文件
cleanup() {
    print_info "清理临时文件..."
    rm -rf "$TEMP_DIR"
    print_success "清理完成"
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "========================================="
    echo "  3x-ui 服务器端安装脚本"
    echo "  GitHub: https://github.com/$GITHUB_USER/$GITHUB_REPO"
    echo "========================================="
    echo -e "${NC}"
    
    check_system
    install_dependencies
    get_latest_version
    download_project
    download_xray
    install_go
    compile_project
    install_project
    create_service
    start_service
    show_info
    cleanup
    
    print_success "所有步骤完成！"
}

# 错误处理
trap 'print_error "安装过程中出现错误，正在清理..."; cleanup; exit 1' ERR

# 运行主函数
main "$@"