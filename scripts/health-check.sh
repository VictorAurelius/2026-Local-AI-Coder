#!/bin/bash
# ============================================================================
# Health Check — Kiểm tra trạng thái hệ thống
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

OLLAMA_PORT="${OLLAMA_PORT:-11434}"
WEBUI_PORT="${WEBUI_PORT:-3000}"

echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│         Local AI Coder — Health Check        │"
echo "└─────────────────────────────────────────────┘"
echo ""

# Docker containers
echo "▸ Docker Containers:"
for svc in ollama open-webui; do
    STATUS=$(docker inspect -f '{{.State.Status}}' "$svc" 2>/dev/null || echo "not found")
    if [ "$STATUS" = "running" ]; then
        echo -e "  $svc: ${GREEN}running${NC} ✓"
    else
        echo -e "  $svc: ${RED}$STATUS${NC} ✗"
    fi
done

echo ""

# Ollama API
echo "▸ Ollama API (port $OLLAMA_PORT):"
if curl -sf "http://localhost:$OLLAMA_PORT/api/version" > /dev/null 2>&1; then
    VERSION=$(curl -sf "http://localhost:$OLLAMA_PORT/api/version" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    echo -e "  Status: ${GREEN}online${NC} (v$VERSION) ✓"
else
    echo -e "  Status: ${RED}offline${NC} ✗"
fi

echo ""

# Loaded models
echo "▸ Models đã tải:"
docker exec ollama ollama list 2>/dev/null | tail -n +2 | while read line; do
    echo "  $line"
done

echo ""

# Running models
echo "▸ Models đang chạy (trong RAM):"
RUNNING=$(docker exec ollama ollama ps 2>/dev/null | tail -n +2)
if [ -z "$RUNNING" ]; then
    echo "  (Không có model nào đang chạy)"
else
    echo "$RUNNING" | while read line; do
        echo "  $line"
    done
fi

echo ""

# Open WebUI
echo "▸ Open WebUI (port $WEBUI_PORT):"
if curl -sf "http://localhost:$WEBUI_PORT" > /dev/null 2>&1; then
    echo -e "  Status: ${GREEN}online${NC} ✓"
    echo "  URL: http://localhost:$WEBUI_PORT"
else
    echo -e "  Status: ${RED}offline${NC} ✗"
fi

echo ""

# System resources
echo "▸ Tài nguyên hệ thống:"
if command -v free &> /dev/null; then
    USED=$(free -g | awk '/Mem:/ {print $3}')
    TOTAL=$(free -g | awk '/Mem:/ {print $2}')
    AVAILABLE=$(free -g | awk '/Mem:/ {print $7}')
    echo "  RAM: ${USED}GB / ${TOTAL}GB (còn ${AVAILABLE}GB khả dụng)"
fi

DISK_USED=$(docker system df --format '{{.Size}}' 2>/dev/null | head -1)
echo "  Docker disk: $DISK_USED"

echo ""
