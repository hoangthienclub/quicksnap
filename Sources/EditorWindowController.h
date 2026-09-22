#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EditorWindowDelegate <NSObject>
- (void)editorDidRequestCaptureNew;
@end

@interface EditorWindowController : NSWindowController

@property (nonatomic, weak, nullable) id<EditorWindowDelegate> delegate;

- (void)showWithImage:(NSImage *)image;
- (void)copyToClipboardAndClose;
- (void)saveToFile;

@end

NS_ASSUME_NONNULL_END
