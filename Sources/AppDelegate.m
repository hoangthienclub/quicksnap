#import "AppDelegate.h"
#import "SystemCapture.h"
#import "ClipboardWatcher.h"
#import "EditorWindowController.h"

@interface AppDelegate () <EditorWindowDelegate>
@property (nonatomic, strong) MenuBarController *menuBar;
@property (nonatomic, strong) ClipboardWatcher *clipboardWatcher;
@property (nonatomic, assign) BOOL autoOpenEnabled;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.autoOpenEnabled = YES;
    self.menuBar = [[MenuBarController alloc] initWithDelegate:self];
    
    __weak typeof(self) weakSelf = self;
    self.clipboardWatcher = [[ClipboardWatcher alloc] initWithImageDetectedHandler:^(NSImage *image) {
        if (weakSelf.autoOpenEnabled) {
            [weakSelf openEditorWithImage:image];
        }
    }];
    [self.clipboardWatcher start];
    
    NSLog(@"QuickSnag Native loaded successfully in Menu Bar.");
}

- (void)openEditorWithImage:(NSImage *)image {
    if (!self.editorController) {
        self.editorController = [[EditorWindowController alloc] init];
        self.editorController.delegate = self;
    }
    [self.editorController showWithImage:image];
}

#pragma mark - MenuBarDelegate

- (void)menuBarDidRequestCapture {
    __weak typeof(self) weakSelf = self;
    [SystemCapture captureInteractiveWithCompletion:^(NSImage * _Nullable image) {
        if (image) {
            [weakSelf.clipboardWatcher markCurrentHandled];
            [weakSelf openEditorWithImage:image];
        }
    }];
}

- (void)menuBarDidRequestOpenClipboard {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *classes = @[[NSImage class]];
    if ([pb canReadObjectForClasses:classes options:@{}]) {
        NSArray *objects = [pb readObjectsForClasses:classes options:@{}];
        if (objects.count > 0 && [objects.firstObject isKindOfClass:[NSImage class]]) {
            [self openEditorWithImage:(NSImage *)objects.firstObject];
        }
    }
}

- (void)menuBarDidToggleAutoOpen:(BOOL)enabled {
    self.autoOpenEnabled = enabled;
    self.clipboardWatcher.enabled = enabled;
}

- (BOOL)isAutoOpenEnabled {
    return self.autoOpenEnabled;
}

#pragma mark - EditorWindowDelegate

- (void)editorDidRequestCaptureNew {
    [self.editorController.window close];
    [self menuBarDidRequestCapture];
}

@end
