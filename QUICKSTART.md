# 🚀 Hướng Dẫn Sử Dụng Nhanh — Local AI Coder

> Hệ thống AI hỗ trợ lập trình chạy hoàn toàn local với Qwen3-Coder 30B

## 📋 Thông Tin Hệ Thống

| Thành phần | Thông tin |
|------------|-----------|
| Model | Qwen3-Coder 30B (A3B) - 30.5B params, 3.3B active |
| Context Window | 256K tokens (~6,000 dòng code) |
| Ollama API | http://localhost:11434 |
| Open WebUI | http://localhost:3000 |
| Docker Containers | `ollama`, `open-webui` |

---

## 🎯 Cách Sử Dụng

### 1. Chat qua Terminal

```bash
# Model gốc
docker exec -it ollama ollama run qwen3-coder:30b

# Java Expert persona
docker exec -it ollama ollama run java-expert

# Code Reviewer persona
docker exec -it ollama ollama run code-reviewer
```

**Ví dụ prompt:**
```
>>> Viết Spring Boot 3 REST controller CRUD cho entity Product,
    sử dụng JPA, Jakarta Validation, ResponseEntity,
    và custom exception handling
```

Thoát: `/bye` hoặc `Ctrl + D`

---

### 2. Chat qua Web UI

1. Mở trình duyệt: **http://localhost:3000**
2. Tạo tài khoản admin (lần đầu, chỉ lưu local)
3. Chọn model từ dropdown
4. Bắt đầu chat hoặc kéo thả file để upload

---

### 3. Review Code

**Review 1 file:**
```bash
./scripts/review.sh src/main/java/com/example/UserService.java
```

**Review cả folder:**
```bash
./scripts/review.sh src/main/java/com/example/service/
```

**Review với prompt tùy chỉnh:**
```bash
./scripts/review.sh OrderController.java "Tập trung vào security và SQL injection"
```

**Pipe trực tiếp:**
```bash
# 1 file
cat UserService.java | docker exec -i ollama ollama run code-reviewer "Review code này"

# Nhiều file
cat src/main/java/com/example/service/*.java | \
  docker exec -i ollama ollama run code-reviewer "Phân tích toàn bộ service layer"

# Cả project
find src -name "*.java" -exec cat {} + | \
  docker exec -i ollama ollama run code-reviewer "Đánh giá kiến trúc project"
```

---

### 4. Tích Hợp IDE

#### VS Code - Continue.dev

1. **Cài extension**: Search "Continue" trong VS Code Extensions
2. **Config**: Chỉnh `~/.continue/config.json`

```json
{
  "models": [
    {
      "title": "Qwen3-Coder 30B",
      "provider": "ollama",
      "model": "qwen3-coder:30b",
      "apiBase": "http://localhost:11434",
      "contextLength": 65536
    }
  ],
  "tabAutocompleteModel": {
    "title": "Qwen3-Coder Autocomplete",
    "provider": "ollama",
    "model": "qwen3-coder:30b",
    "contextLength": 4096
  }
}
```

**Phím tắt:**
- `Ctrl + L` - Mở chat panel
- `Ctrl + I` - Inline edit tại chỗ
- `Ctrl + Shift + L` - Gửi code đang chọn vào chat
- `Tab` - Chấp nhận autocomplete

#### IntelliJ IDEA - CodeGPT

1. `Settings` → `Plugins` → Search "CodeGPT" → Install
2. `Settings` → `Tools` → `CodeGPT`:
   - Provider: `Ollama`
   - Model: `qwen3-coder:30b`
   - URL: `http://localhost:11434`
3. Highlight code → Right click → **CodeGPT** → Explain / Review / Refactor / Test

---

### 5. API Integration

#### cURL

```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-coder:30b",
    "messages": [
      {"role": "system", "content": "Bạn là Senior Java Developer."},
      {"role": "user", "content": "Viết custom exception handler cho Spring Boot"}
    ],
    "temperature": 0.3
  }'
```

#### Python

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="not-needed"
)

