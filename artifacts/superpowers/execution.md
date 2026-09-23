# Superpowers Execution Log: Select & Move Annotations

## Step 1: Extend AnnotationShape Models
- **Files changed**:
  - `Sources/Models.h`
  - `Sources/Models.m`
- **What changed**:
  - Added `ToolTypeSelect = 0` to `ToolType` enumeration.
  - Implemented `boundingRect` for all annotation types (Rect, Circle, Step, Text, Arrow, Blur, Highlight).
  - Implemented smart `hitTestPoint:tolerance:` (perimeter stroke detection for Rect/Circle, segment distance for Arrow/Highlight, bounding rect for Text/Blur/Badge).
  - Implemented `translateByDx:dy:` to translate `startPoint`, `endPoint`, and full `pointsArray` for multi-point annotations.
- **Verification command**: `clang ... -c Sources/Models.m`
- **Result**: PASS (0 errors, 0 warnings).

## Step 2: Implement Selection, Drag-to-Move, and Overlay in CanvasView
- **Files changed**:
  - `Sources/CanvasView.h`
  - `Sources/CanvasView.m`
- **What changed**:
  - Added `selectedShape` property and `isRenderingForExport` flag.
  - Implemented `findShapeAtPoint:` to hit-test existing shapes from top to bottom.
  - Implemented `deleteSelectedShape`, `nudgeSelectedShapeByDx:dy:`, and `clearSelection`.
  - Updated `mouseDown:`, `mouseDragged:`, and `mouseUp:` to support clicking to select and dragging to reposition shapes.
  - Updated `drawRect:` to render dashed cyan bounding box with corner handles around the active selection (suppressed during export).
  - Hooked state changes to `HistoryManager` so all move and delete operations support Undo/Redo (`Cmd+Z`).
- **Verification command**: `make build`
- **Result**: PASS.

## Step 3: Add Select Tool to ToolbarView & Shortcuts to EditorWindowController
- **Files changed**:
  - `Sources/ToolbarView.m`
  - `Sources/EditorWindowController.m`
  - `windows/MainWindow.xaml`
  - `windows/MainWindow.xaml.cs`
- **What changed**:
  - Added Select tool button `↖` (`ToolTypeSelect`) as the first tool on `ToolbarView` with tooltip `Select & Move (V)`.
  - Added keyboard shortcut `V` to switch to Select tool.
  - Added `Delete` / `Backspace` shortcut to delete selected annotation.
  - Added Arrow keys `↑ ↓ ← →` to nudge selected shape by 1px (or 10px with `Shift`).
  - Added holding `Cmd` key to temporarily allow move mode even when another drawing tool is active.
  - Added parity updates to Windows WPF project (`windows/` and `native-snag-win/`).
- **Verification command**: `make clean && make build`
- **Result**: PASS (0 errors, 0 warnings).

## Step 4: Verification and Re-packaging
- **Files changed**:
  - `QuickSnag.app`
  - `release/QuickSnag-macOS-arm64.zip`
- **What changed**:
  - Recompiled and signed `QuickSnag.app`.
  - Re-packaged zip archive.
  - Relaunched running process (PID 84021).
- **Verification command**: `make clean && make build && pgrep -fl QuickSnag`
- **Result**: PASS.
