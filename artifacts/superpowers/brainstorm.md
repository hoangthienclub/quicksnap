# Superpowers Brainstorm: Toolbar Overflow Fix, Distinct Select Icon, Shape Resize Handles & Dual Windows Releases

## 1. Goal
1. **Fix Toolbar Overflow / Overlap**: Expand and adjust ToolbarView dimensions so that the Copy button and Close button fit completely inside the HUD bar with proper right padding without clipping or spilling over.
2. **Distinct Select Icon**: Replace the `↖` arrow icon (which looks too similar to the drawing arrow tool `↗`) with a dedicated, crisp mouse pointer / cursor vector icon.
3. **Interactive Resize / Scale for Selected Shapes**:
   - Allow users to resize/scale any selected annotation shape (Rect, Circle, Blur, Arrow, Text, Highlight) using interactive corner and endpoint handles.
   - Display resize cursor on hover/drag over handles.
   - Support Undo/Redo when resizing.
4. **Dual Windows Releases in CI/CD**:
   - Update `.github/workflows/release.yml` to build and upload both:
     - `QuickSnag-Windows-Standalone.zip` (~65 MB, `--self-contained true`, no runtime needed).
     - `QuickSnag-Windows-Lightweight.zip` (~300 KB, `--self-contained false`, requires .NET 8 Desktop Runtime).
   - Update release notes on GitHub to clearly explain the difference between the two downloads.

## 2. Constraints
- **100% Native**: macOS implementation in Objective-C / AppKit, Windows in C# .NET 8 WPF.
- Zero external libraries or heavy dependencies.
- Bounding box and resize handles must only be drawn on screen and must NEVER be rendered into exported/copied images.
- Seamless coordinate mapping with `isFlipped = NO` in AppKit.

## 3. Risks & Mitigations
- *Risk*: Inverted dragging when resizing shapes (e.g. dragging top-left handle past bottom-right handle).
  *Mitigation*: Normalize `startPoint` and `endPoint` with min/max or maintain anchor logic so dimensions never become negative or break rendering.
- *Risk*: Arrow resize logic differs from rectangular bounding box resize.
  *Mitigation*: For arrows, provide handles at `startPoint` and `endPoint` directly so the user can grab either end to reorient/resize. For boxes/circles/blur, provide 4 corner handles.
- *Risk*: Windows lightweight build missing prerequisite notice.
  *Mitigation*: Release notes clearly label "Requires .NET 8 Desktop Runtime" with download link.

## 4. Acceptance Criteria
- [x] Toolbar fits all buttons with comfortable padding, zero overflow past the dark rounded container.
- [x] Select button shows a clean cursor / pointer icon, completely distinct from the `↗` arrow drawing tool.
- [x] Clicking on a corner handle of a selected shape allows dragging to scale/resize smoothly.
- [x] Resizing is undoable via `Cmd+Z`.
- [x] GitHub Actions workflow builds both Standalone and Lightweight Windows packages alongside macOS ARM64.
