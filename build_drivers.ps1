# PowerShell script to cross-compile DeepX drivers
$ErrorActionPreference = "Stop"

$projectPath = "C:\Users\dvir\CascadeProjects\imdt new patch"
$kernelPath = "$projectPath\kernel-src"
$driverPath = "$projectPath\dx_rt_npu_linux_driver"
$outputPath = "$projectPath\compiled_drivers"
$scriptPath = "$projectPath\compile_drivers.sh"

Write-Host "=== DeepX Driver Cross-Compilation ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project Path: $projectPath"
Write-Host "Kernel Source: $kernelPath"
Write-Host "Driver Source: $driverPath"
Write-Host "Output Path: $outputPath"
Write-Host ""

# Create output directory
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

# Convert Windows paths to WSL paths
$wslKernel = wsl wslpath -a "$kernelPath"
$wslDriver = wsl wslpath -a "$driverPath"
$wslOutput = wsl wslpath -a "$outputPath"
$wslScript = wsl wslpath -a "$scriptPath"

Write-Host "Running Docker container to build drivers..." -ForegroundColor Yellow
Write-Host ""

# Run Docker with proper path handling
wsl docker run --rm `
    -v "${wslKernel}:/kernel" `
    -v "${wslDriver}:/driver" `
    -v "${wslOutput}:/output" `
    -v "${wslScript}:/compile.sh" `
    deepx-driver-builder bash /compile.sh

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Build Complete ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Compiled drivers:"
    Get-ChildItem -Path $outputPath -Filter "*.ko" | ForEach-Object {
        Write-Host "  $($_.Name) - $([math]::Round($_.Length/1KB, 2)) KB"
    }
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Transfer drivers to board:"
    Write-Host "     scp '$outputPath\*.ko' root@192.168.0.165:/tmp/"
    Write-Host ""
    Write-Host "  2. Load drivers on board:"
    Write-Host "     ssh root@192.168.0.165 '/sbin/insmod /tmp/dx_dma.ko && /sbin/insmod /tmp/dxrt_driver.ko'"
} else {
    Write-Host ""
    Write-Host "Build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
