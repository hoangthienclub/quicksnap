# Mini-Plan: Fix Glaring Contrast on Copy Button

## Root Cause
In `native-snag/Sources/ToolbarView.m`, lines 197-206:
`self.clipboardButton.bezelStyle = NSBezelStyleRounded;`
In macOS dark mode, `NSBezelStyleRounded` draws a glossy, bright reflective gradient bezel over the custom `layer.backgroundColor`, washing out the white text and creating an aggressive glare ("chói không thấy").

## Steps
1. In `Sources/ToolbarView.m`:
   - Set `self.clipboardButton.bordered = NO;` to eliminate the glaring macOS native bezel.
   - Use a balanced, high-contrast background color (macOS System Accent Blue `[NSColor colorWithCalibratedRed:0.14 green:0.48 blue:0.95 alpha:1.0]` or Deep Emerald `[NSColor colorWithCalibratedRed:0.08 green:0.55 blue:0.35 alpha:1.0]`) with subtle rounded corner radius (6px) and 1px border.
   - Apply `attributedTitle` with crisp white bold text (`NSForegroundColorAttributeName: [NSColor whiteColor]`) and centered alignment to ensure 100% legibility on dark theme.
2. In Windows `MainWindow.xaml`: Ensure background uses a calm, clear accent tone (`#059669` or `#2563EB`) with high contrast text.
3. Rebuild `QuickSnag.app` via `make clean && make build`.
4. Verification: Inspect button appearance in toolbar, verify text "📋 Copy ↵" is crisp and sharp with zero glare.
