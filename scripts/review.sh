#!/bin/bash
# ============================================================================
# review.sh — Gửi file code tới model để review
#
# Cách dùng:
#   ./scripts/review.sh path/to/File.java
#   ./scripts/review.sh path/to/File.java "Tập trung vào security issues"
#   ./scripts/review.sh src/main/java/com/example/service/   (cả folder)
# ============================================================================

set -e

OLLAMA_PORT="${OLLAMA_PORT:-11434}"
MODEL="${REVIEW_MODEL:-code-reviewer}"
MAX_TOKENS=65536

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [ $# -lt 1 ]; then
    echo "Cách dùng:"
    echo "  $0 <file-or-folder> [custom-prompt]"
    echo ""
    echo "Ví dụ:"
    echo "  $0 UserService.java"
    echo "  $0 src/main/java/com/example/service/"
    echo "  $0 OrderController.java \"Kiểm tra security và performance\""
    exit 1
fi

TARGET="$1"
CUSTOM_PROMPT="${2:-Review code này chi tiết. Tìm bugs, security issues, performance problems, và đề xuất cải thiện.}"

# Thu thập code
if [ -d "$TARGET" ]; then
    echo -e "${GREEN}[INFO]${NC} Đang đọc tất cả file Java trong: $TARGET"
    CODE=""
    while IFS= read -r -d '' file; do
        CODE+="
// ============ FILE: $file ============
$(cat "$file")
"
    done < <(find "$TARGET" -name "*.java" -print0)
elif [ -f "$TARGET" ]; then
    echo -e "${GREEN}[INFO]${NC} Đang đọc file: $TARGET"
    CODE="$(cat "$TARGET")"
else
    echo -e "${RED}[ERROR]${NC} Không tìm thấy: $TARGET"
    exit 1
fi

# Kiểm tra kích thước
CHAR_COUNT=${#CODE}
echo -e "${GREEN}[INFO]${NC} Tổng: $CHAR_COUNT ký tự (~$((CHAR_COUNT / 4)) tokens)"

if [ "$CHAR_COUNT" -gt 200000 ]; then
    echo -e "${RED}[WARN]${NC} Code quá dài (>200K chars). Nên chia nhỏ để review."
    exit 1
fi

# Gửi tới model
echo -e "${GREEN}[INFO]${NC} Gửi tới model '$MODEL'..."
echo ""

curl -sN "http://localhost:$OLLAMA_PORT/api/generate" \
    -d "$(jq -n \
        --arg model "$MODEL" \
        --arg prompt "$CUSTOM_PROMPT

\`\`\`java
$CODE
\`\`\`" \
        --argjson num_ctx "$MAX_TOKENS" \
        '{model: $model, prompt: $prompt, stream: true, options: {num_ctx: $num_ctx, temperature: 0.2}}'
    )" | while IFS= read -r line; do
    echo "$line" | jq -r '.response // empty' 2>/dev/null | tr -d '\n'
done

echo ""
echo ""
echo -e "${GREEN}[DONE]${NC} Review hoàn tất."
