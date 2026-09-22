# Plan: Hide from Menu & Taskbar, Icon Only, Right-Click to Quit

## Mục Tiêu
Cấu hình QuickSnag (cả macOS và Windows) thành ứng dụng chạy ngầm (Agent / Tray App):
1. Không xuất hiện trên Dock/Taskbar.
2. Không xuất hiện trên thanh Application Menu trên macOS (File, Edit...).
3. Ở khay hệ thống: Chỉ hiển thị icon.
   - Chuột trái (Left-click): Chụp màn hình ngay lập tức (Interactive Capture).
   - Chuột phải (Right-click): Mở menu ngữ cảnh để người dùng chọn "Quit QuickSnag" hoặc các tuỳ chọn nhanh.

## Các Bước Thực Hiện

### Bước 1: macOS Info.plist (`native-snag/Info.plist`)
- Thêm `<key>LSUIElement</key><true/>` để macOS ẩn hoàn toàn app khỏi Dock và thanh menu chính của hệ thống.

### Bước 2: macOS MenuBarController (`native-snag/Sources/MenuBarController.m`)
- Tách biệt sự kiện chuột:
  - Không gán trực tiếp `self.statusItem.menu = menu` (tránh việc click chuột trái bị bật menu).
  - Lắng nghe sự kiện `NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp`.
  - Chuột trái -> Gọi `menuBarDidRequestCapture` (chụp ngay lập tức).
  - Chuột phải (hoặc Control+Click) -> Gọi `popUpStatusItemMenu:` hiển thị menu có "Quit QuickSnag".

### Bước 3: Windows App & MainWindow (`windows/` & `native-snag-win/`)
- Trong `MainWindow.xaml`: Thêm `ShowInTaskbar="False"`.
- Trong `App.xaml.cs`: Đảm bảo `_notifyIcon.MouseClick` xử lý:
  - Chuột trái -> `TriggerCapture()`.
  - Chuột phải -> Kích hoạt ContextMenuStrip chứa `Exit QuickSnag`.

### Bước 4: Kiểm Tra (Verification) & Build
- Biên dịch macOS app (`make clean && make build`).
- Chạy thử và xác nhận:
  - App không hiện trên Dock.
  - Click chuột trái vào camera icon: Mở bộ chụp ảnh màn hình.
  - Click chuột phải vào camera icon: Hiện menu với nút Thoát (Quit).
