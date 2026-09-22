APP_NAME = QuickSnag
BUNDLE = $(APP_NAME).app
CC = clang
CFLAGS = -O2 -fobjc-arc -Wall -target arm64-apple-macos14.0
FRAMEWORKS = -framework Cocoa -framework Carbon -framework QuartzCore -framework UniformTypeIdentifiers
SOURCES = $(wildcard Sources/*.m)

all: build

build:
	@mkdir -p build
	$(CC) $(CFLAGS) $(FRAMEWORKS) $(SOURCES) -o build/$(APP_NAME)
	@mkdir -p $(BUNDLE)/Contents/MacOS
	@mkdir -p $(BUNDLE)/Contents/Resources
	@cp build/$(APP_NAME) $(BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Info.plist $(BUNDLE)/Contents/Info.plist
	@if [ -f AppIcon.icns ]; then cp AppIcon.icns $(BUNDLE)/Contents/Resources/; fi
	@codesign --force --deep --sign - $(BUNDLE) 2>/dev/null || true
	@xattr -cr $(BUNDLE) 2>/dev/null || true
	@echo "✓ Successfully built and signed $(BUNDLE)"

clean:
	rm -rf build $(BUNDLE)

run: build
	./$(BUNDLE)/Contents/MacOS/$(APP_NAME)
