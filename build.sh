#!/bin/bash

# YoungsCoolPlay Build Script
# This script builds the application for multiple platforms

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_NAME="youngscoolplay"
VERSION=$(cat config/version 2>/dev/null || echo "1.0.0")
BUILD_DIR="build"
DIST_DIR="dist"

# Supported platforms
PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "linux/386"
    "windows/amd64"
    "windows/386"
    "darwin/amd64"
    "darwin/arm64"
)

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cleanup() {
    print_info "Cleaning up previous builds..."
    rm -rf "$BUILD_DIR" "$DIST_DIR"
    mkdir -p "$BUILD_DIR" "$DIST_DIR"
}

build_for_platform() {
    local platform=$1
    local os=$(echo $platform | cut -d'/' -f1)
    local arch=$(echo $platform | cut -d'/' -f2)
    
    print_info "Building for $os/$arch..."
    
    local output_name="$APP_NAME"
    if [[ "$os" == "windows" ]]; then
        output_name="${APP_NAME}.exe"
    fi
    
    local build_path="$BUILD_DIR/${APP_NAME}-${os}-${arch}"
    mkdir -p "$build_path"
    
    # Set environment variables for cross-compilation
    export GOOS=$os
    export GOARCH=$arch
    export CGO_ENABLED=0
    
    # Build the application
    go build -ldflags "-s -w -X main.version=$VERSION" -o "$build_path/$output_name" main.go
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to build for $os/$arch"
        return 1
    fi
    
    # Copy necessary files
    cp -r web "$build_path/"
    cp -r config "$build_path/"
    cp LICENSE "$build_path/"
    cp README.md "$build_path/"
    cp FORK_DEVELOPMENT_GUIDE.md "$build_path/"
    cp .env.example "$build_path/"
    
    # Copy install script for Linux
    if [[ "$os" == "linux" ]]; then
        cp install.sh "$build_path/"
        chmod +x "$build_path/install.sh"
    fi
    
    # Create bin directory with necessary files
    mkdir -p "$build_path/bin"
    if [[ -f "bin/geoip.dat" ]]; then
        cp bin/geoip.dat "$build_path/bin/"
    fi
    if [[ -f "bin/geosite.dat" ]]; then
        cp bin/geosite.dat "$build_path/bin/"
    fi
    if [[ -f "bin/LICENSE" ]]; then
        cp bin/LICENSE "$build_path/bin/"
    fi
    if [[ -f "bin/README.md" ]]; then
        cp bin/README.md "$build_path/bin/"
    fi
    
    # Create archive
    cd "$BUILD_DIR"
    local archive_name="${APP_NAME}-${os}-${arch}"
    
    if [[ "$os" == "windows" ]]; then
        zip -r "../$DIST_DIR/${archive_name}.zip" "${APP_NAME}-${os}-${arch}/"
    else
        tar -czf "../$DIST_DIR/${archive_name}.tar.gz" "${APP_NAME}-${os}-${arch}/"
    fi
    
    cd ..
    
    print_success "Built $archive_name"
}

generate_checksums() {
    print_info "Generating checksums..."
    
    cd "$DIST_DIR"
    
    # Generate SHA256 checksums
    if command -v sha256sum &> /dev/null; then
        sha256sum * > checksums.txt
    elif command -v shasum &> /dev/null; then
        shasum -a 256 * > checksums.txt
    else
        print_error "No checksum utility found"
        return 1
    fi
    
    cd ..
    
    print_success "Checksums generated"
}

main() {
    echo "========================================"
    echo "  YoungsCoolPlay Build Script"
    echo "  Version: $VERSION"
    echo "========================================"
    echo
    
    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        print_error "Go is not installed"
        exit 1
    fi
    
    print_info "Go version: $(go version)"
    
    cleanup
    
    # Build for all platforms
    for platform in "${PLATFORMS[@]}"; do
        build_for_platform "$platform"
    done
    
    generate_checksums
    
    print_success "All builds completed!"
    print_info "Build artifacts are in the '$DIST_DIR' directory"
    
    # Show build results
    echo
    echo "Build Results:"
    echo "=============="
    ls -la "$DIST_DIR"
}

main "$@"