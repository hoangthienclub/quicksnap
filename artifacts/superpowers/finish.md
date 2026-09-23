# Superpowers Finish: Toolbar Fix, Select Icon, Shape Resizing & Dual Windows Releases

## Summary of Changes
1. **Toolbar Layout & Width Fix**:
   - Expanded `[ToolbarView recommendedWidth]` to 888px.
   - Enclosed all 8 drawing/select tools, color palette, stroke widths, undo/redo, capture/save, Copy button, and Close button with clean ~12-17px margins on both left and right edges.
   - Solved the visual overlap and right-edge spillover seen in user screenshots.

2. **Distinctive Cursor Pointer for Select Tool**:
   - Replaced ambiguous `↖` character with native Apple cursor pointer (`cursorarrow` SF Symbol on macOS 11+, with high-res vector fallback).
   - Replaced `↖` with `🎯 Select` on Windows WPF to avoid confusion with drawing arrow `↗`.

3. **Interactive Shape Resizing / Scaling**:
   - Implemented `ShapeResizeHandle` and hit-testing in `AnnotationShape` for 4 corner handles and arrow endpoints.
   - Added interactive dragging in `CanvasView.m` (`mouseDown:`, `mouseDragged:`, `mouseUp:`) supporting smooth enlargement, shrinking, and reorientation.
   - Added crosshair cursor updates over resize handles via `resetCursorRects`.
   - Undo/Redo (`Cmd+Z`) records shape state before resizing.
   - Selection outline and handles are omitted during export/copy.
   - Implemented corner-drag resizing parity for Windows in `MainWindow.xaml.cs`.

4. **Dual Windows Packages in CI/CD**:
   - Configured `.github/workflows/release.yml` to publish both:
     - `QuickSnag-Windows-Standalone.zip` (~65 MB, standalone portable).
     - `QuickSnag-Windows-Lightweight.zip` (~300 KB, requires .NET 8 Desktop Runtime).
     - `QuickSnag-Windows-x64.zip` (legacy alias).
     - `QuickSnag-macOS-arm64.zip` (~1.1 MB).
   - Pushed tag `v1.0.7` to trigger automated GitHub Release.

## Verification Commands & Results
- macOS Build: `make clean && make build` -> `✓ Successfully built and signed QuickSnag.app` (0 warnings, 0 errors).
- macOS Zip: `release/QuickSnag-macOS-arm64.zip` created (1.1 MB).
- App process: Successfully relaunched (PID active).
- GitHub Push: Tag `v1.0.7` successfully pushed to `hoangthienclub/quicksnap`.

## Manual Validation Steps
1. Click menu bar icon or press `Cmd+Shift+S` to capture.
2. Check top floating toolbar: Notice the Copy button and Close button fit completely inside the dark container with comfortable padding.
3. Check the first tool icon: It is now a distinct mouse cursor pointer, not an arrow.
4. Draw a rectangle, circle, or arrow.
5. Click on it to select it: Notice the 8px white/blue circular handle dots at the corners (or endpoints).
6. Drag a corner handle: The shape smoothly expands or shrinks in real-time.
7. Press `Cmd+Z`: The shape returns to its previous size before the resize drag.
8. Press `Enter`: The composed image is copied without any handle dots or bounding lines.
