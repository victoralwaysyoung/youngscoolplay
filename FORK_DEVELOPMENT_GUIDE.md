# YoungsCoolPlay - 二次开发说明文档

## 项目概述
本项目是基于 [3x-ui](https://github.com/MHSanaei/3x-ui) 的二次开发版本，项目名称为 `youngscoolplay`。

## 遇到的问题及解决方案

### 1. Go模块依赖问题
**问题描述**: 
- 项目名称更改后，Go编译器在错误路径查找标准库包
- 出现 `math/rand/v2`、`crypto/mlkem` 等包找不到的错误

**解决方案**:
```bash
# 1. 清理Go模块缓存
go clean -modcache

# 2. 删除go.sum文件
rm go.sum

# 3. 设置Go代理
go env -w GOPROXY=https://goproxy.cn,direct

# 4. 重新下载依赖
go mod download

# 5. 重新构建
go build -o youngscoolplay.exe main.go
```

### 2. UTF-8编码问题
**问题描述**: 
- 代码中存在无效UTF-8字符导致编译失败
- 主要出现在 `web/service/tgbot.go` 和 `sub/subService.go`

**解决方案**:
- 将无效字符 `` 替换为正确的emoji符号 `❌` 和 `✅`
- 修复格式化字符串中的无效字符

### 3. XRAY核心文件缺失
**问题描述**: 
- `bin` 目录不存在
- 缺少XRAY可执行文件导致服务启动失败

**解决方案**:
```bash
# 1. 创建bin目录
mkdir bin

# 2. 下载对应版本的XRAY核心文件
# 根据go.mod中的版本 v1.250803.0 下载对应的xray-windows-amd64.exe
```

## 二次开发规范流程

### 1. 项目差异化处理
- [x] 修改项目模块名称：`youngscoolplay`
- [x] 更新 `go.mod` 中的模块路径
- [x] 创建独立的二次开发说明文档
- [ ] 添加项目标识和版权信息

### 2. 依赖关系处理
- [x] 检查Go模块依赖关系
- [x] 修复import路径引用问题
- [x] 确保外部依赖完整性
- [ ] 验证所有跨目录引用

### 3. 环境配置
- [x] 安装Go依赖项
- [x] 配置Go环境变量
- [x] 下载必要的二进制文件（XRAY核心）
- [ ] 配置开发环境变量文件
- [ ] 设置调试配置

### 4. 调试启动
- [x] 成功编译项目
- [x] 验证可执行文件功能
- [ ] 配置VS Code调试环境
- [ ] 设置热更新机制

## 项目结构说明

```
youngscoolplay/
├── bin/                    # 二进制文件目录（XRAY核心）
├── config/                 # 配置文件
├── database/              # 数据库相关
├── web/                   # Web界面和服务
├── xray/                  # XRAY相关代码
├── go.mod                 # Go模块定义
├── main.go               # 主程序入口
└── FORK_DEVELOPMENT_GUIDE.md  # 本文档
```

## 关键修改点

1. **模块名称**: `github.com/MHSanaei/3x-ui` → `youngscoolplay`
2. **可执行文件**: `x-ui` → `youngscoolplay.exe`
3. **XRAY版本**: 使用 `v1.250803.0` 对应的核心文件

## 开发注意事项

1. **编码规范**: 确保所有文件使用UTF-8编码，避免特殊字符
2. **依赖管理**: 定期更新依赖，注意版本兼容性
3. **路径引用**: 使用相对路径时要考虑项目结构变化
4. **二进制文件**: XRAY核心文件需要与go.mod中的版本保持一致

## 版本信息

- **原项目**: 3x-ui v2.6.6
- **二次开发版本**: youngscoolplay v1.0.0
- **Go版本**: 1.24.5
- **XRAY版本**: v1.250803.0

## 联系信息

- **GitHub仓库**: https://github.com/victoralwaysyoung/youngscoolplay.git
- **开发者**: victoralwaysyoung