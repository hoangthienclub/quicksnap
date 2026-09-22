#import <Cocoa/Cocoa.h>
#import "MenuBarController.h"

@class EditorWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate, MenuBarDelegate>

@property (nonatomic, strong) EditorWindowController *editorController;

- (void)openEditorWithImage:(NSImage *)image;

@end
