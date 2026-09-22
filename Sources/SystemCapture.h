#import <Cocoa/Cocoa.h>

@interface SystemCapture : NSObject

+ (void)captureInteractiveWithCompletion:(void (^ _Nullable)(NSImage * _Nullable image))completion;

@end
