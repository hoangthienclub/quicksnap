# Superpowers Plan: Toolbar Overflow Fix, Distinct Select Icon, Shape Resizing & Dual Windows Releases

## Goal
Resolve HUD toolbar overflow, replace the select tool icon with a distinctive cursor pointer, implement interactive shape resizing handles, and configure GitHub Actions to release both Standalone and Lightweight Windows builds.

## Assumptions
- macOS codebase is in `native-snag/Sources/`.
- Windows codebase is in `windows/` and `native-snag-win/`.
- CI/CD release workflow is at `native-snag/.github/workflows/release.yml`.

## Plan

### Step 1: Fix Toolbar Overflow & Resize HUD Window
- **Files**: `native-snag/Sources/ToolbarView.h`, `native-snag/Sources/ToolbarView.m`, `native-snag/Sources/EditorWindowController.m`
- **Change**:
  - Update `[ToolbarView recommendedWidth]` to 885.0px (accurate measurement including all 8 tools, palette, stroke widths, undo/redo, capture/save, copy, and close button with 12px margins).
  - Ensure the toolbar container background and layer bounds enclose all buttons with proper right padding.
- **Verify**: Inspect toolbar visually; buttons no longer exceed or clip at the right edge.

### Step 2: Replace Select Tool Icon with Cursor Pointer
- **Files**: `native-snag/Sources/ToolbarView.m`, `windows/MainWindow.xaml`, `native-snag-win/MainWindow.xaml`
- **Change**:
  - In macOS `ToolbarView.m`: render a crisp native cursor pointer icon (SF Symbol `cursorarrow` on macOS 11+, with custom vector pointer fallback) instead of `↖`.
  - In Windows XAML: replace `↖` with a distinct vector mouse cursor pointer or `🖱 / 🎯` icon to eliminate confusion with the drawing arrow `↗`.
- **Verify**: Select button clearly looks like an arrow pointer / cursor tool, visually differentiated from drawing tools.

### Step 3: Implement Interactive Shape Resize / Scaling
- **Files**: `native-snag/Sources/Models.h`, `native-snag/Sources/Models.m`, `native-snag/Sources/CanvasView.h`, `native-snag/Sources/CanvasView.m`
- **Change**:
  - Define `ResizeHandle` enum (`ResizeHandleNone`, `ResizeHandleTopLeft`, `ResizeHandleTopRight`, `ResizeHandleBottomRight`, `ResizeHandleBottomLeft`, `ResizeHandleArrowStart`, `ResizeHandleArrowEnd`).
  - Add `hitTestHandleAtPoint:tolerance:` to `AnnotationShape` to detect clicks on resize handle dots.
  - Implement `resizeWithHandle:toPoint:anchor:` to update shape boundaries smoothly during drag.
  - In `CanvasView.m`:
    - Track `activeResizeHandle` and `resizeAnchorPoint`.
    - In `mouseDown:`: if clicking a handle on `selectedShape`, initiate resize mode and push undo state.
    - In `mouseDragged:`: if in resize mode, call resize method on `selectedShape` and redraw.
    - In `mouseUp:`: commit resize and notify delegate.
    - Update mouse cursor on hover over handles (`resizeUpDownCursor`, `resizeLeftRightCursor`, or crosshair).
  - Replicate resize handle logic in Windows WPF (`windows/MainWindow.xaml.cs` and `native-snag-win/MainWindow.xaml.cs`).
- **Verify**: Draw a rectangle or circle, click to select, drag a corner handle to enlarge or shrink it. Verify with `Cmd+Z` to undo.

### Step 4: Configure GitHub Release with Dual Windows Packages
- **Files**: `native-snag/.github/workflows/release.yml`
- **Change**:
  - Build Standalone: `dotnet publish windows/QuickSnag.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o win-publish-standalone` -> `QuickSnag-Windows-Standalone.zip` (~65MB).
  - Build Lightweight: `dotnet publish windows/QuickSnag.csproj -c Release -r win-x64 --self-contained false -p:PublishSingleFile=true -o win-publish-lightweight` -> `QuickSnag-Windows-Lightweight.zip` (~300KB).
  - Upload both artifacts and include them in the GitHub release download assets.
  - Update release notes markdown in the workflow.
- **Verify**: Review workflow YAML syntax and verify outputs.

## Risks & Mitigations
- Inverting handles when dragging across opposite side: normalize coordinates so min/max bounds remain positive.
- Keeping export clean: ensure resize handles are omitted when copying to clipboard or saving.

## Rollback Plan
- `git checkout HEAD -- native-snag/` to revert changes if any regression occurs.

## Persist
Artifacts persisted at `artifacts/superpowers/plan.md`.
