# QuickSnag Native for Windows (C# .NET WPF) 🪟

Bản build native 100% bằng **C# .NET 8 / WPF / Win32 API** dành riêng cho hệ điều hành **Windows 10 & Windows 11**.

> [!TIP]
> **Hoàn toàn KHÔNG DÙNG Electron**: Đóng gói thành đúng **1 file duy nhất `QuickSnag.exe`**, không cần cài đặt, tải về là click đúp dùng ngay, tiêu hao < 25MB RAM ở khay hệ thống (System Tray).

---

## 📥 Tải Về (Downloads / Releases)
Tải file tại mục **[Releases](../../releases)** trên GitHub:
- **[QuickSnag-Windows-x64.zip](../../releases)** (Bao gồm file thực thi `QuickSnag.exe`).

---

## 🌟 Tính Năng Trên Windows

1. **Phím tắt toàn cục**:
   - Nhấn **`Ctrl + Shift + S`**: Tự động chụp toàn màn hình và bật cửa sổ chỉnh sửa nổi.
2. **Lắng nghe phím chụp hệ điều hành**:
   - Khi bạn bấm phím **`PrtScn`** hoặc **`Win + Shift + S`** (Snipping Tool mặc định của Windows), QuickSnag tự động bắt ảnh mới từ Clipboard và mở editor.
3. **Thao tác 1 Phím Siêu Tốc**:
   - Nhấn **`Enter`** hoặc **`Ctrl + C`**: Tự động hợp nhất tất cả hình vẽ, lưu vào Windows Clipboard (`Clipboard.SetImage`) và ẩn cửa sổ ngay để bạn sang Zalo/Slack bấm `Ctrl + V`.
   - Nhấn **`Ctrl + S`**: Lưu file ảnh PNG/JPG.
   - Nhấn **`Esc`**: Ẩn cửa sổ editor.
4. **Bộ công cụ chú thích**:
   - Mũi tên (Arrow), Đóng khung (Rect), Vòng tròn (Oval), Đánh số bước tự động (Step Badge 1-2-3), Chữ trong suốt (Transparent Text), Che mờ (Blur), Undo (`Ctrl + Z`).

---

## 🔨 Cách Tự Biên Dịch (Dành cho Developer)

Nếu muốn tự build trên máy Windows:
```cmd
cd native-snag-win
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
```
File thực thi độc lập sẽ được tạo tại:
`bin\Release\net8.0-windows\win-x64\publish\QuickSnag.exe`
