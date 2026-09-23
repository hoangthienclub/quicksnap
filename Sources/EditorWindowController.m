#import "EditorWindowController.h"
#import "CanvasView.h"
#import "ToolbarView.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface EditorWindowController () <NSWindowDelegate, ToolbarViewDelegate, CanvasViewDelegate>

@property (nonatomic, strong) CanvasView *canvasView;
@property (nonatomic, strong) ToolbarView *toolbarView;
@property (nonatomic, strong) id keyEventMonitor;

@end

@implementation EditorWindowController

- (instancetype)init {
    NSScreen *screen = [NSScreen mainScreen];
    NSRect screenRect = screen ? screen.visibleFrame : NSMakeRect(0, 0, 1280, 800);
    
    CGFloat w = MIN(1366, screenRect.size.width - 60);
    CGFloat h = MIN(860, screenRect.size.height - 60);
    NSRect windowRect = NSMakeRect((screenRect.size.width - w) / 2.0 + screenRect.origin.x,
                                   (screenRect.size.height - h) / 2.0 + screenRect.origin.y,
                                   w, h);

    NSWindowStyleMask mask = NSWindowStyleMaskTitled |
                             NSWindowStyleMaskClosable |
                             NSWindowStyleMaskMiniaturizable |
                             NSWindowStyleMaskResizable |
                             NSWindowStyleMaskFullSizeContentView;

    NSWindow *win = [[NSWindow alloc] initWithContentRect:windowRect
                                                styleMask:mask
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    win.titlebarAppearsTransparent = YES;
    win.titleVisibility = NSWindowTitleHidden;
    win.backgroundColor = [NSColor colorWithCalibratedRed:0.06 green:0.08 blue:0.12 alpha:1.0];
    win.hasShadow = YES;
    win.movableByWindowBackground = NO;

    self = [super initWithWindow:win];
    if (self) {
        win.delegate = self;
        [self setupSubviews];
        [self setupKeyboardShortcuts];
    }
    return self;
}

- (void)setupSubviews {
    NSView *contentView = self.window.contentView;
    if (!contentView) return;

    // Full area Canvas View
    self.canvasView = [[CanvasView alloc] initWithFrame:contentView.bounds];
    self.canvasView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.canvasView.delegate = self;
    [contentView addSubview:self.canvasView];

    // Floating Top Toolbar View (Centered Island)
    CGFloat toolbarW = [ToolbarView recommendedWidth];
    CGFloat toolbarH = [ToolbarView recommendedHeight];
    CGFloat tbX = MAX(10.0, (contentView.bounds.size.width - toolbarW) / 2.0);
    CGFloat tbY = contentView.bounds.size.height - toolbarH - 12.0;
    NSRect tbRect = NSMakeRect(tbX, tbY, toolbarW, toolbarH);

    self.toolbarView = [[ToolbarView alloc] initWithFrame:tbRect];
    self.toolbarView.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin;
    self.toolbarView.delegate = self;
    [contentView addSubview:self.toolbarView];
}

- (void)setupKeyboardShortcuts {
    __weak typeof(self) weakSelf = self;
    self.keyEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
        if (!weakSelf.window.isKeyWindow) return event;

        // If typing in a text field inside canvas, let it receive the event
        NSResponder *firstResponder = weakSelf.window.firstResponder;
        if ([firstResponder isKindOfClass:[NSText class]] || [firstResponder isKindOfClass:[NSTextField class]]) {
            return event;
        }

        NSEventModifierFlags flags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
        BOOL isCmd = (flags & NSEventModifierFlagCommand) != 0;
        BOOL isShift = (flags & NSEventModifierFlagShift) != 0;

        // Enter or Cmd+C -> Copy & Close
        if (event.keyCode == 36 || (isCmd && [event.charactersIgnoringModifiers isEqualToString:@"c"])) {
            [weakSelf copyToClipboardAndClose];
            return nil;
        }

        // Cmd+S -> Save
        if (isCmd && [event.charactersIgnoringModifiers isEqualToString:@"s"]) {
            [weakSelf saveToFile];
            return nil;
        }

        // Esc -> Close
        if (event.keyCode == 53) {
            [weakSelf.window close];
            return nil;
        }

        // Cmd+Z -> Undo / Cmd+Shift+Z -> Redo
        if (isCmd && !isShift && [event.charactersIgnoringModifiers isEqualToString:@"z"]) {
            [weakSelf.canvasView undo];
            return nil;
        }
        if (isCmd && isShift && [event.charactersIgnoringModifiers isEqualToString:@"z"]) {
            [weakSelf.canvasView redo];
            return nil;
        }

        // Delete or Backspace -> Delete Selected Shape
        if (event.keyCode == 51 || event.keyCode == 117) {
            [weakSelf.canvasView deleteSelectedShape];
            return nil;
        }

        // Arrow Keys -> Nudge Selected Shape (Shift for 10px)
        if (event.keyCode >= 123 && event.keyCode <= 126) {
            CGFloat step = isShift ? 10.0 : 1.0;
            if (event.keyCode == 123) {
                [weakSelf.canvasView nudgeSelectedShapeByDx:-step dy:0];
            } else if (event.keyCode == 124) {
                [weakSelf.canvasView nudgeSelectedShapeByDx:step dy:0];
            } else if (event.keyCode == 125) {
                [weakSelf.canvasView nudgeSelectedShapeByDx:0 dy:-step];
            } else if (event.keyCode == 126) {
                [weakSelf.canvasView nudgeSelectedShapeByDx:0 dy:step];
            }
            return nil;
        }

        // Quick Tool Keys (V, A, R, C, S, T, B, H)
        if (flags == 0) {
            NSString *ch = [event.charactersIgnoringModifiers lowercaseString];
            if ([ch isEqualToString:@"v"]) {
                [weakSelf toolbarDidSelectTool:ToolTypeSelect];
                return nil;
            } else if ([ch isEqualToString:@"a"]) {
                [weakSelf toolbarDidSelectTool:ToolTypeArrow];
                return nil;
            } else if ([ch isEqualToString:@"r"]) {
                [weakSelf toolbarDidSelectTool:ToolTypeRect];
                return nil;
            } else if ([ch isEqualToString:@"c"]) {
                [weakSelf toolbarDidSelectTool:ToolTypeCircle];
                return nil;
            } else if ([ch isEqualToString:@"s"]) {
                [weakSelf toolbarDidSelectTool:ToolTypeStepBadge];
                return nil;
            } else if ([ch isEqualToString:@"t"]) {
                [weakSelf toolbarDidSelectTool:ToolTypeText];
                return nil;
            } else if ([ch isEqualToString:@"b"]) {
                [weakSelf toolbarDidSelectTool:ToolTypeBlur];
                return nil;
            } else if ([ch isEqualToString:@"h"]) {
                [weakSelf toolbarDidSelectTool:ToolTypeHighlight];
                return nil;
            }
        }

        return event;
    }];
}

