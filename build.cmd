@echo off
REM Windows build script for DeepX DX-M1 on iMDT V2H SBC
REM Run this on your Windows PC with Docker Desktop installed

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%build
set RELEASE_DIR=%SCRIPT_DIR%release

echo ================================================
echo  DeepX DX-M1 Build Script for iMDT V2H SBC
echo ================================================
echo.

REM Check Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed or not running.
    echo Please install Docker Desktop and try again.
    exit /b 1
)
echo [INFO] Docker found

REM Build Docker images
echo [INFO] Building Docker images...
docker build -t deepx-drivers-build -f docker\Dockerfile.drivers docker\
if errorlevel 1 (
    echo [ERROR] Failed to build drivers Docker image
    exit /b 1
)

docker build -t deepx-runtime-build -f docker\Dockerfile.runtime docker\
if errorlevel 1 (
    echo [ERROR] Failed to build runtime Docker image
    exit /b 1
)
echo [INFO] Docker images built successfully

REM Create build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

REM Clone sources
echo [INFO] Cloning source repositories...

if not exist "%BUILD_DIR%\kernel-src" (
    echo [INFO] Cloning Renesas kernel source...
    git clone --depth 1 https://github.com/imd-tec/renesas-rz-linux-cip.git "%BUILD_DIR%\kernel-src"
)

if not exist "%BUILD_DIR%\dx_rt_npu_linux_driver" (
    echo [INFO] Cloning DeepX driver...
    git clone --recurse-submodules https://github.com/DEEPX-AI/dx_rt_npu_linux_driver.git "%BUILD_DIR%\dx_rt_npu_linux_driver"
)

if not exist "%BUILD_DIR%\dx-all-suite" (
    echo [INFO] Cloning DeepX SDK...
    git clone --recurse-submodules https://github.com/DEEPX-AI/dx-all-suite.git "%BUILD_DIR%\dx-all-suite"
)

REM Build drivers
echo [INFO] Building DeepX drivers...
docker run --rm -v "%BUILD_DIR%:/build" deepx-drivers-build bash -c "set -e && cd /build/kernel-src && rm -rf .git && mkdir -p include/config && echo '5.10.145-cip17-yocto-standard' > include/config/kernel.release && make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig && make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules_prepare && cd /build/dx_rt_npu_linux_driver && make DEVICE=m1 PCIE=deepx ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KERNEL_DIR=/build/kernel-src && mkdir -p /build/output/drivers && cp modules/dxrt_driver.ko /build/output/drivers/ && cp modules/dx_dma.ko /build/output/drivers/ && cp utils/dx_dma/dx_dma.conf /build/output/drivers/"
if errorlevel 1 (
    echo [ERROR] Failed to build drivers
    exit /b 1
)
echo [INFO] Drivers built successfully

REM Disable ORT in runtime config
echo [INFO] Configuring runtime build...
powershell -Command "(Get-Content '%BUILD_DIR%\dx-all-suite\dx-runtime\dx_rt\cmake\dxrt.cfg.cmake') -replace 'option\(USE_ORT \"Use ONNX Runtime\" ON\)', 'option(USE_ORT \"Use ONNX Runtime\" OFF)' | Set-Content '%BUILD_DIR%\dx-all-suite\dx-runtime\dx_rt\cmake\dxrt.cfg.cmake'"

REM Build runtime
echo [INFO] Building DeepX runtime...
docker run --rm -v "%BUILD_DIR%:/build" deepx-runtime-build bash -c "set -e && cd /build/dx-all-suite/dx-runtime/dx_rt && find . -type f \( -name '*.sh' -o -name '*.cmake' -o -name 'CMakeLists.txt' \) -exec sed -i 's/\r$//' {} \; && rm -rf build_aarch64 && ./build.sh --arch aarch64 --type Release || true && mkdir -p /build/output/runtime && cp -r build_aarch64/bin /build/output/runtime/ && cp -r build_aarch64/lib /build/output/runtime/"
if errorlevel 1 (
    echo [ERROR] Failed to build runtime
    exit /b 1
)
echo [INFO] Runtime built successfully

REM Create release package
echo [INFO] Creating release package...
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"
if not exist "%RELEASE_DIR%\drivers" mkdir "%RELEASE_DIR%\drivers"
if not exist "%RELEASE_DIR%\runtime" mkdir "%RELEASE_DIR%\runtime"

xcopy /E /Y "%BUILD_DIR%\output\drivers\*" "%RELEASE_DIR%\drivers\"
xcopy /E /Y "%BUILD_DIR%\output\runtime\*" "%RELEASE_DIR%\runtime\"
copy /Y "%SCRIPT_DIR%board\install.sh" "%RELEASE_DIR%\"

REM Create tarball using Docker
docker run --rm -v "%RELEASE_DIR%:/release" deepx-drivers-build bash -c "cd /release && tar czf /release/deepx-release.tar.gz drivers runtime install.sh"
move "%RELEASE_DIR%\deepx-release.tar.gz" "%SCRIPT_DIR%"

echo.
echo ================================================
echo  Build completed successfully!
echo ================================================
echo.
echo Release package: %SCRIPT_DIR%deepx-release.tar.gz
echo.
echo To deploy to your board:
echo   1. Transfer deepx-release.tar.gz to the board
echo   2. Extract: tar xzf deepx-release.tar.gz
echo   3. Run: ./install.sh
echo.

endlocal
