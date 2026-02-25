# PowerShell script to build latest DeepX runtime for ARM64
$ErrorActionPreference = "Stop"

$projectPath = "C:\Users\dvir\CascadeProjects\imdt new patch"
$runtimeSrc = "$projectPath\dx-all-suite-latest\dx-runtime"
$kernelPath = "$projectPath\kernel-src"
$outputPath = "$projectPath\dxrt-latest-arm64"
$scriptPath = "$projectPath\build_latest_runtime.sh"

Write-Host "=== DeepX Latest Runtime Build for ARM64 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Runtime Source: $runtimeSrc"
Write-Host "Kernel Source: $kernelPath"
Write-Host "Output Path: $outputPath"
Write-Host ""

# Create output directory
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

# Build Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
wsl docker build -t dxrt-builder -f Dockerfile.dxrt-builder .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed!" -ForegroundColor Red
    exit 1
}

# Convert Windows paths to WSL paths
$wslRuntime = wsl wslpath -a "$runtimeSrc"
$wslKernel = wsl wslpath -a "$kernelPath"
$wslOutput = wsl wslpath -a "$outputPath"
$wslScript = wsl wslpath -a "$scriptPath"

Write-Host ""
Write-Host "Running Docker container to build runtime..." -ForegroundColor Yellow
Write-Host ""

# Run Docker with proper path handling
wsl docker run --rm `
    -v "${wslRuntime}:/build/dx-runtime" `
    -v "${wslKernel}:/kernel" `
    -v "${wslOutput}:/output" `
    -v "${wslScript}:/build.sh" `
    dxrt-builder bash /build.sh

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Build Complete ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Output location: $outputPath"
    Write-Host ""
    
    # Show what was built
    if (Test-Path "$outputPath\bin") {
        Write-Host "Binaries:" -ForegroundColor Cyan
        Get-ChildItem -Path "$outputPath\bin" | Select-Object -First 10 | ForEach-Object {
            Write-Host "  $($_.Name) - $([math]::Round($_.Length/1KB, 2)) KB"
        }
    }
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Package and transfer to board:"
    Write-Host "     tar czf dxrt-latest.tar.gz -C '$outputPath' ."
    Write-Host "     scp dxrt-latest.tar.gz root@192.168.0.165:/tmp/"
    Write-Host ""
    Write-Host "  2. Install on board and update firmware"
} else {
    Write-Host ""
    Write-Host "Build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