- (void)showWithImage:(NSImage *)image {
    [self.canvasView loadImage:image];
    [self.toolbarView setCanUndo:NO canRedo:NO];
    [self.toolbarView updateStepCounter:1];

    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)copyToClipboardAndClose {
    NSImage *finalImg = [self.canvasView renderComposedImage];
    if (finalImg) {
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb writeObjects:@[finalImg]];
        NSLog(@"QuickSnag: Successfully copied composed image to clipboard.");
    }
    [self.window close];
}

- (void)saveToFile {
    NSImage *finalImg = [self.canvasView renderComposedImage];
    if (!finalImg) return;

    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.title = @"Save Annotated Screenshot";
    panel.nameFieldStringValue = [NSString stringWithFormat:@"QuickSnag_%@.png",
                                  [[NSISO8601DateFormatter alloc] stringFromDate:[NSDate date]]];
    if (@available(macOS 12.0, *)) {
        panel.allowedContentTypes = @[UTTypePNG, UTTypeJPEG];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        panel.allowedFileTypes = @[@"png", @"jpg"];
#pragma clang diagnostic pop
    }

    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK && panel.URL) {
            CGImageRef cgRef = [finalImg CGImageForProposedRect:NULL context:nil hints:nil];
            if (cgRef) {
                NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
                NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
                [pngData writeToURL:panel.URL atomically:YES];
            }
        }
    }];
}

#pragma mark - ToolbarViewDelegate

- (void)toolbarDidSelectTool:(ToolType)tool {
    self.canvasView.currentTool = tool;
    [self.toolbarView setSelectedTool:tool];
}

- (void)toolbarDidSelectColor:(NSColor *)color {
    self.canvasView.currentColor = color;
}

- (void)toolbarDidSelectStrokeWidth:(CGFloat)width {
    self.canvasView.currentStrokeWidth = width;
}

- (void)toolbarDidClickUndo {
    [self.canvasView undo];
}

- (void)toolbarDidClickRedo {
    [self.canvasView redo];
}

- (void)toolbarDidClickCopy {
    [self copyToClipboardAndClose];
}

- (void)toolbarDidClickSave {
    [self saveToFile];
}

- (void)toolbarDidClickClose {
    [self.window close];
}

- (void)toolbarDidClickCaptureNew {
    [self.delegate editorDidRequestCaptureNew];
}

#pragma mark - CanvasViewDelegate

- (void)canvasDidChangeShapes {
    [self.toolbarView setCanUndo:[self.canvasView canUndo] canRedo:[self.canvasView canRedo]];
    [self.toolbarView updateStepCounter:self.canvasView.stepCounter];
}

- (void)dealloc {
    if (self.keyEventMonitor) {
        [NSEvent removeMonitor:self.keyEventMonitor];
        self.keyEventMonitor = nil;
    }
}

@end
