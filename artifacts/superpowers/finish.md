# Superpowers Finish: Select & Move Annotations

## Summary of Changes
- Added `ToolTypeSelect` and vector pointer icon `↖` to `ToolbarView` (recommended width expanded to 834px).
- Implemented robust geometry methods on `AnnotationShape`:
  - `boundingRect` calculation for all shape types.
  - Smart `hitTestPoint:tolerance:` (perimeter stroke detection for Rect/Circle, segment distance for Arrow/Highlight, bounding rect for Text/Blur/Badge).
  - Multi-point delta translation `translateByDx:dy:`.
- Integrated interactive selection, move dragging, and dashed cyan bounding outline with corner handles in `CanvasView`.
- Added keyboard shortcuts in `EditorWindowController`:
  - `V`: Switch to Select & Move tool.
  - `Delete` / `Backspace`: Remove selected shape.
  - `↑ ↓ ← →`: Nudge selected shape (with `Shift` for 10px steps).
  - Hold `Cmd`: Temporary move mode while using any drawing tool.
- Full Undo/Redo integration (`Cmd+Z`).
- Parity updates to Windows WPF codebase (`windows/` and `native-snag-win/`).

## Verification Commands & Results
- Build command: `make clean && make build`
  - Output: `✓ Successfully built and signed QuickSnag.app` (0 errors, 0 warnings).
- Re-packaged: `zip -r -y release/QuickSnag-macOS-arm64.zip QuickSnag.app`
- Process verified active: PID running in Menu Bar.
- GitHub Release tag pushed: `v1.0.6`.

## Manual Validation Steps
1. Capture any screen area via Menu Bar icon or `Cmd+Shift+S`.
2. Draw a Rectangle and write some Text.
3. Click the `↖` (Select) button or press `V`.
4. Click on the Rectangle to select it (dashed cyan outline appears).
5. Drag to move it to a new location on the image.
6. Press `Cmd+Z` -> shape returns to original location.
7. Press `Delete` -> shape is removed.
8. Press `Enter` -> composed image is copied to clipboard without any selection outline.
