# YoungsCoolPlay Build Script for Windows
# This script builds the project for multiple platforms and creates release packages

param(
    [string]$Version = "2.6.6"
)

$ErrorActionPreference = "Stop"

Write-Host "Building YoungsCoolPlay v$Version..." -ForegroundColor Green

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
if (Test-Path "dist") {
    Remove-Item -Recurse -Force "dist"
}
New-Item -ItemType Directory -Path "dist" -Force | Out-Null

# Set Go environment
$env:GOROOT = ""
$env:GOPROXY = "https://goproxy.cn,direct"
$env:GO111MODULE = "on"

# Build targets
$targets = @(
    @{OS="linux"; ARCH="amd64"; EXT=""},
    @{OS="linux"; ARCH="arm64"; EXT=""},
    @{OS="windows"; ARCH="amd64"; EXT=".exe"},
    @{OS="darwin"; ARCH="amd64"; EXT=""},
    @{OS="darwin"; ARCH="arm64"; EXT=""}
)

foreach ($target in $targets) {
    $outputName = "youngscoolplay-$($target.OS)-$($target.ARCH)$($target.EXT)"
    $packageName = "youngscoolplay-$($target.OS)-$($target.ARCH)"
    
    Write-Host "Building $outputName..." -ForegroundColor Cyan
    
    $env:GOOS = $target.OS
    $env:GOARCH = $target.ARCH
    
    # Build the binary
    go build -ldflags "-s -w -X main.version=$Version" -o "dist\$outputName" main.go
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build $outputName"
        exit 1
    }
    
    # Create package directory
    $packageDir = "dist\$packageName"
    New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
    
    # Copy binary (check if it exists first)
    if (Test-Path "dist\$outputName") {
        Copy-Item "dist\$outputName" "$packageDir\youngscoolplay$($target.EXT)"
    } else {
        Write-Error "Binary dist\$outputName was not created"
        exit 1
    }
    
    # Copy web assets
    if (Test-Path "web") {
        Copy-Item -Recurse "web" "$packageDir\"
    }
    
    # Copy config
    if (Test-Path "config") {
        Copy-Item -Recurse "config" "$packageDir\"
    }
    
    # Copy license and readme
    if (Test-Path "LICENSE") {
        Copy-Item "LICENSE" "$packageDir\"
    }
    if (Test-Path "README.md") {
        Copy-Item "README.md" "$packageDir\"
    }
    
    # Copy env example
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" "$packageDir\"
    }
    
    # Copy install script for Linux
    if ($target.OS -eq "linux" -and (Test-Path "install.sh")) {
        Copy-Item "install.sh" "$packageDir\"
    }
    
    # Copy geo files
    if (Test-Path "bin\geoip.dat") {
        if (-not (Test-Path "$packageDir\bin")) {
            New-Item -ItemType Directory -Path "$packageDir\bin" -Force | Out-Null
        }
        Copy-Item "bin\geoip.dat" "$packageDir\bin\"
        Copy-Item "bin\geosite.dat" "$packageDir\bin\"
    }
    
    # Create archive
    if ($target.OS -eq "windows") {
        $archiveName = "$packageName.zip"
        Compress-Archive -Path "$packageDir\*" -DestinationPath "dist\$archiveName" -Force
    } else {
        $archiveName = "$packageName.tar.gz"
        # Use tar if available, otherwise use PowerShell compression
        try {
            tar -czf "dist\$archiveName" -C "dist" $packageName
        } catch {
            # Fallback to zip for non-Windows platforms
            Compress-Archive -Path "$packageDir\*" -DestinationPath "dist\$packageName.zip" -Force
        }
    }
    
    # Generate checksum
    $hash = Get-FileHash "dist\$archiveName" -Algorithm SHA256
    "$($hash.Hash.ToLower())  $archiveName" | Out-File -Append "dist\checksums.txt" -Encoding UTF8
    
    Write-Host "✓ Created $archiveName" -ForegroundColor Green
    
    # Clean up package directory
    Remove-Item -Recurse -Force $packageDir
}

Write-Host "`nBuild completed successfully!" -ForegroundColor Green
Write-Host "Release packages are in the 'dist' directory" -ForegroundColor Yellow
Write-Host "Checksums are in 'dist\checksums.txt'" -ForegroundColor Yellow