response = client.chat.completions.create(
    model="qwen3-coder:30b",
    messages=[
        {"role": "system", "content": "Bạn là Java expert."},
        {"role": "user", "content": "Viết DTO validation với Jakarta Validation"}
    ],
    temperature=0.3
)

print(response.choices[0].message.content)
```

#### Java (OkHttp)

```java
import okhttp3.*;
import com.google.gson.*;

OkHttpClient client = new OkHttpClient.Builder()
    .readTimeout(120, TimeUnit.SECONDS)
    .build();

JsonObject body = new JsonObject();
body.addProperty("model", "qwen3-coder:30b");

JsonArray messages = new JsonArray();
JsonObject sysMsg = new JsonObject();
sysMsg.addProperty("role", "system");
sysMsg.addProperty("content", "Bạn là Java expert.");
messages.add(sysMsg);

JsonObject userMsg = new JsonObject();
userMsg.addProperty("role", "user");
userMsg.addProperty("content", "Viết Spring Boot REST controller");
messages.add(userMsg);

body.add("messages", messages);
body.addProperty("temperature", 0.3);

Request request = new Request.Builder()
    .url("http://localhost:11434/v1/chat/completions")
    .post(RequestBody.create(body.toString(),
          MediaType.parse("application/json")))
    .build();

Response response = client.newCall(request).execute();
System.out.println(response.body().string());
```

---

## 🔧 Quản Lý Hệ Thống

### Docker Commands

```bash
# Khởi động
docker compose up -d

# Dừng (giữ data)
docker compose down

# Dừng + xóa data (reset hoàn toàn)
docker compose down -v

# Restart
docker compose restart

# Xem logs
docker compose logs -f              # Tất cả
docker compose logs -f ollama       # Chỉ Ollama
docker compose logs -f open-webui   # Chỉ WebUI

# Health check
./scripts/health-check.sh
```

### Ollama Commands

```bash
# Liệt kê models
docker exec ollama ollama list

# Xem model đang chạy
docker exec ollama ollama ps

# Dừng model (giải phóng RAM)
docker exec ollama ollama stop qwen3-coder:30b

# Xóa model
docker exec ollama ollama rm <model-name>

# Tải thêm model
docker exec ollama ollama pull <model-name>
```

### Backup và Restore

```bash
# Backup model data (Docker volume)
docker run --rm -v ollama-data:/data -v $(pwd)/backup:/backup \
  alpine tar czf /backup/ollama-backup.tar.gz -C /data .

# Restore
docker run --rm -v ollama-data:/data -v $(pwd)/backup:/backup \
  alpine tar xzf /backup/ollama-backup.tar.gz -C /data
```

---

## ⚡ Hiệu Năng

### RAM Usage (32GB Total)

| Thành phần | RAM |
|------------|-----|
| OS | ~4 GB |
| Ollama + Model (Q4) | ~18-20 GB |
| Context window (32K) | ~2 GB |
| Open WebUI | ~0.5 GB |
| **Tổng** | **~25 GB** |
| **Còn lại** | **~7 GB** |

### Tốc Độ Dự Kiến

- **CPU Only (i5-14400)**: 12-15 tokens/s
- **Context 32K**: Đọc được ~800-1,000 dòng code
- **Context 65K** (Code Reviewer): Đọc được ~1,600-2,000 dòng code

### Điều Chỉnh Context

Trong Modelfile hoặc khi gọi API:

```bash
# 8K - chat ngắn, generate code nhỏ
PARAMETER num_ctx 8192

# 32K - review 1-2 file (mặc định)
PARAMETER num_ctx 32768

# 65K - phân tích cả package
PARAMETER num_ctx 65536
```

---

## 🐛 Xử Lý Lỗi

### Container không khởi động

```bash
docker compose logs ollama
docker compose logs open-webui
```

### Ollama OOM (Out of Memory)

```bash
# Giảm context trong Modelfile
PARAMETER num_ctx 8192

