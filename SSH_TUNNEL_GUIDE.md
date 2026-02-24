# 🔐 Hướng Dẫn Sử Dụng Model Qua SSH Tunnel

## ✅ BƯỚC 1: Setup trên MÁY SERVER (Máy này - HOÀN THÀNH)

SSH Server đã được cài đặt và đang chạy!

### Thông tin kết nối:

```
Username: vkiet
SSH Port: 22
IP Address: [Xem hướng dẫn bên dưới]
```

### Lấy IP Address của Windows:

**Trên Windows (máy này), mở PowerShell và chạy**:

```powershell
ipconfig
```

Tìm dòng **"IPv4 Address"** trong phần:
- **"Wireless LAN adapter Wi-Fi"** (nếu dùng WiFi)
- **"Ethernet adapter"** (nếu dùng dây mạng)

Ví dụ: `192.168.1.100` hoặc `10.0.0.5`

**Ghi lại IP này**, sẽ dùng ở bước 2!

---

## 📱 BƯỚC 2: Kết nối từ MÁY CLIENT (Máy khác)

### Option 1: Dùng Linux/macOS Client

#### 2.1. Tạo SSH Key (lần đầu tiên)

Trên máy client, mở Terminal và chạy:

```bash
ssh-keygen -t ed25519 -C "ollama-tunnel"
```

Nhấn Enter 3 lần (không đặt passphrase cho đơn giản).

#### 2.2. Copy SSH Key sang Server

```bash
ssh-copy-id vkiet@<IP_ADDRESS>
```

Thay `<IP_ADDRESS>` bằng IP của Windows Server (lấy ở Bước 1).

Ví dụ:
```bash
ssh-copy-id vkiet@192.168.1.100
```

Nhập password: `vkiet432`

#### 2.3. Tạo SSH Tunnel

```bash
ssh -f -N -L 11434:localhost:11434 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    vkiet@<IP_ADDRESS>
```

Ví dụ:
```bash
ssh -f -N -L 11434:localhost:11434 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    vkiet@192.168.1.100
```

#### 2.4. Sử dụng Model

Bây giờ dùng model như thể nó đang chạy local:

```bash
# Cần cài Ollama trên client trước
curl -fsSL https://ollama.com/install.sh | sh

# Chat với model
ollama run qwen3-coder:30b "Viết hello world Java"

# Hoặc dùng API
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-coder:30b",
    "messages": [{"role": "user", "content": "Viết factorial Java"}]
  }'
```

#### 2.5. Ngắt Tunnel

```bash
# Tìm PID của tunnel
lsof -t -i :11434

# Kill tunnel
kill $(lsof -t -i :11434)
```

---

### Option 2: Dùng Windows Client

#### 2.1. Cài OpenSSH Client (nếu chưa có)

Mở PowerShell **Administrator** và chạy:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Client
```

#### 2.2. Tạo SSH Key

```powershell
ssh-keygen -t ed25519 -C "ollama-tunnel"
```

File key sẽ được lưu tại: `C:\Users\<YourUsername>\.ssh\id_ed25519`

#### 2.3. Copy SSH Key sang Server

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh vkiet@<IP_ADDRESS> "cat >> ~/.ssh/authorized_keys"
```

Nhập password: `vkiet432`

Ví dụ:
```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh vkiet@192.168.1.100 "cat >> ~/.ssh/authorized_keys"
```

#### 2.4. Tạo SSH Tunnel

```powershell
ssh -f -N -L 11434:localhost:11434 vkiet@<IP_ADDRESS>
```

Ví dụ:
```powershell
ssh -f -N -L 11434:localhost:11434 vkiet@192.168.1.100
```

**Lưu ý**: Trên Windows, tunnel sẽ chạy trong cửa sổ PowerShell. Giữ cửa sổ mở.

#### 2.5. Sử dụng Model

**Cài Ollama trên Windows Client**:

Tải từ: https://ollama.com/download/windows

Sau khi cài, mở PowerShell hoặc CMD:

```powershell
# Chat với model
ollama run qwen3-coder:30b "Viết hello world Java"

# Hoặc dùng API
curl http://localhost:11434/v1/chat/completions `
  -H "Content-Type: application/json" `
  -d '{
    "model": "qwen3-coder:30b",
    "messages": [{"role": "user", "content": "Viết factorial Java"}]
  }'
```

#### 2.6. Ngắt Tunnel

Đóng cửa sổ PowerShell đang chạy tunnel, hoặc:

