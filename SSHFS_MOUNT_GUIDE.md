# 📁 Hướng Dẫn Mount Thư Mục Client → Server (SSHFS)

Mount thư mục từ **máy Client** lên **máy Server** để server có thể truy cập và xử lý files trên client.

---

## 📊 Kiến Trúc

```
┌──────────────────────┐         SSHFS Mount          ┌──────────────────────┐
│   MÁY SERVER         │◄──────────────────────────────│   MÁY CLIENT         │
│   (WSL2)             │                               │   (Máy bạn)          │
├──────────────────────┤                               ├──────────────────────┤
│ ~/client-workspace/  │ <── Mount point               │ E:\omega\project\    │
│   - src/             │                               │   (source code)      │
│   - README.md        │                               │                      │
│                      │                               │ SSH Server           │
│ Model có thể:        │                               │ Port: 22 hoặc 2222   │
│ - Review code        │                               │                      │
│ - Access files       │                               │                      │
└──────────────────────┘                               └──────────────────────┘
```

**Lợi ích:**
- ✅ Server có thể đọc/review code trên client
- ✅ Không cần copy files qua lại
- ✅ Real-time sync
- ✅ Bảo mật với SSH encryption

---

## 🖥️ PHẦN 1: Cài SSH Server Trên CLIENT

### A. Client Chạy Linux/WSL

**SSH server có sẵn!** Bỏ qua phần này, chuyển sang Phần 2.

---

### B. Client Chạy Windows (Native)

#### Bước 1: Cài OpenSSH Server

**Mở PowerShell Administrator** và chạy:

```powershell
# Cài OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Khởi động service
Start-Service sshd

# Tự động chạy lúc khởi động
Set-Service -Name sshd -StartupType 'Automatic'

# Mở firewall
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

#### Bước 2: Kiểm Tra SSH Đang Chạy

```powershell
Get-Service sshd
```

**Kết quả mong đợi:**
```
Status   Name               DisplayName
------   ----               -----------
Running  sshd               OpenSSH SSH Server
```

#### Bước 3: Test SSH Từ Chính Client

```powershell
ssh localhost
```

Nếu kết nối được → SSH server OK! ✅

---

### C. Client Chạy WSL2

#### Bước 1: Cài OpenSSH Server

```bash
sudo apt update
sudo apt install -y openssh-server
```

#### Bước 2: Khởi Động SSH

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh
```

#### Bước 3: Kiểm Tra Port

```bash
sudo ss -tlnp | grep sshd
```

Nên thấy: `LISTEN ... :22` hoặc `:2222`

---

## 🔗 PHẦN 2: Lấy Thông Tin Kết Nối Của Client

Bạn cần 3 thông tin sau:

### 1. IP Address Của Client

**Option A: Qua Tailscale (Khuyến nghị)**

Trên client, chạy:

```bash
tailscale ip -4
```

Ví dụ output: `100.64.168.100`

**Option B: Qua LAN**

```bash
# Linux/WSL
hostname -I | awk '{print $1}'

# Windows PowerShell
ipconfig | findstr /i "IPv4"
```

Ví dụ: `192.168.99.101`

### 2. Username

**Linux/WSL:**
```bash
whoami
```

**Windows:**
```powershell
echo $env:USERNAME
```

### 3. Đường Dẫn Thư Mục Cần Mount

**Linux/WSL:**
```bash
pwd
# Ví dụ: /home/user/projects
```

**Windows (qua WSL):**
- Ổ C: `/mnt/c/Users/YourName/Projects`
- Ổ D: `/mnt/d/code`
- Ổ E: `/mnt/e/omega/task 1/2511事業案件_develop2511quarter`

**Windows (Native OpenSSH):**
- Sử dụng path kiểu Windows với dấu `/`: `C:/Users/YourName/Projects`

---

## 📝 PHẦN 3: Ghi Lại Thông Tin

**Điền thông tin của bạn vào đây:**

```
CLIENT_USER     = ___________________  (username trên client)
CLIENT_IP       = ___________________  (IP Tailscale hoặc LAN)
CLIENT_PORT     = ___________________  (22 hoặc 2222)
CLIENT_PATH     = ___________________  (đường dẫn thư mục)
```

**Ví dụ:**
```
CLIENT_USER     = vkiet
CLIENT_IP       = 100.64.168.100
CLIENT_PORT     = 22
CLIENT_PATH     = /mnt/e/omega/task 1/2511事業案件_develop2511quarter/omega-cns-app-develop-2511-quarter
```

---

## 🔧 PHẦN 4: Mount Từ Server (Làm trên máy SERVER)

### Bước 1: Cài SSHFS (Đã làm sẵn)