# Hoặc dùng bản quantize nhẹ hơn
docker exec ollama ollama pull qwen3-coder:30b-a3b-q3_K_M
```

### Tốc độ chậm (< 5 tok/s)

```bash
# Kiểm tra CPU hỗ trợ AVX2
grep -o 'avx2' /proc/cpuinfo | head -1

# Kiểm tra RAM khả dụng
free -h

# Nếu swap đang dùng nhiều → RAM không đủ
# → Giảm context hoặc dùng model nhỏ hơn
```

### Model trả lời kém chất lượng

```bash
# Giảm temperature cho code generation
# Trong Modelfile:
PARAMETER temperature 0.2

# Viết prompt cụ thể hơn
# Thay vì: "viết code"
# Dùng: "Viết Java 17 Spring Boot 3 REST controller cho Product entity
#        với CRUD, JPA, Jakarta Validation, custom exception handling"
```

---

## 📊 Custom Model Personas

### Personas có sẵn

| Persona | Model | Mô tả | Lệnh chạy |
|---------|-------|--------|-----------|
| **Qwen3-Coder** | Base | Model gốc, đa năng | `ollama run qwen3-coder:30b` |
| **Java Expert** | Custom | Senior Java Dev, Spring Boot, SOLID | `ollama run java-expert` |
| **Code Reviewer** | Custom | Review theo framework, severity levels | `ollama run code-reviewer` |

### Tạo Persona Mới

1. Tạo file trong `modelfiles/`:

```
FROM qwen3-coder:30b

PARAMETER temperature 0.3
PARAMETER num_ctx 32768

SYSTEM """
Mô tả vai trò và quy tắc ở đây...
"""
```

2. Build:

```bash
docker exec ollama ollama create <tên> -f /modelfiles/<tên>.modelfile
```

---

## 🔒 Bảo Mật

- ✅ **100% Offline**: Sau khi cài đặt, ngắt mạng vẫn hoạt động
- ✅ **No Data Leak**: Dữ liệu không rời khỏi máy
- ✅ **Local Storage**: Models và data lưu trong Docker volumes
- ✅ **SSH Tunnel**: Chia sẻ an toàn cho máy khác qua mã hóa

---

## 📚 Resources

| Resource | Link |
|----------|------|
| README đầy đủ | [README.md](README.md) |
| Ollama Docs | [github.com/ollama/ollama](https://github.com/ollama/ollama) |
| Qwen3-Coder | [github.com/QwenLM/Qwen3-Coder](https://github.com/QwenLM/Qwen3-Coder) |
| Open WebUI | [github.com/open-webui/open-webui](https://github.com/open-webui/open-webui) |
| Continue.dev | [continue.dev](https://continue.dev) |
| CodeGPT | [JetBrains Marketplace](https://plugins.jetbrains.com/plugin/21056-codegpt) |

---

## ⚙️ Thông Số Kỹ Thuật

### Model: Qwen3-Coder 30B (A3B)

- **Total Params**: 30.5B
- **Active Params**: 3.3B (Mixture of Experts)
- **Architecture**: Transformer-based MoE
- **Quantization**: Q4_K_M (4-bit)
- **Model Size on Disk**: ~18GB
- **RAM Required**: ~20GB (loaded)
- **Context Window**: 256K tokens max
- **Training Data**: 7.5T tokens (70% code)
- **Languages**: 100+ programming languages
- **License**: Apache 2.0

### System Requirements Met

- ✅ **OS**: Windows 11 Home Single Language
- ✅ **CPU**: Intel Core i5-14400 (10 cores, 16 threads, AVX2)
- ✅ **RAM**: 32GB (31.77GB available)
- ✅ **Disk**: 56GB free space
- ✅ **Docker**: 28.4.0

---

> 💡 **Mẹo**: Model chạy nhanh hơn sau lần đầu load vào RAM. Giữ model trong RAM bằng cách set `OLLAMA_KEEP_ALIVE=30m` trong `.env`

> ⚠️ **Lưu ý**: Mọi dữ liệu hoàn toàn local. Không có gì được gửi ra internet sau khi cài đặt.

---

**Ngày tạo**: 2026-02-24
**Version**: 1.0.0
