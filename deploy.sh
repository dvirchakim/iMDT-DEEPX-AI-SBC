#!/bin/bash
#
# Deploy DeepX release to iMDT V2H SBC
# Usage: ./deploy.sh <board-ip> [username]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_FILE="$SCRIPT_DIR/deepx-release.tar.gz"

BOARD_IP="${1:-}"
BOARD_USER="${2:-root}"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ -z "$BOARD_IP" ]; then
    echo "Usage: $0 <board-ip> [username]"
    echo ""
    echo "Examples:"
    echo "  $0 192.168.1.100"
    echo "  $0 10.11.12.31 root"
    exit 1
fi

if [ ! -f "$RELEASE_FILE" ]; then
    log_error "Release file not found: $RELEASE_FILE"
    log_error "Run ./build.sh first to create the release package"
    exit 1
fi

log_info "Deploying to $BOARD_USER@$BOARD_IP..."

# Transfer release package
log_info "Transferring release package..."
scp -o StrictHostKeyChecking=no "$RELEASE_FILE" "$BOARD_USER@$BOARD_IP:/tmp/"

# Extract and install
log_info "Installing on board..."
ssh -o StrictHostKeyChecking=no "$BOARD_USER@$BOARD_IP" << 'EOF'
cd /tmp
rm -rf deepx-release
mkdir -p deepx-release
tar xzf deepx-release.tar.gz -C deepx-release
cd deepx-release
chmod +x install.sh
./install.sh
EOF

log_info "Deployment completed!"