```bash
sudo apt update
sudo apt install -y sshfs
```

### Bước 2: Tạo Mount Point

```bash
mkdir -p ~/client-workspace
```

### Bước 3: Mount Thư Mục

**Cú pháp chung:**

```bash
sshfs [CLIENT_USER]@[CLIENT_IP]:[CLIENT_PATH] ~/client-workspace -p [PORT] [OPTIONS]
```

**Example 1: Client Linux/WSL qua Tailscale**

```bash
sshfs vkiet@100.64.168.100:/home/vkiet/projects ~/client-workspace \
  -p 22 \
  -o allow_other \
  -o default_permissions \
  -o IdentityFile=~/.ssh/id_ed25519 \
  -o reconnect \
  -o ServerAliveInterval=15 \
  -o ServerAliveCountMax=3
```

**Example 2: Client Windows (WSL) với thư mục E:\omega\**

```bash
sshfs vkiet@100.64.168.100:"/mnt/e/omega/task 1/project" ~/client-workspace \
  -p 22 \
  -o allow_other \
  -o default_permissions \
  -o IdentityFile=~/.ssh/id_ed25519 \
  -o reconnect
```

**Lưu ý**: Dùng dấu ngoặc kép `"` nếu path có dấu cách!

**Example 3: Với Password (Không dùng SSH key)**

```bash
sshfs vkiet@100.64.168.100:/path/to/folder ~/client-workspace -p 22
# Nhập password khi được hỏi
```

### Bước 4: Kiểm Tra Mount

```bash
# Kiểm tra đã mount chưa
mountpoint ~/client-workspace

# List files
ls -la ~/client-workspace

# Xem thông tin mount
df -h | grep client-workspace
```

---

## 🎯 PHẦN 5: Sử Dụng

### Truy Cập Files Trên Client

```bash
cd ~/client-workspace
ls -la
cat README.md
```

### Review Code Bằng Model

```bash
# Review 1 file
docker exec -i ollama ollama run code-reviewer < ~/client-workspace/src/Main.java

# Review với script
./scripts/review.sh ~/client-workspace/src/UserService.java

# Chat với model về code
echo "Giải thích code trong ~/client-workspace/src/App.java" | docker exec -i ollama ollama run qwen3-coder:30b
```

### Unmount Khi Xong

```bash
fusermount -u ~/client-workspace
```

---

## 🔄 PHẦN 6: Tự Động Mount (Optional)

### Tạo Script Mount

```bash
nano ~/mount-client.sh
```

**Nội dung:**

```bash
#!/bin/bash

# ========== CẤU HÌNH ==========
CLIENT_USER="vkiet"                                    # Sửa thành username của bạn
CLIENT_IP="100.64.168.100"                             # Sửa thành IP của client
CLIENT_PORT="22"                                       # Hoặc 2222
CLIENT_PATH="/mnt/e/omega/task 1/project"              # Sửa thành path của bạn
MOUNT_POINT="$HOME/client-workspace"
SSH_KEY="$HOME/.ssh/id_ed25519"
# ===============================

echo "Mounting client workspace..."

# Kiểm tra đã mount chưa
if mountpoint -q "$MOUNT_POINT"; then
    echo "Already mounted!"
    exit 0
fi

# Mount
sshfs "$CLIENT_USER@$CLIENT_IP:$CLIENT_PATH" "$MOUNT_POINT" \
    -p "$CLIENT_PORT" \
    -o allow_other \
    -o default_permissions \
    -o IdentityFile="$SSH_KEY" \
    -o reconnect \
    -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    -o compression=yes

# Kiểm tra
if mountpoint -q "$MOUNT_POINT"; then
    echo "✓ Mounted successfully!"
    echo "  Access: cd $MOUNT_POINT"
else
    echo "✗ Mount failed!"
fi
```

**Cấp quyền:**

```bash
chmod +x ~/mount-client.sh
```

**Sử dụng:**

```bash
# Mount
~/mount-client.sh

# Unmount
fusermount -u ~/client-workspace
```

---

### Auto-mount Khi Khởi Động (Linux)

**Thêm vào `/etc/fstab`:**

```bash
sudo nano /etc/fstab
```

**Thêm dòng:**

```
vkiet@100.64.168.100:/mnt/e/omega/project /home/vkiet/client-workspace fuse.sshfs defaults,_netdev,reconnect,IdentityFile=/home/vkiet/.ssh/id_ed25519,allow_other,port=22 0 0
```

**Lưu ý:**
- Thay `vkiet`, `100.64.168.100`, path theo thông tin của bạn
- `_netdev`: Đợi network ready mới mount
- `reconnect`: Tự động reconnect khi mất kết nối

