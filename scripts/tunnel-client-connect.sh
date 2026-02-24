#!/bin/bash
# ============================================================================
# SSH Tunnel — Setup và kết nối từ MÁY CLIENT
# Chạy script này trên máy muốn sử dụng model (client)
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ---- Load config ----
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

SERVER_USER="${SSH_SERVER_USER:-user}"
SERVER_IP="${SSH_SERVER_IP:-192.168.1.100}"
SERVER_PORT="${SSH_SERVER_PORT:-22}"
SSH_KEY="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"
LOCAL_PORT="${OLLAMA_PORT:-11434}"

echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│    SSH Tunnel — Client Connection            │"
echo "└─────────────────────────────────────────────┘"
echo ""
echo "  Server: $SERVER_USER@$SERVER_IP:$SERVER_PORT"
echo "  Local:  localhost:$LOCAL_PORT"
echo ""

# ---- Kiểm tra tunnel đã chạy chưa ----
if lsof -i ":$LOCAL_PORT" > /dev/null 2>&1; then
    EXISTING_PID=$(lsof -t -i ":$LOCAL_PORT" | head -1)
    log_info "Port $LOCAL_PORT đã được sử dụng (PID: $EXISTING_PID)."

    # Test kết nối
    if curl -sf "http://localhost:$LOCAL_PORT/api/version" > /dev/null 2>&1; then
        log_info "Tunnel đang hoạt động tốt ✓"
        echo ""
        echo "  Sử dụng: ollama run qwen3-coder:30b"
        echo "  API:     http://localhost:$LOCAL_PORT/v1/chat/completions"
        exit 0
    else
        log_error "Port đang bị chiếm nhưng không phải Ollama tunnel."
        echo "  Kiểm tra: lsof -i :$LOCAL_PORT"
        echo "  Dừng process: kill $EXISTING_PID"
        exit 1
    fi
fi

# ---- Tạo SSH key nếu chưa có ----
if [ ! -f "$SSH_KEY" ]; then
    log_info "Tạo SSH key..."
    ssh-keygen -t ed25519 -C "ollama-tunnel-client" -f "$SSH_KEY" -N ""
    echo ""
    echo -e "${YELLOW}Copy public key sang server:${NC}"
    echo "  ssh-copy-id -i $SSH_KEY.pub -p $SERVER_PORT $SERVER_USER@$SERVER_IP"
    echo ""
    read -p "Đã copy key xong? Nhấn Enter để tiếp tục..."
fi

# ---- Kết nối tunnel ----
log_info "Đang kết nối SSH tunnel..."

ssh -f -N \
    -L "$LOCAL_PORT:localhost:11434" \
    -p "$SERVER_PORT" \
    -i "$SSH_KEY" \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=accept-new \
    "$SERVER_USER@$SERVER_IP"

# ---- Kiểm tra kết nối ----
sleep 2
if curl -sf "http://localhost:$LOCAL_PORT/api/version" > /dev/null 2>&1; then
    VERSION=$(curl -sf "http://localhost:$LOCAL_PORT/api/version" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    log_info "Kết nối thành công! Ollama v$VERSION ✓"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Chat:   ollama run qwen3-coder:30b"
    echo "  API:    http://localhost:$LOCAL_PORT/v1/chat/completions"
    echo "  WebUI:  (chỉ khả dụng trên server hoặc qua tunnel port 3000)"
    echo ""
    echo "  Ngắt tunnel:  kill \$(lsof -t -i :$LOCAL_PORT)"
    echo ""
else
    log_error "Tunnel đã tạo nhưng không kết nối được tới Ollama."
    echo "  Kiểm tra Ollama trên server đang chạy."
    echo "  Debug: ssh -v -N -L $LOCAL_PORT:localhost:11434 -p $SERVER_PORT $SERVER_USER@$SERVER_IP"
fi
