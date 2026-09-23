# Superpowers Review Pass: QuickSnag Tray-Only Mode

## Summary
Đã hoàn thành cấu hình QuickSnag ẩn hoàn toàn khỏi Dock/Taskbar và thanh Application Menu chính, chỉ chạy dưới dạng icon khay hệ thống (System Tray / Status Item):
- Chuột trái (Left-click): Chụp màn hình ngay lập tức (Interactive Capture).
- Chuột phải (Right-click): Hiển thị menu ngữ cảnh chứa tuỳ chọn Thoát (**Quit QuickSnag** / **Exit QuickSnag**).

## Verification Results
- macOS build: `make clean && make build` biên dịch thành công với 0 cảnh báo, sinh `QuickSnag.app` kèm `LSUIElement=true`.
- Đã đóng gói lại file `release/QuickSnag-macOS-arm64.zip`.
- Đã commit và push code lên nhánh `main` và kích hoạt tag release `v1.0.3` trên GitHub Actions.

## Issue Review by Severity
- **Blocker**: Không có.
- **Major**: Không có.
- **Minor**: Không có.
- **Nit**: Không có.
