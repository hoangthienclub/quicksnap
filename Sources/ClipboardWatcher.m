#import "ClipboardWatcher.h"

@interface ClipboardWatcher ()
@property (nonatomic, copy) void (^handler)(NSImage *image);
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger lastChangeCount;
@end

@implementation ClipboardWatcher

- (instancetype)initWithImageDetectedHandler:(void (^)(NSImage *image))handler {
    self = [super init];
    if (self) {
        _handler = [handler copy];
        _enabled = YES;
        _lastChangeCount = [[NSPasteboard generalPasteboard] changeCount];
    }
    return self;
}

- (void)start {
    if (self.timer) return;
    self.lastChangeCount = [[NSPasteboard generalPasteboard] changeCount];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.8
                                                  target:self
                                                selector:@selector(checkClipboard)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stop {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)markCurrentHandled {
    self.lastChangeCount = [[NSPasteboard generalPasteboard] changeCount];
}

- (void)checkClipboard {
    if (!self.enabled) return;
    
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSInteger currentCount = [pb changeCount];
    
    if (currentCount != self.lastChangeCount) {
        self.lastChangeCount = currentCount;
        
        NSArray *classes = @[[NSImage class]];
        NSDictionary *options = @{};
        if ([pb canReadObjectForClasses:classes options:options]) {
            NSArray *objects = [pb readObjectsForClasses:classes options:options];
            if (objects.count > 0 && [objects.firstObject isKindOfClass:[NSImage class]]) {
                NSImage *image = (NSImage *)objects.firstObject;
                if (image.size.width > 10 && image.size.height > 10) {
                    if (self.handler) {
                        self.handler(image);
                    }
                }
            }
        }
    }
}

@end