**Test:**

```bash
sudo mount -a
```

---

## 🛠️ PHẦN 7: Troubleshooting

### Lỗi: "remote host has disconnected"

**Nguyên nhân:** Client SSH server không chạy hoặc firewall chặn.

**Giải pháp:**

Trên **CLIENT**, kiểm tra:

```bash
# Linux/WSL
sudo systemctl status ssh

# Windows
Get-Service sshd
```

Nếu stopped → Start lại:

```bash
# Linux/WSL
sudo systemctl start ssh

# Windows
Start-Service sshd
```

---

### Lỗi: "Permission denied (publickey)"

**Nguyên nhân:** SSH key chưa được copy.

**Giải pháp:**

Từ **SERVER**, copy key sang **CLIENT**:

```bash
ssh-copy-id -p 22 vkiet@100.64.168.100
```

Hoặc dùng password authentication (bỏ `-o IdentityFile=...`):

```bash
sshfs vkiet@100.64.168.100:/path ~/client-workspace -p 22
```

---

### Lỗi: "Transport endpoint is not connected"

**Nguyên nhân:** Mount bị stale (client offline/network lost).

**Giải pháp:**

```bash
# Unmount force
fusermount -uz ~/client-workspace

# Mount lại
~/mount-client.sh
```

---

### Lỗi: Path với dấu cách không nhận

**Giải pháp:** Dùng dấu ngoặc kép hoặc escape:

```bash
# Cách 1: Dấu ngoặc kép
sshfs user@ip:"/mnt/e/omega/task 1" ~/mount

# Cách 2: Escape space
sshfs user@ip:/mnt/e/omega/task\ 1 ~/mount
```

---

### Mount chậm / lag

**Nguyên nhân:** Network latency cao hoặc large files.

**Giải pháp:**

Thêm options tối ưu:

```bash
sshfs ... \
  -o cache=yes \
  -o kernel_cache \
  -o compression=yes \
  -o Ciphers=aes128-ctr \
  -o auto_cache
```

---

## 📊 So Sánh Các Cách Chia Sẻ Files

| Phương pháp | Tốc độ | Realtime | Bảo mật | Độ phức tạp |
|-------------|--------|----------|---------|-------------|
| **SSHFS** | ⭐⭐⭐ | ✅ | 🔒🔒🔒 | ⭐⭐ |
| **SCP/SFTP** | ⭐⭐⭐⭐ | ❌ | 🔒🔒🔒 | ⭐ |
| **NFS** | ⭐⭐⭐⭐⭐ | ✅ | 🔒 | ⭐⭐⭐⭐ |
| **Samba** | ⭐⭐⭐⭐ | ✅ | 🔒🔒 | ⭐⭐⭐ |
| **Git sync** | ⭐⭐ | ❌ | 🔒🔒 | ⭐⭐⭐ |

**SSHFS tốt cho:**
- ✅ Development workflow (edit local, review remote)
- ✅ Qua VPN/Internet (encrypted)
- ✅ Không cần config phức tạp
- ✅ Tương thích đa nền tảng

---

## 🎯 Use Cases

### 1. Review Code Tự Động

```bash
#!/bin/bash
# auto-review.sh

# Mount client code
~/mount-client.sh

# Review all Java files
find ~/client-workspace -name "*.java" -type f | while read file; do
    echo "Reviewing: $file"
    docker exec -i ollama ollama run code-reviewer < "$file" > "${file}.review.txt"
done

echo "Reviews saved as *.review.txt"
```

### 2. Chat Về Code

```bash
# Hỏi model về toàn bộ project
find ~/client-workspace/src -name "*.java" | xargs cat | docker exec -i ollama ollama run qwen3-coder:30b "Phân tích kiến trúc của project này"
```

### 3. Generate Tests

```bash
cat ~/client-workspace/src/UserService.java | docker exec -i ollama ollama run java-expert "Viết unit tests cho class này với JUnit 5 và Mockito"
```

---

## 📋 Checklist Trước Khi Mount

- [ ] Client đã cài SSH server
- [ ] SSH server đang chạy trên client
- [ ] Đã có SSH key hoặc biết password
- [ ] Biết IP của client (Tailscale hoặc LAN)
- [ ] Biết username trên client
- [ ] Biết đường dẫn thư mục cần mount
- [ ] Firewall không chặn port SSH
- [ ] Client và server kết nối được qua Tailscale/LAN

---

**Ngày tạo**: 2026-02-24
**Server**: vkiet@VANKIET (100.64.168.87)
**Hỗ trợ**: Windows, Linux, macOS, WSL2
