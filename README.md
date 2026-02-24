# Local AI Coder

> Hệ thống AI hỗ trợ lập trình chạy hoàn toàn local, triển khai bằng Docker.
> Dữ liệu không rời khỏi máy. Không phụ thuộc internet sau khi cài đặt.

```
┌─────────────────────────────────────────────────────────────────┐
│                      Local AI Coder                             │
│                                                                 │
│   ┌──────────┐    ┌──────────────┐    ┌───────────────────┐    │
│   │  Ollama   │◄──│  Open WebUI   │    │  IDE / Terminal   │    │
│   │  :11434   │    │  :3000        │    │  Continue.dev     │    │
│   │           │    │  (Chat UI)    │    │  CodeGPT          │    │
│   │  Qwen3-   │    └──────────────┘    └───────────────────┘    │
│   │  Coder    │                                                 │
│   │  30B      │◄── SSH Tunnel (mã hóa) ◄── Máy Client          │
│   └──────────┘                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Mục lục

1. [Tổng quan](#1-tổng-quan)
2. [Yêu cầu hệ thống](#2-yêu-cầu-hệ-thống)
3. [Cấu trúc project](#3-cấu-trúc-project)
4. [Cài đặt nhanh](#4-cài-đặt-nhanh)
5. [Cài đặt chi tiết](#5-cài-đặt-chi-tiết)
6. [Sử dụng](#6-sử-dụng)
7. [Tích hợp IDE](#7-tích-hợp-ide)
8. [Chia sẻ cho máy khác qua SSH Tunnel](#8-chia-sẻ-cho-máy-khác-qua-ssh-tunnel)
9. [Custom Model Personas](#9-custom-model-personas)
10. [Quản lý và vận hành](#10-quản-lý-và-vận-hành)
11. [Tối ưu hiệu năng](#11-tối-ưu-hiệu-năng)
12. [Xử lý lỗi](#12-xử-lý-lỗi)
13. [Tham khảo](#13-tham-khảo)

---

## 1. Tổng quan

### Vấn đề

Khách hàng yêu cầu AI hỗ trợ phân tích và sinh code Java nhưng **không chấp nhận gửi dữ liệu lên cloud** (GitHub Copilot, ChatGPT, Claude Code...) vì lo ngại bảo mật và lộ mã nguồn.

### Giải pháp

Triển khai **Qwen3-Coder 30B (A3B)** — model AI chuyên code mạnh nhất có thể chạy trên phần cứng phổ thông — hoàn toàn local bằng Docker. Kèm giao diện web, tích hợp IDE, và khả năng chia sẻ an toàn cho máy khác qua SSH Tunnel.

### Model: Qwen3-Coder 30B (A3B)

| Thông số              | Giá trị                                      |
| --------------------- | --------------------------------------------- |
| Parameters tổng       | 30.5B                                         |
| Parameters kích hoạt  | 3.3B (Mixture of Experts — nhanh như model 3B)|
| Context window        | **256K tokens** (đọc được ~6,000 dòng code)   |
| Training data         | 7.5 nghìn tỷ tokens (70% code)                |
| Ngôn ngữ lập trình    | 100+ (Java, Python, JS, Go, Rust...)          |
| License               | Apache 2.0 (thương mại tự do)                  |

### So sánh với Qwen 2.5 Coder 7B (model cũ)

| Tiêu chí              | Qwen 2.5 Coder 7B | Qwen3-Coder 30B     |
| ---------------------- | ------------------ | -------------------- |
| Context window         | 32K tokens         | **256K tokens (8x)** |
| Đọc file code dài      | Yếu                | **Rất tốt**         |
| Tốc độ CPU (32GB RAM) | 4–7 tok/s          | **12–15 tok/s**      |
| Code quality           | Tốt                | **Vượt trội**        |
| Agentic / Tool calling | Không              | **Có**               |

---

## 2. Yêu cầu hệ thống

### Máy Server (chạy model)

| Thành phần | Tối thiểu              | Khuyến nghị           |
| ---------- | ---------------------- | --------------------- |
| OS         | Linux / macOS / Win 10+| Ubuntu 22.04+ LTS     |
| CPU        | AVX2 support           | Intel i7+ / AMD Ryzen 7+ |
| RAM        | 32 GB                  | 32 GB                 |
| Ổ đĩa     | 30 GB trống            | SSD NVMe 50 GB+       |
| Docker     | Docker 24+             | Docker 27+             |
| Mạng       | Cần khi tải model      | Không cần sau khi cài  |

### Máy Client (nếu dùng SSH Tunnel)

| Thành phần | Yêu cầu                              |
| ---------- | ------------------------------------- |
| OS         | Bất kỳ (Linux / macOS / Windows)      |
| SSH Client | Có sẵn trên hầu hết OS               |
| Ollama CLI | Tùy chọn (có thể dùng API thay thế)  |

---

## 3. Cấu trúc project

```
local-ai-coder/
├── docker-compose.yml              # Docker services: Ollama + Open WebUI
├── .env.example                    # Cấu hình mẫu (copy → .env)
├── .gitignore
├── README.md                       # Tài liệu này
│
├── modelfiles/                     # Custom model personas
│   ├── JavaExpert.modelfile        # Senior Java Developer persona
│   └── CodeReviewer.modelfile      # Code Reviewer persona
│
├── nginx/                          # Reverse proxy (tùy chọn)
│   └── ollama-proxy.conf           # Nginx config + IP whitelist
│
└── scripts/                        # Scripts tiện ích
    ├── setup.sh                    # Cài đặt tự động (1 lệnh)
    ├── health-check.sh             # Kiểm tra trạng thái hệ thống
    ├── review.sh                   # Gửi file code để review
    ├── tunnel-server-setup.sh      # Setup SSH trên server
    └── tunnel-client-connect.sh    # Kết nối tunnel từ client
