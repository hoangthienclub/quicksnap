#import <Cocoa/Cocoa.h>

@interface ClipboardWatcher : NSObject

@property (nonatomic, assign) BOOL enabled;

- (instancetype)initWithImageDetectedHandler:(void (^)(NSImage *image))handler;
- (void)start;
- (void)stop;
- (void)markCurrentHandled;

@end
