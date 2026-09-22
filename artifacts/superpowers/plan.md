# Mini-Plan: Fix Windows CI Build Failure (Missing icon.ico)

## Goal
Fix the GitHub Actions CI build error CS7064 caused by `<ApplicationIcon>icon.ico</ApplicationIcon>` in `QuickSnag.csproj` when `icon.ico` does not exist on disk, and trigger a successful release build.

## Root Cause
In `windows/QuickSnag.csproj`, line 9 specifies `<ApplicationIcon>icon.ico</ApplicationIcon>`. During `dotnet publish`, CSC fails with `CS7064: Error opening icon file ... Could not find file '.../windows/icon.ico'`.

## Steps
1. Edit `windows/QuickSnag.csproj` and `native-snag-win/QuickSnag.csproj`: Remove the `<ApplicationIcon>icon.ico</ApplicationIcon>` line so .NET uses standard default executable icon.
2. Commit the change with message `fix(windows): remove missing icon.ico reference to resolve CI build`.
3. Push to `origin main`.
4. Delete failed remote tag `v1.0.1` or tag `v1.0.2` and push to trigger GitHub Actions release workflow.
5. Verification: Monitor GitHub Actions run to verify `build-windows` and `build-macos` pass and assets are attached to GitHub Release.
