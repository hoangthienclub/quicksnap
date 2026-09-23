# Superpowers Review Pass: Toolbar Fix, Select Icon, Shape Resizing & Dual Windows Releases

## Review Pass
- **Correctness**:
  - ToolbarView width expanded to 888px with comfortable padding, eliminating right-edge clipping of Copy and Close buttons.
  - Select button updated to native `cursorarrow` SF Symbol with custom vector fallback (and `🎯 Select` on Windows), eliminating visual confusion with drawing arrows.
  - Shape resizing handles added to 4 corners (and start/end of arrows), allowing smooth scaling and resizing with live cursor feedback.
  - Dual Windows packaging configured in `.github/workflows/release.yml` for Standalone (~65MB) and Lightweight (~300KB).
- **Edge cases**:
  - Handles omitted from composed export/clipboard copy (inherently clean).
  - Inverted dragging normalized with min/max coordinate calculations so shapes never disappear or crash.
  - Undo/Redo (`Cmd+Z`) preserves shape state before resize.
- **Security**: No secrets or credentials in repository.
- **Maintainability**: Clean AppKit / WPF native code adhering to architectural patterns.

## Issues by Severity
- **Blocker**: None
- **Major**: None
- **Minor**: None
- **Nit**: None