```powershell
# Tìm process
Get-Process | Where-Object {$_.ProcessName -eq "ssh"}

# Kill process
Stop-Process -Name ssh
```

---

## 🔧 Tích Hợp IDE (Trên Client)

### VS Code + Continue.dev

1. Cài extension **Continue**
2. Mở `~/.continue/config.json` (Linux/macOS) hoặc `C:\Users\<YourUsername>\.continue\config.json` (Windows)
3. Thêm cấu hình:

```json
{
  "models": [
    {
      "title": "Qwen3-Coder 30B (Remote)",
      "provider": "ollama",
      "model": "qwen3-coder:30b",
      "apiBase": "http://localhost:11434",
      "contextLength": 65536
    }
  ]
}
```

4. Khởi động lại VS Code
5. Dùng `Ctrl+L` để chat

### IntelliJ IDEA + CodeGPT

1. Cài plugin **CodeGPT**
2. **Settings** → **Tools** → **CodeGPT**:
   - Provider: `Ollama`
   - Model: `qwen3-coder:30b`
   - URL: `http://localhost:11434`
3. Highlight code → Right click → **CodeGPT** → Explain/Review/Refactor

---

## 🛡️ Bảo Mật Nâng Cao

### Giới hạn SSH Key chỉ cho Tunnel

Trên **MÁY SERVER**, chỉnh file `~/.ssh/authorized_keys`:

```bash
nano ~/.ssh/authorized_keys
```

Thêm prefix vào đầu dòng public key:

```
no-agent-forwarding,no-X11-forwarding,permitopen="localhost:11434",command="/bin/false" ssh-ed25519 AAAA...
```

Kết quả: Key này chỉ được phép tạo tunnel tới port 11434, không thể chạy lệnh hay truy cập gì khác.

### Tự động khởi động Tunnel (Linux Client)

Tạo systemd service:

```bash
sudo nano /etc/systemd/system/ollama-tunnel.service
```

Nội dung:

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
    vkiet@<IP_ADDRESS>
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable và start:

```bash
sudo systemctl enable ollama-tunnel
sudo systemctl start ollama-tunnel
```

---

## 🐛 Troubleshooting

### Lỗi "Connection refused"

**Nguyên nhân**: Firewall Windows chặn port SSH (22).

**Giải pháp**: Trên **MÁY SERVER** (Windows), mở PowerShell **Administrator**:

```powershell
New-NetFirewallRule -DisplayName "SSH Server" -Direction Inbound -LocalPort 22 -Protocol TCP -Action Allow
```

### Lỗi "Permission denied (publickey)"

**Nguyên nhân**: SSH key chưa được copy đúng.

**Giải pháp**: Copy lại key hoặc dùng password authentication:

```bash
ssh -L 11434:localhost:11434 vkiet@<IP_ADDRESS>
```

Nhập password: `vkiet432`

### Tunnel bị ngắt sau vài phút

**Nguyên nhân**: NAT/Router timeout.

**Giải pháp**: Thêm keep-alive options:

```bash
ssh -f -N -L 11434:localhost:11434 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o TCPKeepAlive=yes \
    vkiet@<IP_ADDRESS>
```

### Test kết nối tunnel

```bash
# Kiểm tra port đã mở chưa
lsof -i :11434    # Linux/macOS
netstat -an | grep 11434    # Windows

# Test API
curl http://localhost:11434/api/version
```

---

## 📚 Models Có Sẵn

Sau khi kết nối tunnel, client có thể dùng:

| Model | Size | Mô tả |
|-------|------|-------|
| `qwen3-coder:30b` | 18 GB | Model gốc đa năng |
| `java-expert` | 18 GB | Chuyên Java/Spring Boot |
| `code-reviewer` | 18 GB | Review code chuyên sâu |

**Sử dụng**:

```bash
ollama run qwen3-coder:30b
ollama run java-expert
ollama run code-reviewer
```

---

## ⚡ Performance

**Tốc độ**: Phụ thuộc vào:
- Băng thông mạng LAN (khuyến nghị: 100 Mbps+)
- Độ trễ mạng (ping < 10ms là tốt)

**Model đang chạy trên server**, client chỉ gửi/nhận text nên bandwidth không cần cao lắm.

**Latency**:
- LAN (cùng WiFi/mạng): ~5-20ms → trải nghiệm như local
- Qua internet: Tùy khoảng cách, có thể chậm hơn

---

**Ngày tạo**: 2026-02-24
**Máy Server**: vkiet@VANKIET
**Model**: Qwen3-Coder 30B (18GB)
