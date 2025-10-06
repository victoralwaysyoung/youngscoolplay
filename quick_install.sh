#!/bin/bash

# 3x-ui Quick Install Script
# 一键安装脚本 - 服务器端使用

# 项目信息
GITHUB_USER="victoralwaysyoung"
GITHUB_REPO="youngscoolplay"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查root权限
[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 请使用root权限运行此脚本${NC}" && exit 1

echo -e "${BLUE}正在下载并执行完整安装脚本...${NC}"

# 下载并执行完整安装脚本
bash <(curl -Ls https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/master/server_download.sh)