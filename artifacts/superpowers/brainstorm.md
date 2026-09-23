# Brainstorm: Tính Năng Di Chuyển & Lựa Chọn Annotation Đã Vẽ Trên QuickSnag

## Goal
Cho phép người dùng lựa chọn (Select) và di chuyển (Move / Drag & Drop) các đối tượng chú thích đã vẽ trên ảnh (Mũi tên, Khung chữ nhật, Hình tròn, Số thứ tự Step Badge, Chữ Text, Che mờ Blur, Highlight) đến vị trí mới một cách trực quan, mượt mà và hỗ trợ Undo/Redo.

## Constraints
1. **Kiến trúc Native 100% AppKit/Objective-C trên macOS** (và duy trì logic tương thích trên Windows WPF): Không làm phình bộ nhớ, giữ nguyên tốc độ phản hồi 0ms.
2. **Không cản trở luồng vẽ nhanh (Fast Drawing Flow)**: Người dùng chọn tool nào (Rect, Arrow, Step 1-2-3...) thì vẫn phải vẽ liên tục được, không bị nhầm lẫn giữa việc vẽ mới và di chuyển hình cũ.
3. **Tương thích toàn diện với History (Undo/Redo)**: Hành động di chuyển một hình từ toạ độ A sang B phải được đẩy vào `HistoryManager` để bấm `Cmd+Z` là trả về vị trí cũ.
4. **Độ chính xác khi xuất ảnh (`renderComposedImage`)**: Khung chỉ thị vùng chọn (Selection Outline/Handles) chỉ hiển thị khi tương tác trên màn hình, tuyệt đối không bị in vào ảnh cuối khi nhấn `Enter` copy vào Clipboard.

## Known context
- Hiện tại trong `CanvasView.m`, toàn bộ đối tượng được lưu trong danh sách `NSMutableArray<AnnotationShape *> *shapes`.
- Mỗi `AnnotationShape` lưu toạ độ `startPoint`, `endPoint`, `pointsArray` (đối với Highlight), `stepNumber`, `textString`, `color`, `strokeWidth`...
- Hàm `mouseDown:` hiện tại luôn mặc định coi thao tác là vẽ một hình mới (hoặc đặt Textbox). Chưa có cơ chế Hit-Testing (kiểm tra click chuột trúng hình nào) và chưa có đối tượng `selectedShape`.
- Nếu vẽ sai lệch vị trí một chút, hiện tại người dùng chỉ có cách bấm `Cmd+Z` để xoá rồi vẽ lại từ đầu.

## Risks
1. **Xung đột giữa Vẽ mới và Di chuyển (Ambiguity/Misclick)**:
   - Nếu click vào bên trong một khung hình chữ nhật lớn đang bao quanh chi tiết, nếu hit-testing tính cả phần diện tích bên trong thì người dùng sẽ không thể vẽ thêm mũi tên/text bên trong khung đó mà sẽ bị biến thành kéo khung đi.
   - *Cách giải quyết*: Với Shape rỗng (Rect, Circle), chỉ hit-test theo đường viền (stroke border trong phạm vi +/- 6px), không hit-test vùng rỗng bên trong. Với Text, Badge, Blur thì hit-test theo toàn bộ khung bounding box.
2. **Hit-testing đối với đường thẳng / mũi tên xiên**: Cần công thức khoảng cách từ điểm click $(x_0, y_0)$ đến đoạn thẳng $(x_1, y_1) \to (x_2, y_2)$ để nhận diện click chính xác trong phạm vi vài pixel.
3. **Cập nhật toạ độ dạng phức hợp**: Đối với Highlight (`pointsArray`), khi di chuyển cần tịnh tiến toàn bộ danh sách điểm theo độ lệch $(\Delta x, \Delta y)$.

## Options (2–4)

