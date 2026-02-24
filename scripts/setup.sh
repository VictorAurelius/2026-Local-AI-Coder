#!/bin/bash
# ============================================================================
# Local AI Coder — Setup Script
# Cài đặt và khởi chạy toàn bộ hệ thống
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "\n${BLUE}━━━ $1 ━━━${NC}\n"; }

# ---- Load .env ----
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    log_warn "File .env chưa tồn tại. Tạo từ .env.example..."
    cp .env.example .env
    log_info "Đã tạo .env — hãy chỉnh sửa nếu cần rồi chạy lại script."
fi

MODEL_NAME="${MODEL_NAME:-qwen3-coder:30b}"
MODEL_CUSTOM_NAME="${MODEL_CUSTOM_NAME:-java-expert}"

# ============================================================================
# Bước 1: Kiểm tra yêu cầu hệ thống
# ============================================================================
log_step "Bước 1/5: Kiểm tra hệ thống"

# Kiểm tra Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker chưa được cài đặt."
    echo "  Cài Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
log_info "Docker: $(docker --version)"

# Kiểm tra Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    log_error "Docker Compose chưa được cài đặt."
    exit 1
fi
log_info "Docker Compose: $($COMPOSE_CMD version)"

# Kiểm tra RAM
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1024)}')
TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))

if [ "$TOTAL_RAM_GB" -lt 28 ]; then
    log_warn "RAM: ${TOTAL_RAM_GB}GB — Khuyến nghị tối thiểu 32GB."
    log_warn "Model có thể chạy chậm hoặc bị OOM."
else
    log_info "RAM: ${TOTAL_RAM_GB}GB ✓"
fi

# Kiểm tra dung lượng ổ đĩa
AVAILABLE_DISK=$(df -BG . | tail -1 | awk '{print $4}' | tr -d 'G')
if [ "$AVAILABLE_DISK" -lt 25 ]; then
    log_error "Ổ đĩa còn ${AVAILABLE_DISK}GB — cần tối thiểu 25GB."
    exit 1
fi
log_info "Ổ đĩa trống: ${AVAILABLE_DISK}GB ✓"

# ============================================================================
# Bước 2: Khởi động Docker containers
# ============================================================================
log_step "Bước 2/5: Khởi động containers"

$COMPOSE_CMD up -d
log_info "Containers đã khởi động."

# Chờ Ollama sẵn sàng
log_info "Đợi Ollama khởi động..."
for i in $(seq 1 30); do
    if curl -sf http://localhost:${OLLAMA_PORT:-11434}/api/version > /dev/null 2>&1; then
        log_info "Ollama đã sẵn sàng ✓"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "Ollama không khởi động được sau 30 giây."
        echo "  Kiểm tra logs: $COMPOSE_CMD logs ollama"
        exit 1
    fi
    sleep 1
done

# ============================================================================
# Bước 3: Tải model
# ============================================================================
log_step "Bước 3/5: Tải model ${MODEL_NAME}"

log_info "Đang tải model (có thể mất 10-30 phút tùy tốc độ mạng)..."
docker exec ollama ollama pull "$MODEL_NAME"
log_info "Model ${MODEL_NAME} đã tải xong ✓"

# ============================================================================
# Bước 4: Tạo custom modelfiles
# ============================================================================
log_step "Bước 4/5: Tạo custom model personas"

# Tạo Java Expert
if [ -f modelfiles/JavaExpert.modelfile ]; then
    docker exec ollama ollama create java-expert -f /modelfiles/JavaExpert.modelfile
    log_info "Model 'java-expert' đã tạo ✓"
fi

# Tạo Code Reviewer
if [ -f modelfiles/CodeReviewer.modelfile ]; then
    docker exec ollama ollama create code-reviewer -f /modelfiles/CodeReviewer.modelfile
    log_info "Model 'code-reviewer' đã tạo ✓"
fi

# ============================================================================
# Bước 5: Kiểm tra
# ============================================================================
log_step "Bước 5/5: Kiểm tra hệ thống"

# Test Ollama API
OLLAMA_VERSION=$(curl -sf http://localhost:${OLLAMA_PORT:-11434}/api/version | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
log_info "Ollama API: http://localhost:${OLLAMA_PORT:-11434} (v${OLLAMA_VERSION}) ✓"

# Test Open WebUI
sleep 3
if curl -sf http://localhost:${WEBUI_PORT:-3000} > /dev/null 2>&1; then
    log_info "Open WebUI: http://localhost:${WEBUI_PORT:-3000} ✓"
else
    log_warn "Open WebUI đang khởi động... thử lại sau vài giây."
fi

# Liệt kê models
log_info "Models đã cài:"
docker exec ollama ollama list

# ============================================================================
# Hoàn thành
# ============================================================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} ✅ CÀI ĐẶT HOÀN TẤT${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Sử dụng:"
echo ""
echo "    Chat terminal:    docker exec -it ollama ollama run qwen3-coder:30b"
echo "    Java Expert:      docker exec -it ollama ollama run java-expert"
echo "    Code Reviewer:    docker exec -it ollama ollama run code-reviewer"
echo "    Web UI:           http://localhost:${WEBUI_PORT:-3000}"
echo "    API endpoint:     http://localhost:${OLLAMA_PORT:-11434}/v1/chat/completions"
echo ""
echo "  Quản lý:"
echo ""
echo "    Dừng:             $COMPOSE_CMD down"
echo "    Khởi động lại:    $COMPOSE_CMD up -d"
echo "    Xem logs:         $COMPOSE_CMD logs -f"
echo "    Health check:     ./scripts/health-check.sh"
echo ""
echo -e "  ${YELLOW}⚠️  Mọi dữ liệu hoàn toàn local. Không gì được gửi ra internet.${NC}"
echo ""
