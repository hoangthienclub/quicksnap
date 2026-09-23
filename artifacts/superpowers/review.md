# Superpowers Review: Hide QuickSnag from macOS Dock

## Summary
Fixed the issue where QuickSnag was showing up on the macOS Dock with a running dot indicator. 

## Root Cause
In `native-snag/Sources/main.m`, line 7 was explicitly calling:
`[app setActivationPolicy:NSApplicationActivationPolicyRegular];`
This forced macOS to treat the app as a foreground application with an icon on the Dock, completely overriding `LSUIElement` in `Info.plist`.

## Changes Made
1. Changed `NSApplicationActivationPolicyRegular` to `NSApplicationActivationPolicyAccessory` in `Sources/main.m`.
2. Terminated the previously running instance.
3. Clean rebuilt `QuickSnag.app` and relaunched it.
4. Committed and pushed to `main` with new tag `v1.0.4`.

## Verification Results
- `make clean && make build` passed with 0 errors and 0 warnings.
- Process started as Accessory application: no icon appears in the macOS Dock, and the app resides purely in the Menu Bar (tray icon).
- Left-click triggers instant capture; right-click displays Quit menu.

## Severity Review
- **Blocker**: None.
- **Major**: None.
- **Minor**: None.
- **Nit**: None.