### Option 1: Bổ sung công cụ "Select / Move" (Con trỏ ↖) trên Toolbar (Phím tắt `V`)
- Thêm nút công cụ **Select Tool** (icon con trỏ chuột ↖) ở vị trí đầu tiên trên thanh Toolbar (hoặc phím tắt `V` - chuẩn Photoshop/Figma).
- Khi bật tool Select:
  - Click vào hình nào thì chọn hình đó (hiện khung nét đứt hoặc 4 góc bounding box).
  - Giữ chuột kéo rê để di chuyển hình.
  - Bấm phím `Delete` hoặc `Backspace` để xoá hình đó.
  - Dùng các phím mũi tên `↑ ↓ ← →` để căn chỉnh dịch từng pixel.
- Khi ở các công cụ vẽ khác (Mũi tên, Hình chữ nhật...): Luôn luôn vẽ mới 100%, tách bạch hoàn toàn.

### Option 2: Smart Auto-Selection (CleanShot X style - Không cần thêm tool)
- Không thêm nút Select trên Toolbar.
- Mặc định sau khi người dùng vẽ xong một hình, hình đó tự động ở trạng thái được chọn (Selected) với bounding box mờ. Người dùng có thể kéo di chuyển ngay lập tức.
- Khi hover chuột qua các hình đã vẽ, con trỏ chuột tự đổi thành bàn tay di chuyển (`openHandCursor`) nếu rê trúng viền.

### Option 3: Hybrid (Công cụ Select chuyên dụng + Phím tắt thông minh `Cmd` / `Option`)
- Vừa có công cụ **Select Tool (↖)** trên Toolbar (phím tắt `V`) để người dùng chuyển hẳn sang chế độ chỉnh sửa / sắp xếp layout các annotation.
- Vừa hỗ trợ phím tắt nhanh: Khi đang ở bất kỳ công cụ vẽ nào, người dùng có thể giữ phím `Cmd` (hoặc `Ctrl` trên Windows) để tạm thời biến con trỏ thành chế độ Move, click kéo hình bất kỳ mà không cần đổi qua lại tool.
- Hỗ trợ thêm phím `Backspace` / `Delete` để xoá nhanh hình đang chọn.

## Recommendation
Chọn **Option 3 (Hybrid)**:
- Cực kỳ trực quan cho người dùng mới nhờ có icon con trỏ **Select (↖)** rõ ràng trên thanh Toolbar.
- Cực kỳ tiện lợi cho người dùng chuyên nghiệp nhờ phím tắt `V` và phím giữ `Cmd` để di chuyển nhanh.
- Giải quyết trọn vẹn cả 2 nhu cầu cấp thiết: **Di chuyển vị trí (Move)** và **Xóa hình vẽ sai (Delete)** mà không bắt buộc phải Undo toàn bộ.

## Acceptance criteria
1. **Giao diện Toolbar**: Bổ sung icon **Select Tool (↖)** (phím tắt `V`, đặt cạnh nút Mũi tên).
2. **Nhận diện chính xác (Hit-Testing)**: Click trúng viền hoặc thân của bất kỳ annotation nào sẽ chọn được hình đó; hiển thị viền bounding box nét đứt (Accent Color) thể hiện đang Active.
3. **Kéo thả mượt mà (Drag to Move)**: Kéo chuột di chuyển hình đến vị trí mới; toạ độ cập nhật trơn tru real-time theo chuột.
4. **Phím tắt hỗ trợ**:
   - `Backspace` / `Delete`: Xoá shape đang chọn.
   - `↑ ↓ ← →`: Dịch chuyển shape từng 1px (hoặc 10px khi giữ `Shift`).
   - Giữ `Cmd`: Tạm thời chuyển sang chế độ Move ngay cả khi đang chọn tool vẽ khác.
5. **Hỗ trợ Undo/Redo**: Nhấn `Cmd+Z` hoàn tác thao tác di chuyển về vị trí trước đó.
6. **Đóng gói & Xuất ảnh**: Khung selection chỉ là UI tạm thời, không in vào ảnh cuối khi copy vào Clipboard (`Enter`) hoặc Save file.
