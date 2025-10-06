# 服务器端安装指南

## 一键安装（推荐）

在服务器上执行以下命令即可一键安装：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay/master/quick_install.sh)
```

## 手动安装

如果一键安装失败，可以手动下载安装脚本：

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay/master/server_download.sh

# 给予执行权限
chmod +x server_download.sh

# 执行安装
sudo ./server_download.sh
```

## 安装要求

- **操作系统**: Linux (Ubuntu/Debian/CentOS)
- **权限**: Root权限
- **网络**: 能够访问GitHub和Go官方网站
- **架构**: x86_64, ARM64, ARMv7

## 安装过程

安装脚本会自动完成以下步骤：

1. ✅ 检查系统环境
2. ✅ 安装必要依赖 (curl, wget, tar, unzip, git)
3. ✅ 安装Go环境 (如果未安装)
4. ✅ 下载项目源码
5. ✅ 编译项目
6. ✅ 安装到系统目录
7. ✅ 创建系统服务
8. ✅ 启动服务

## 安装后信息

- **安装目录**: `/usr/local/x-ui`
- **访问地址**: `http://your-server-ip:2053`
- **默认用户名**: `admin`
- **默认密码**: `admin`

## 常用命令

```bash
# 启动服务
systemctl start x-ui

# 停止服务
systemctl stop x-ui

# 重启服务
systemctl restart x-ui

# 查看服务状态
systemctl status x-ui

# 查看服务日志
journalctl -u x-ui -f

# 管理面板
x-ui
```

## 防火墙设置

如果使用防火墙，请开放相应端口：

```bash
# Ubuntu/Debian (ufw)
ufw allow 2053

# CentOS (firewalld)
firewall-cmd --permanent --add-port=2053/tcp
firewall-cmd --reload

# CentOS (iptables)
iptables -I INPUT -p tcp --dport 2053 -j ACCEPT
```

## 卸载

如需卸载，执行以下命令：

```bash
# 停止并禁用服务
systemctl stop x-ui
systemctl disable x-ui

# 删除服务文件
rm -f /etc/systemd/system/x-ui.service

# 删除安装目录
rm -rf /usr/local/x-ui

# 删除符号链接
rm -f /usr/local/bin/x-ui

# 重新加载systemd
systemctl daemon-reload
```

## 故障排除

### 1. 安装失败

- 检查网络连接
- 确保有root权限
- 查看错误日志

### 2. 服务启动失败

```bash
# 查看详细日志
journalctl -u x-ui -f

# 检查端口占用
netstat -tlnp | grep :2053

# 手动启动测试
cd /usr/local/x-ui
./youngscoolplay run
```

### 3. 无法访问面板

- 检查防火墙设置
- 确认服务正在运行
- 检查端口配置

## 更新

要更新到最新版本，重新运行安装脚本即可：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay/master/quick_install.sh)
```

## 支持

如遇问题，请在GitHub提交Issue：
https://github.com/victoralwaysyoung/youngscoolplay/issues