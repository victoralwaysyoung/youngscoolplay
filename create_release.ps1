# YoungsCoolPlay Release Package Creator
# Creates a release package for Linux deployment

param(
    [string]$Version = "2.6.6"
)

$ErrorActionPreference = "Stop"

Write-Host "Creating YoungsCoolPlay v$Version release package..." -ForegroundColor Green

# Clean and create release directory
if (Test-Path "release") {
    Remove-Item -Recurse -Force "release"
}
New-Item -ItemType Directory -Path "release" -Force | Out-Null

# Build Linux binary
Write-Host "Building Linux binary..." -ForegroundColor Cyan
$env:GOOS = "linux"
$env:GOARCH = "amd64"
$env:GOROOT = ""
$env:GOPROXY = "https://goproxy.cn,direct"

go build -ldflags "-s -w -X main.version=$Version" -o "release\youngscoolplay" main.go

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build Linux binary"
    exit 1
}

# Copy necessary files
Write-Host "Copying project files..." -ForegroundColor Cyan

# Copy web assets
if (Test-Path "web") {
    Copy-Item -Recurse "web" "release\"
}

# Copy config
if (Test-Path "config") {
    Copy-Item -Recurse "config" "release\"
}

# Copy documentation
if (Test-Path "LICENSE") {
    Copy-Item "LICENSE" "release\"
}
if (Test-Path "README.md") {
    Copy-Item "README.md" "release\"
}
if (Test-Path ".env.example") {
    Copy-Item ".env.example" "release\"
}

# Copy install script
if (Test-Path "install.sh") {
    Copy-Item "install.sh" "release\"
}

# Copy geo files
if (Test-Path "bin\geoip.dat") {
    New-Item -ItemType Directory -Path "release\bin" -Force | Out-Null
    Copy-Item "bin\geoip.dat" "release\bin\"
    Copy-Item "bin\geosite.dat" "release\bin\"
    if (Test-Path "bin\LICENSE") {
        Copy-Item "bin\LICENSE" "release\bin\"
    }
    if (Test-Path "bin\README.md") {
        Copy-Item "bin\README.md" "release\bin\"
    }
}

# Create tar.gz archive
Write-Host "Creating release archive..." -ForegroundColor Cyan
$archiveName = "youngscoolplay-linux-amd64-v$Version.tar.gz"

# Use tar if available
try {
    tar -czf $archiveName -C release .
    Write-Host "✓ Created $archiveName using tar" -ForegroundColor Green
} catch {
    # Fallback to zip
    $zipName = "youngscoolplay-linux-amd64-v$Version.zip"
    Compress-Archive -Path "release\*" -DestinationPath $zipName -Force
    Write-Host "✓ Created $zipName (fallback)" -ForegroundColor Green
    $archiveName = $zipName
}

# Generate checksum
$hash = Get-FileHash $archiveName -Algorithm SHA256
"$($hash.Hash.ToLower())  $archiveName" | Out-File "checksums.txt" -Encoding UTF8

Write-Host "`nRelease package created successfully!" -ForegroundColor Green
Write-Host "Archive: $archiveName" -ForegroundColor Yellow
Write-Host "Checksum: checksums.txt" -ForegroundColor Yellow
Write-Host "`nTo test the install script:" -ForegroundColor Cyan
Write-Host "bash <(curl -Ls https://raw.githubusercontent.com/victoralwaysyoung/youngscoolplay/master/install.sh)" -ForegroundColor White