```

---

## 4. Cài đặt nhanh

Dành cho người muốn chạy nhanh nhất có thể:

```bash
# 1. Clone project
git clone <repo-url> local-ai-coder
cd local-ai-coder

# 2. Tạo file cấu hình
cp .env.example .env

# 3. Chạy setup tự động (cài tất cả, tải model)
chmod +x scripts/*.sh
./scripts/setup.sh

# 4. Sử dụng
docker exec -it ollama ollama run qwen3-coder:30b    # Chat terminal
# hoặc mở http://localhost:3000                       # Web UI
```

> ⏱️ Lần đầu chạy cần tải model ~18 GB. Các lần sau khởi động trong vài giây.

---

## 5. Cài đặt chi tiết

### 5.1. Cài Docker

**Linux (Ubuntu/Debian):**

```bash
# Cài Docker Engine
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Kiểm tra
docker --version
docker compose version
```

**macOS:**

Tải Docker Desktop từ [https://docker.com/get-docker](https://docker.com/get-docker).

**Windows:**

Tải Docker Desktop từ [https://docker.com/get-docker](https://docker.com/get-docker). Bật WSL 2 khi được hỏi.

### 5.2. Clone và cấu hình

```bash
git clone <repo-url> local-ai-coder
cd local-ai-coder

# Tạo file cấu hình
cp .env.example .env
```

Chỉnh `.env` nếu cần:

```bash
# .env — Các giá trị mặc định thường phù hợp cho hầu hết trường hợp

MODEL_NAME=qwen3-coder:30b     # Model chính
OLLAMA_PORT=11434               # Port API
WEBUI_PORT=3000                 # Port giao diện web
OLLAMA_MEMORY_LIMIT=28g        # Giới hạn RAM cho Docker
OLLAMA_KEEP_ALIVE=5m           # Giữ model trong RAM bao lâu sau lần dùng cuối
```

### 5.3. Khởi động containers

```bash
docker compose up -d
```

Docker sẽ tải images (lần đầu ~2–3 GB) và khởi động 2 services:

| Service    | Mô tả             | Port  |
| ---------- | ------------------ | ----- |
| `ollama`   | Engine chạy model  | 11434 |
| `open-webui` | Giao diện chat web | 3000  |

Kiểm tra:

```bash
docker compose ps

# Output:
# NAME        STATUS              PORTS
# ollama      Up (healthy)        0.0.0.0:11434->11434/tcp
# open-webui  Up                  0.0.0.0:3000->8080/tcp
```

### 5.4. Tải model

```bash
# Tải Qwen3-Coder 30B (~18 GB, cần mạng tốt)
docker exec ollama ollama pull qwen3-coder:30b
```

> 💡 **Mẹo:** Nếu mạng chậm hoặc hay ngắt, Ollama hỗ trợ tải tiếp (resume). Chạy lại lệnh trên nếu bị gián đoạn.

### 5.5. Tạo custom model personas

```bash
# Java Expert — chuyên Java/Spring Boot
docker exec ollama ollama create java-expert -f /modelfiles/JavaExpert.modelfile

# Code Reviewer — review code theo framework
docker exec ollama ollama create code-reviewer -f /modelfiles/CodeReviewer.modelfile
```

### 5.6. Xác nhận cài đặt

```bash
./scripts/health-check.sh
```

Hoặc kiểm tra thủ công:

```bash
# API
curl http://localhost:11434/api/version

# Liệt kê models
docker exec ollama ollama list

# Test generate
docker exec -it ollama ollama run qwen3-coder:30b "Viết hello world Java"
```

### 5.7. Sau khi cài xong — ngắt mạng

Sau khi model đã tải, có thể **ngắt hoàn toàn kết nối internet**. Hệ thống hoạt động offline 100%.

---

## 6. Sử dụng

### 6.1. Chat qua Terminal

```bash
# Dùng model gốc
docker exec -it ollama ollama run qwen3-coder:30b

# Dùng Java Expert persona
docker exec -it ollama ollama run java-expert

# Dùng Code Reviewer persona
docker exec -it ollama ollama run code-reviewer
```

Trong chat session, gõ yêu cầu:

```
>>> Viết Spring Boot 3 REST controller CRUD cho entity Product,
    sử dụng JPA, Jakarta Validation, ResponseEntity, và custom exception handling
```

Thoát: `/bye` hoặc `Ctrl + D`.

### 6.2. Chat qua Web UI

1. Mở trình duyệt → `http://localhost:3000`.
2. Tạo tài khoản admin (lần đầu, chỉ lưu local).
3. Chọn model từ dropdown → chat.
4. Kéo thả file để upload phân tích.

### 6.3. Phân tích file code

```bash
# Review 1 file
./scripts/review.sh src/main/java/com/example/UserService.java

# Review cả folder
./scripts/review.sh src/main/java/com/example/service/

# Review với prompt tùy chỉnh
./scripts/review.sh OrderController.java "Tập trung vào security và SQL injection"
```

Hoặc pipe trực tiếp:

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

### 6.4. Gọi API (tương thích OpenAI format)

```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-coder:30b",
    "messages": [
      {"role": "system", "content": "Bạn là Senior Java Developer."},
      {"role": "user", "content": "Viết custom exception handler cho Spring Boot"}
    ]
  }'
```

### 6.5. Tích hợp Python

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

### 6.6. Tích hợp Java (OkHttp)

```java
OkHttpClient client = new OkHttpClient.Builder()
        .readTimeout(120, TimeUnit.SECONDS)
        .build();

JsonObject body = new JsonObject();
body.addProperty("model", "qwen3-coder:30b");
// ... (xem chi tiết trong phần Phụ lục)

Request request = new Request.Builder()
        .url("http://localhost:11434/v1/chat/completions")
        .post(RequestBody.create(body.toString(), MediaType.parse("application/json")))
        .build();
```

---

## 7. Tích hợp IDE

### 7.1. VS Code — Continue.dev

1. Extensions → tìm **"Continue"** → Install.
2. Chỉnh `~/.continue/config.json`:

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

Phím tắt:

| Phím               | Chức năng                  |
| ------------------- | -------------------------- |
| `Ctrl + L`          | Mở chat panel              |
| `Ctrl + I`          | Inline edit tại chỗ         |
| `Ctrl + Shift + L`  | Gửi code đang chọn vào chat |
| `Tab`               | Chấp nhận autocomplete      |

### 7.2. IntelliJ IDEA — CodeGPT

1. `Settings` → `Plugins` → tìm **"CodeGPT"** → Install.
2. `Settings` → `Tools` → `CodeGPT`:
   - Provider: `Ollama`
   - Model: `qwen3-coder:30b`
   - URL: `http://localhost:11434`
3. Highlight code → chuột phải → **CodeGPT** → Explain / Review / Refactor / Test.

---

## 8. Chia sẻ cho máy khác qua SSH Tunnel

Khi model chạy trên 1 máy server và bạn muốn **duy nhất 1 máy client** truy cập:

```
Máy SERVER                   SSH Tunnel (mã hóa)              Máy CLIENT
┌──────────────┐       ┌──────────────────────┐       ┌──────────────┐
│ Docker       │       │                      │       │ IDE          │
│  Ollama      │◄──────│  Port 11434 ◄──────► │◄──────│ Terminal     │
│  :11434      │       │  (chỉ ai có SSH key  │       │ localhost    │
│  (localhost) │       │   mới dùng được)     │       │  :11434      │
└──────────────┘       └──────────────────────┘       └──────────────┘
```

### 8.1. Setup Server

```bash
# Trên máy server — chạy script setup
./scripts/tunnel-server-setup.sh
```

Script sẽ kiểm tra SSH server, tạo user riêng cho tunnel (tùy chọn), và hiển thị hướng dẫn.

Hoặc setup thủ công:

```bash
# Đảm bảo SSH server đang chạy
sudo systemctl enable ssh
sudo systemctl start ssh

# Ollama giữ nguyên localhost:11434 — KHÔNG expose ra ngoài
```

### 8.2. Setup Client

```bash
# Trên máy client — copy .env.example và chỉnh thông tin server
cp .env.example .env
# Sửa: SSH_SERVER_USER, SSH_SERVER_IP, SSH_SERVER_PORT, SSH_KEY_PATH

# Chạy script kết nối
./scripts/tunnel-client-connect.sh
```

Hoặc kết nối thủ công:

```bash
# Tạo SSH key (lần đầu)
ssh-keygen -t ed25519 -C "ollama-tunnel"
ssh-copy-id user@192.168.1.100

# Tạo tunnel
ssh -f -N -L 11434:localhost:11434 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    user@192.168.1.100

# Dùng model (y hệt như model đang chạy local)
ollama run qwen3-coder:30b
curl http://localhost:11434/v1/chat/completions ...
```

### 8.3. Tự động kết nối khi khởi động (Linux client)

```bash
sudo nano /etc/systemd/system/ollama-tunnel.service
```

```ini
[Unit]
Description=SSH Tunnel to Ollama Server
After=network-online.target

[Service]
Type=simple
User=your-username
ExecStart=/usr/bin/ssh -N -L 11434:localhost:11434 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -i /home/your-username/.ssh/id_ed25519 \
    user@192.168.1.100
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable ollama-tunnel
sudo systemctl start ollama-tunnel
```

### 8.4. Bảo mật nâng cao

Giới hạn SSH key chỉ được dùng cho tunnel (trên server):

```bash
# Trong /home/ollama-tunnel/.ssh/authorized_keys, thêm prefix:
no-agent-forwarding,no-X11-forwarding,permitopen="localhost:11434",command="/bin/false" ssh-ed25519 AAAA... client-key
```

Kết quả: key này chỉ tạo được tunnel tới port 11434, không thể chạy lệnh hay truy cập gì khác trên server.

---

## 9. Custom Model Personas

Project bao gồm 2 persona mẫu trong `modelfiles/`. Bạn có thể tạo thêm.

### Personas có sẵn

| Persona | File | Mô tả | Lệnh chạy |
|---------|------|--------|------------|
| **Java Expert** | `JavaExpert.modelfile` | Senior Java Dev, Spring Boot, SOLID | `ollama run java-expert` |
| **Code Reviewer** | `CodeReviewer.modelfile` | Review theo framework có severity levels | `ollama run code-reviewer` |

### Tạo persona mới

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

### Ví dụ thêm personas

**API Designer:**

```
FROM qwen3-coder:30b
PARAMETER temperature 0.3
PARAMETER num_ctx 32768
SYSTEM """
Bạn là API Designer chuyên thiết kế RESTful API.
Tuân thủ OpenAPI 3.0, JSON:API conventions, proper HTTP status codes.
Luôn generate kèm Swagger/OpenAPI spec.
"""
```

**Database Expert:**

```
FROM qwen3-coder:30b
PARAMETER temperature 0.2
PARAMETER num_ctx 32768
SYSTEM """
Bạn là DBA chuyên PostgreSQL và query optimization.
Phân tích query plan, đề xuất indexes, normalization.
"""
```

---

## 10. Quản lý và vận hành

### Docker commands

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

### Ollama commands (chạy trong container)

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

### Backup và restore

```bash
# Backup model data (Docker volume)
docker run --rm -v ollama-data:/data -v $(pwd)/backup:/backup \
  alpine tar czf /backup/ollama-backup.tar.gz -C /data .

# Restore
docker run --rm -v ollama-data:/data -v $(pwd)/backup:/backup \
  alpine tar xzf /backup/ollama-backup.tar.gz -C /data
```

### Cho team truy cập Web UI qua LAN

Open WebUI mặc định bind `0.0.0.0:3000`. Bất kỳ máy nào trong LAN đều truy cập được:

```
http://<server-ip>:3000
```

Nếu muốn giới hạn, bỏ comment khối `nginx` trong `docker-compose.yml` và chỉnh IP whitelist trong `nginx/ollama-proxy.conf`.

---

## 11. Tối ưu hiệu năng

### RAM budget cho 32GB

| Thành phần               | RAM       |
| ------------------------ | --------- |
| OS                       | ~4 GB     |
| Ollama + Model (Q4)     | ~18–20 GB |
| Context window (32K)     | ~2 GB     |
| Open WebUI               | ~0.5 GB   |
| **Tổng**                | **~25 GB** |
| **Còn lại cho IDE/apps** | **~7 GB** |

### Điều chỉnh context length

Trong `.env`:

```bash
# Hoặc chỉnh qua Modelfile: PARAMETER num_ctx 32768
```

| Context   | RAM thêm | Phù hợp cho                |
| --------- | -------- | --------------------------- |
| 8192      | +0.5 GB  | Chat, generate code ngắn    |
| 32768     | +2 GB    | Review 1–2 file (mặc định)  |
| 65536     | +4 GB    | Phân tích cả package         |

### Tiết kiệm RAM

```bash
# Giảm thời gian giữ model trong RAM
# .env:
OLLAMA_KEEP_ALIVE=2m   # Unload model sau 2 phút idle (mặc định 5m)

# Chỉ cho phép 1 model chạy cùng lúc
OLLAMA_MAX_LOADED_MODELS=1
```

### Tối ưu hệ thống Linux

```bash
# Tạo swap file 16GB (đề phòng OOM)
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Tăng swappiness
sudo sysctl vm.swappiness=60
```

---

## 12. Xử lý lỗi

### Container không khởi động

```bash
docker compose logs ollama
docker compose logs open-webui
```

### Ollama OOM (Out of Memory)

```bash
# Giảm context
# Trong Modelfile: PARAMETER num_ctx 8192

# Hoặc dùng bản quantize nhẹ hơn
docker exec ollama ollama pull qwen3-coder:30b-a3b-q3_K_M
```

### Tốc độ chậm (< 5 tok/s)

```bash
# Kiểm tra CPU hỗ trợ AVX2
grep -o 'avx2' /proc/cpuinfo | head -1

# Kiểm tra RAM khả dụng
free -h

# Nếu swap đang dùng nhiều → RAM không đủ → giảm context hoặc dùng model nhỏ hơn
```

### SSH Tunnel không kết nối

```bash
# Debug verbose
ssh -v -N -L 11434:localhost:11434 user@server-ip

# Kiểm tra port đã bị chiếm chưa
lsof -i :11434   # Linux/macOS
netstat -an | findstr 11434   # Windows
```

### Model trả lời kém chất lượng

```bash
# Giảm temperature cho code generation
# Trong Modelfile: PARAMETER temperature 0.2

# Viết prompt cụ thể hơn:
# Thay vì: "viết code"
# Dùng: "Viết Java 17 Spring Boot 3 REST controller cho Product entity
#        với CRUD, JPA, Jakarta Validation, custom exception handling"
```

---

## 13. Tham khảo

| Resource | Link |
|----------|------|
| Ollama Documentation | [github.com/ollama/ollama](https://github.com/ollama/ollama) |
| Qwen3-Coder Official | [github.com/QwenLM/Qwen3-Coder](https://github.com/QwenLM/Qwen3-Coder) |
| Qwen3-Coder Local Guide | [unsloth.ai/docs/models/qwen3-coder](https://unsloth.ai/docs/models/qwen3-coder-how-to-run-locally) |
| Open WebUI | [github.com/open-webui/open-webui](https://github.com/open-webui/open-webui) |
| Continue.dev | [continue.dev](https://continue.dev) |
| CodeGPT Plugin | [JetBrains Marketplace](https://plugins.jetbrains.com/plugin/21056-codegpt) |

---

> 📝 *Tạo ngày 24/02/2026*
>
> **Mọi dữ liệu hoàn toàn local. Không có gì được gửi ra internet sau khi cài đặt.**
