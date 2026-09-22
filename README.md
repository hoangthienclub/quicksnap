# QuickSnag Native (100% Cocoa / AppKit macOS) ⚡

Ứng dụng chụp ảnh màn hình và chỉnh sửa nhanh ("update một xíu") siêu tốc, được viết **100% bằng Native Objective-C & AppKit** dành riêng cho macOS.

> [!TIP]
> **Hoàn toàn KHÔNG DÙNG Electron**: Dung lượng ứng dụng chỉ **157 KB**, khởi động tức thì 0ms, tiêu hao < 15MB RAM và **không bao giờ bị macOS Gatekeeper báo lỗi** *"Electron will damage your computer"*.

---

## 🌟 Tính Năng Nổi Bật

1. **Bộ công cụ chú thích chuẩn Snagit / CleanShot X**:
   - ↗️ **Mũi tên (Arrow)**: Nét vẽ sắc nhọn, tự tính toán góc nghiêng kèm đổ bóng tương phản cao.
   - 🔲 **Khung chữ nhật bo góc & Vòng tròn (Box & Oval)**: Đóng khung các chi tiết cần lưu ý.
   - 🔢 **Đánh số bước tự động (Step Badge 1, 2, 3...)**: Tự động tăng số mỗi lần bạn nhấp chuột vào ảnh để hướng dẫn thao tác từng bước.
   - 🙈 **Che mờ thông tin (Pixelate / Blur)**: Che mật khẩu, email, thông tin nhạy cảm.
   - ✍️ **Viết chữ (Text)**: Gõ chữ trực tiếp lên ảnh với hộp nền tương phản dễ đọc.
   - 🖍️ **Bút dạ quang (Highlighter)**: Tô sáng dòng văn bản bán trong suốt.
   - ↩️ **Undo / Redo**: Hoàn tác / làm lại không giới hạn (`Cmd + Z` / `Cmd + Shift + Z`).

2. **Luồng làm việc Siêu Tốc (1 Phím để Copy & Gửi ngay)**:
   - Nhấn **`Enter`** hoặc **`Cmd + C`**: Tự động hợp nhất mọi nét vẽ thành ảnh chất lượng cao, **ghi thẳng vào Clipboard hệ thống** (`NSPasteboard`) và **đóng cửa sổ editor ngay lập tức**! Bạn chỉ cần sang Zalo/Slack/Messenger/Jira/Gmail nhấn `Cmd + V` là xong.
   - Nhấn **`Cmd + S`**: Mở hộp thoại lưu ảnh ra file PNG/JPG.
   - Nhấn **`Esc`**: Hủy và đóng nhanh.

3. **Tích hợp sâu hệ điều hành**:
   - **Menu Bar Status Item**: Biểu tượng camera nằm ngay trên thanh Menu Bar góc phải của macOS, sẵn sàng phục vụ 24/7.
   - **Tự động mở khi bấm phím chụp macOS**: Chạy ngầm theo dõi Clipboard (`ClipboardWatcher`). Mỗi khi bạn bấm phím chụp quen thuộc của macOS (`Cmd + Shift + 4`, `Cmd + Ctrl + Shift + 4`), QuickSnag tự động mở ngay cửa sổ để bạn chỉnh sửa.
   - **Gọi Native Capture**: Kích hoạt trỏ chuột chọn vùng chụp gốc của macOS (`screencapture -i`).

---

## ⌨️ Bảng Phím Tắt Tiện Dụng

| Phím tắt | Tác vụ |
| :--- | :--- |
| **`Enter`** hoặc **`Cmd + C`** | **Copy ảnh đã sửa vào Clipboard & Đóng Editor** |
| **`Cmd + S`** | Lưu file ảnh ra ổ đĩa |
| **`Esc`** | Đóng / Thoát cửa sổ Editor |
| **`Cmd + Z`** | Hoàn tác (Undo) |
| **`Cmd + Shift + Z`** | Làm lại (Redo) |
| **`A`** | Chọn công cụ Mũi tên (Arrow) |
| **`R`** | Chọn công cụ Hình chữ nhật (Rectangle) |
| **`C`** | Chọn công cụ Vòng tròn (Circle) |
| **`S`** | Chọn công cụ Đánh số bước (Step Badge) |
| **`T`** | Chọn công cụ Viết chữ (Text) |
| **`B`** | Chọn công cụ Che mờ (Blur / Pixelate) |
| **`H`** | Chọn công cụ Bút dạ quang (Highlighter) |

---

## 🚀 Cách Chạy & Cài Đặt

### 1. Khởi chạy ngay:
```bash
open native-snag/QuickSnag.app
```
*(Icon camera của QuickSnag sẽ xuất hiện ngay trên thanh Menu Bar ở góc trên bên phải màn hình)*

### 2. Cài đặt vào thư mục Ứng dụng của Mac:
```bash
cp -R native-snag/QuickSnag.app /Applications/
```

### 3. Biên dịch lại (nếu cần):
```bash
cd native-snag
./scripts/package.sh
```
# quicksnap
