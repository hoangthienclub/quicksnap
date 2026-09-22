#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "===> Compiling Native QuickSnag for macOS Apple Silicon..."
make clean
make build

echo "===> Verifying Code Signature..."
codesign --verify --verbose QuickSnag.app

echo "===> App Bundle Info:"
ls -lh QuickSnag.app/Contents/MacOS/QuickSnag

echo ""
echo "✓ QuickSnag.app successfully packaged and verified!"
echo "  Location: $DIR/QuickSnag.app"
echo "  To launch: open $DIR/QuickSnag.app"
echo "  To install: cp -R $DIR/QuickSnag.app /Applications/"
