hãy đọc readme để hiểu repo, 
check thông số của máy, thông số window để xem có thỏa mãn điều kiện không?


bạn đang check thông số của wsl rồi vì claude đang chạy trong wsl'
check thực tết của window bằng powershell vì image sẽ được build ở window

dọn ổ F rồi, check lại tất cả code xem hợp lý so với yêu cầu chưa, nếu đạt, bắt đầu thực hiện cài đặt và export

đã restart rồi, check model đi

bây giờ hãy đọc lại readme và hướng dẫn tôi sử dụng được model bằng máy khác thông qua SSH

pass là vkiet432, hãy cập nhật env

vậy bạn dùng pass này để setup trong session này luôn

với trường hợp không cùng mạng thì dùng cách kết nối nào?

tôi cài trên wsl mà

vkiet@VANKIET:~$ ollama run qwen3-coder:30b
Command 'ollama' not found, but can be installed with:
sudo snap install ollama

gọi docker chứ nhỉ?

tạo file hướng dẫn md để để tôi cài trên client
