# Plan: Tính Năng Chọn & Di Chuyển Annotation (Select & Move) Cho QuickSnag

## Goal
Cho phép người dùng chọn (Select) và di chuyển (Move / Drag & Drop) bất kỳ đối tượng chú thích nào đã vẽ (Mũi tên, Box, Circle, Step Badge, Text, Blur, Highlight) đến vị trí mới, hỗ trợ phím xóa `Delete` / `Backspace`, căn chỉnh bằng phím mũi tên `↑ ↓ ← →`, và tương thích 100% với hệ thống Undo/Redo (`Cmd+Z`).

## Assumptions
- QuickSnag là ứng dụng 100% Native AppKit/Objective-C trên macOS.
- Mọi annotation được quản lý dưới dạng các object `AnnotationShape` trong mảng `NSMutableArray<AnnotationShape *> *shapes` của `CanvasView`.
- Viền chọn (Selection Box/Handles) chỉ là visual overlay trên màn hình, không bao giờ được in vào ảnh khi xuất (`renderComposedImage`).

## Plan

### Bước 1: Mở rộng Model `AnnotationShape` (Hit-testing & Dịch chuyển toạ độ)
- **Files**:
  - `native-snag/Sources/Models.h`
  - `native-snag/Sources/Models.m`
- **Change**:
  - Thêm `ToolTypeSelect = 0` vào enum `ToolType`.
  - Bổ sung phương thức `(NSRect)boundingRect` tính khung bao quanh cho từng loại shape (Rect, Circle, Step, Text, Arrow, Blur, Highlight).
  - Bổ sung phương thức `(BOOL)hitTestPoint:(NSPoint)point tolerance:(CGFloat)tolerance`:
    - Với Rect/Circle rỗng: Kiểm tra click trúng cạnh viền (stroke border trong phạm vi +/- 6px), không chiếm vùng rỗng bên trong.
    - Với Text/StepBadge/Blur: Kiểm tra click trong khung bounding box.
    - Với Arrow: Tính khoảng cách vuông góc từ điểm click đến đoạn thẳng $(P_{start} \to P_{end}) < 8px$.
    - Với Highlight: Kiểm tra khoảng cách đến các đoạn nối trong `pointsArray`.
  - Bổ sung phương thức `(void)translateByDx:(CGFloat)dx dy:(CGFloat)dy` để tịnh tiến toạ độ `startPoint`, `endPoint` và toàn bộ mảng `pointsArray`.
- **Verify**: Chạy `make build` để đảm bảo code model biên dịch thành công.

### Bước 2: Tích hợp logic Select, Move & Render Selection trên `CanvasView`
- **Files**:
  - `native-snag/Sources/CanvasView.h`
  - `native-snag/Sources/CanvasView.m`
- **Change**:
  - Khai báo `@property (nonatomic, strong, nullable) AnnotationShape *selectedShape;` và cờ `BOOL isRenderingForExport;`.
  - Cập nhật `mouseDown:`:
    - Nếu đang ở `ToolTypeSelect` HOẶC người dùng đang giữ phím `Cmd`: Duyệt mảng `shapes` từ trên xuống dưới (reverse order) gọi `hitTestPoint:`.
    - Nếu trúng một shape: Gán `self.selectedShape = shape;`, bật chế độ `isDraggingSelectedShape = YES`, lưu vị trí chuột ban đầu `dragStartPoint`.
    - Nếu không trúng shape nào: Bỏ chọn (`self.selectedShape = nil;`).
  - Cập nhật `mouseDragged:`:
    - Nếu đang trong `isDraggingSelectedShape`: Tính $\Delta x, \Delta y$, gọi `[self.selectedShape translateByDx:dx dy:dy]`, gọi `[self setNeedsDisplay:YES]`.
  - Cập nhật `mouseUp:`:
    - Nếu vừa kết thúc kéo di chuyển: Đẩy trạng thái mới vào `HistoryManager` (`pushState:`) để `Cmd+Z` có thể hoàn tác vị trí cũ.
  - Cập nhật `drawRect:`:
    - Nếu `selectedShape != nil && !self.isRenderingForExport`: Vẽ khung viền nét đứt (dashed border) màu Accent Cyan (`#38BDF8`) cùng các chấm tròn handles nhỏ tại các góc/đầu mút của hình được chọn.
  - Thêm hàm `(void)deleteSelectedShape;` để xóa hình đang chọn và ghi vào lịch sử.
  - Thêm hàm `(void)nudgeSelectedShapeByDx:(CGFloat)dx dy:(CGFloat)dy;` để dịch chuyển hình theo phím mũi tên.
