# YoungsCoolPlay - 二次开发版本

## 项目说明

本项目是基于 [3x-ui](https://github.com/MHSanaei/3x-ui) 项目的二次开发版本，项目名称为 `youngscoolplay`。

### 原项目信息
- **原项目名称**: 3x-ui
- **原项目版本**: 2.6.6
- **原项目仓库**: https://github.com/MHSanaei/3x-ui
- **原项目许可证**: 请参考原项目的 LICENSE 文件

### 二次开发信息
- **Fork项目名称**: youngscoolplay
- **Fork项目版本**: 1.0.0-fork
- **Fork项目仓库**: https://github.com/victoralwaysyoung/youngscoolplay.git
- **开发者**: victoralwaysyoung

## 主要修改

### 1. 项目标识修改
- 修改 `go.mod` 中的模块名称从 `x-ui` 改为 `youngscoolplay`
- 修改 `config/name` 文件中的项目名称
- 修改 `config/version` 文件中的版本号为 `1.0.0-fork`

### 2. 依赖关系处理
- 保持原有的 Go 模块依赖结构
- 确保所有 import 语句正确引用新的模块名称

### 3. 环境配置
- 支持原有的配置文件结构
- 兼容原有的环境变量配置

## 构建和运行

### 环境要求
- Go 1.24.5 或更高版本
- 支持的操作系统：Linux, Windows, macOS

### 构建项目
```bash
go mod tidy
go build -o youngscoolplay main.go
```

### 运行项目
```bash
./youngscoolplay
```

### 调试模式运行
```bash
go run -race main.go
```

## 开发说明

### 项目结构
项目保持了原有的目录结构：
- `config/` - 配置文件目录
- `database/` - 数据库相关代码
- `web/` - Web 服务相关代码
- `xray/` - Xray 核心功能
- `util/` - 工具函数
- `sub/` - 订阅相关功能

### 调试配置
项目支持 VS Code 调试，相关配置文件位于 `.vscode/launch.json`

### 注意事项
1. 本项目是基于原项目的二次开发，请遵守原项目的许可证条款
2. 在进行功能修改时，请确保不破坏原有的核心功能
3. 建议在独立的分支上进行开发，便于版本管理

## 许可证

本项目遵循原项目的许可证条款。详细信息请参考 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进本项目。

## 联系方式

- GitHub: [@victoralwaysyoung](https://github.com/victoralwaysyoung)
- 项目仓库: https://github.com/victoralwaysyoung/youngscoolplay.git