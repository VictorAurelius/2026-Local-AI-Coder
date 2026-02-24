#!/bin/bash
# ============================================================================
# SSH Tunnel — Setup trên MÁY SERVER
# Chạy script này trên máy đang chạy Ollama (server)
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│    SSH Tunnel Setup — Server Side            │"
echo "└─────────────────────────────────────────────┘"
echo ""

# ---- 1. Kiểm tra SSH Server ----
log_info "Kiểm tra SSH server..."

if command -v sshd &> /dev/null || systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
    log_info "SSH server đang chạy ✓"
else
    log_warn "SSH server chưa chạy. Cài đặt..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y openssh-server
        sudo systemctl enable ssh && sudo systemctl start ssh
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y openssh-server
        sudo systemctl enable sshd && sudo systemctl start sshd
    elif command -v brew &> /dev/null; then
        echo "macOS: Bật Remote Login trong System Settings → General → Sharing"
        exit 1
    fi
    log_info "SSH server đã cài và khởi động ✓"
fi

# ---- 2. Tạo user riêng cho tunnel (tùy chọn) ----
read -p "Tạo user riêng cho SSH tunnel? (khuyến nghị cho bảo mật) [y/N]: " CREATE_USER

if [[ "$CREATE_USER" =~ ^[Yy]$ ]]; then
    TUNNEL_USER="ollama-tunnel"

    if id "$TUNNEL_USER" &>/dev/null; then
        log_info "User '$TUNNEL_USER' đã tồn tại."
    else
        sudo useradd -m -s /usr/sbin/nologin "$TUNNEL_USER"
        sudo mkdir -p /home/$TUNNEL_USER/.ssh
        sudo chmod 700 /home/$TUNNEL_USER/.ssh
        sudo touch /home/$TUNNEL_USER/.ssh/authorized_keys
        sudo chmod 600 /home/$TUNNEL_USER/.ssh/authorized_keys
        sudo chown -R $TUNNEL_USER:$TUNNEL_USER /home/$TUNNEL_USER/.ssh
        log_info "User '$TUNNEL_USER' đã tạo (no shell, chỉ dùng cho tunnel) ✓"
    fi

    echo ""
    echo -e "${YELLOW}Bước tiếp theo:${NC}"
    echo "  1. Trên MÁY CLIENT, chạy: ssh-keygen -t ed25519 -C 'ollama-tunnel'"
    echo "  2. Copy public key vào server:"
    echo "     ssh-copy-id $TUNNEL_USER@$(hostname -I | awk '{print $1}')"
    echo ""
    echo "  Hoặc dán public key vào file sau trên server:"
    echo "     /home/$TUNNEL_USER/.ssh/authorized_keys"
    echo ""
    echo "  (Tùy chọn) Giới hạn key chỉ được tunnel, thêm prefix vào authorized_keys:"
    echo '     no-agent-forwarding,no-X11-forwarding,permitopen="localhost:11434",command="/bin/false" ssh-ed25519 AAAA...'
else
    TUNNEL_USER=$(whoami)
    log_info "Sẽ dùng user hiện tại: $TUNNEL_USER"
fi

# ---- 3. Kiểm tra Ollama ----
log_info "Kiểm tra Ollama..."
if curl -sf http://localhost:11434/api/version > /dev/null 2>&1; then
    log_info "Ollama đang chạy tại localhost:11434 ✓"
else
    log_warn "Ollama chưa chạy. Khởi động containers..."
    docker compose up -d 2>/dev/null || log_warn "Chạy 'docker compose up -d' thủ công."
fi

# ---- 4. Hiển thị thông tin kết nối ----
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} ✅ SERVER SẴN SÀNG${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Server IP:   $SERVER_IP"
echo "  SSH User:    $TUNNEL_USER"
echo "  SSH Port:    22"
echo ""
echo "  Trên MÁY CLIENT, chạy:"
echo "    ssh -f -N -L 11434:localhost:11434 $TUNNEL_USER@$SERVER_IP"
echo ""
echo "  Sau đó dùng model:"
echo "    ollama run qwen3-coder:30b"
echo "    curl http://localhost:11434/v1/chat/completions ..."
echo ""
