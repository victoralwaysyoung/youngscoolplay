# YoungsCoolPlay

A modern web-based proxy management panel forked from 3x-ui, redesigned for enhanced performance and user experience.

## Features

- **Modern Web Interface**: Clean and intuitive web-based management panel
- **Multi-Protocol Support**: Support for VLESS, VMess, Trojan, Shadowsocks, and more
- **Traffic Statistics**: Real-time traffic monitoring and statistics
- **User Management**: Easy client management with QR code generation
- **Telegram Bot**: Optional Telegram bot integration for remote management
- **Multi-Language**: Support for multiple languages
- **Database Management**: Built-in database management tools
- **Security**: Enhanced security features and access controls

## Quick Installation

### Method 1: One-Click Installation Script

For Ubuntu 24.04+ servers:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay/main/install.sh)
```

### Method 2: Manual Installation

1. Download the latest release:
```bash
wget https://github.com/victoralwaysyoung/youngscoolplay/releases/latest/download/youngscoolplay-linux-amd64.tar.gz
```

2. Extract and install:
```bash
tar -xzf youngscoolplay-linux-amd64.tar.gz
cd youngscoolplay
sudo ./install.sh
```

## Development

### Prerequisites

- Go 1.21 or higher
- Node.js (for frontend development)
- Git

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/victoralwaysyoung/youngscoolplay.git
cd youngscoolplay
```

2. Build the project:
```bash
go build -o youngscoolplay main.go
```

3. Run the application:
```bash
./youngscoolplay run
```

### Development Environment

For development setup, see [FORK_DEVELOPMENT_GUIDE.md](FORK_DEVELOPMENT_GUIDE.md) for detailed instructions.

## Configuration

The application uses the following default settings:
- **Port**: 2053
- **Username**: admin
- **Password**: admin
- **Web Path**: /

You can modify these settings through the web interface or configuration files.

## Usage

1. Access the web panel at `http://your-server-ip:2053`
2. Login with default credentials (admin/admin)
3. Change the default password immediately
4. Configure your proxy settings through the web interface

## API Documentation

The application provides RESTful APIs for automation and integration. API documentation is available at `/api/docs` when the service is running.

## Contributing

We welcome contributions! Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Original 3x-ui project and contributors
- XTLS/Xray-core project
- All open source libraries used in this project

## Support

- **Issues**: Report bugs and feature requests on [GitHub Issues](https://github.com/victoralwaysyoung/youngscoolplay/issues)
- **Discussions**: Join community discussions on [GitHub Discussions](https://github.com/victoralwaysyoung/youngscoolplay/discussions)

## Disclaimer

This tool is for educational and research purposes only. Users are responsible for complying with local laws and regulations.
