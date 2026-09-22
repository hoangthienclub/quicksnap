#import "SystemCapture.h"

@implementation SystemCapture

+ (void)captureInteractiveWithCompletion:(void (^)(NSImage * _Nullable image))completion {
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"quicksnag_%@.png", [[NSUUID UUID] UUIDString]]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/sbin/screencapture";
        task.arguments = @[@"-i", @"-r", tempFile];
        
        @try {
            [task launch];
            [task waitUntilExit];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSFileManager *fm = [NSFileManager defaultManager];
                if ([fm fileExistsAtPath:tempFile]) {
                    NSImage *image = [[NSImage alloc] initWithContentsOfFile:tempFile];
                    [fm removeItemAtPath:tempFile error:nil];
                    if (completion) {
                        completion(image);
                    }
                } else {
                    if (completion) {
                        completion(nil);
                    }
                }
            });
        } @catch (NSException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil);
                }
            });
        }
    });
}

@end
