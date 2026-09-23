# Superpowers Review Pass: Fix Glare on Copy Button

## Summary
Fixed the glaring/unreadable Copy button issue on the floating HUD toolbar.

## Root Cause
The button previously used `NSBezelStyleRounded`, which draws an Apple native glossy silver gradient bezel over the background color in macOS dark mode. This gradient overlay produced a bright white/reflective glare, completely washing out the white text `📋 Copy ↵`.

## Changes Made
1. Set `self.clipboardButton.bordered = NO` in `ToolbarView.m` to eliminate the reflective gradient bezel entirely.
2. Switched to a flat, elegant macOS system accent background (`#1F6BDB` Royal Blue) with a subtle border (`rgba(255,255,255,0.18)`), perfectly harmonizing with the dark theme (`#0F172A`).
3. Applied `attributedTitle` with centered, bold 11.5pt white text for maximum legibility and zero glare.
4. Clean compiled `QuickSnag.app` and relaunched the process.
5. Pushed release tag `v1.0.5` to GitHub.

## Severity Review
- **Blocker**: None.
- **Major**: None.
- **Minor**: None.
- **Nit**: None.
