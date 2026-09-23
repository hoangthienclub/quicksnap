# Mini-Plan: Remove QuickSnag from macOS Dock (NSApplicationActivationPolicyAccessory)

## Root Cause
In `native-snag/Sources/main.m`, line 7 explicitly calls:
`[app setActivationPolicy:NSApplicationActivationPolicyRegular];`
This overrides `LSUIElement` in `Info.plist` and forces macOS to show QuickSnag on the Dock with a running dot indicator.

## Solution
1. Change `NSApplicationActivationPolicyRegular` to `NSApplicationActivationPolicyAccessory` in `native-snag/Sources/main.m`.
2. Terminate any running instance of QuickSnag (`killall QuickSnag`).
3. Rebuild `QuickSnag.app` using `make clean && make build`.
4. Verification: Run `QuickSnag.app`, confirm it only appears in the menu bar tray and NEVER appears on the macOS Dock.