- **Verify**: Chạy `make build` kiểm tra tính toàn vẹn của `CanvasView`.

### Bước 3: Cập nhật `ToolbarView` & Phím tắt trong `EditorWindowController`
- **Files**:
  - `native-snag/Sources/ToolbarView.m`
  - `native-snag/Sources/ToolbarView.h`
  - `native-snag/Sources/EditorWindowController.m`
- **Change**:
  - Trong `ToolbarView.m`:
    - Thêm nút công cụ **Select Tool (↖)** (tag `ToolTypeSelect`) ở vị trí đầu tiên của cụm công cụ vẽ.
    - Vẽ icon vector con trỏ chuột ↖ sắc nét cho nút Select.
    - Đặt tooltip `Select & Move (V)`.
  - Trong `EditorWindowController.m`:
    - Phím tắt `V`: Chuyển nhanh sang công cụ Select (`toolbarDidSelectTool:ToolTypeSelect`).
    - Phím `Delete` / `Backspace` (Keycode 51): Xóa shape đang chọn thông qua `[self.canvasView deleteSelectedShape]`.
    - Phím mũi tên `← → ↑ ↓` (Keycodes 123, 124, 125, 126): Dịch chuyển shape đang chọn 1px (hoặc 10px nếu giữ `Shift`).
- **Verify**: Chạy `make clean && make build` tạo `QuickSnag.app`.

### Bước 4: Kiểm tra Nghiệm thu (Verification & End-to-End)
- **Files**: Không sửa file, chạy ứng dụng thực tế.
- **Change**:
  1. Khởi chạy `QuickSnag.app`.
  2. Vẽ 1 hình chữ nhật, 1 mũi tên, 1 số step badge (1), 1 dòng chữ.
  3. Bấm phím `V` (hoặc click icon ↖): Click vào hình chữ nhật -> Viền chọn màu xanh xuất hiện.
  4. Kéo chuột di chuyển hình chữ nhật đến vị trí khác -> Hình di chuyển mượt mà.
  5. Nhấn `Cmd+Z` -> Hình quay lại vị trí ban đầu.
  6. Chọn dòng chữ, nhấn phím `Delete` -> Chữ bị xóa khỏi canvas.
  7. Nhấn `Enter` để copy vào Clipboard -> Paste ảnh vào Preview/browser, xác nhận ảnh sạch đẹp 100%, không bị dính bất kỳ viền chọn nét đứt nào.

## Risks & mitigations
- **Rủi ro misclick khi vẽ hình con bên trong khung lớn**:
  - *Giải pháp*: Hit-testing cho Rect và Circle chỉ bắt các điểm nằm sát đường viền (biên +/- 6px), click vào lòng khung rỗng sẽ không bị tính là chọn khung, cho phép người dùng thoải mái vẽ hình con bên trong.
- **Rủi ro ảnh xuất dính viền chọn**:
  - *Giải pháp*: Biến cờ `isRenderingForExport` được bật khi vào `renderComposedImage`, đảm bảo AppKit bỏ qua toàn bộ layer selection overlay khi vẽ vào bitmap xuất ra.

## Rollback plan
Nếu phát sinh lỗi hoặc không đúng ý, hoàn tác toàn bộ nhánh qua lệnh:
```bash
git checkout Sources/Models.h Sources/Models.m Sources/CanvasView.h Sources/CanvasView.m Sources/ToolbarView.m Sources/EditorWindowController.m
make clean && make build
```
