#import "MenuBarController.h"

@interface MenuBarController ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@end

@implementation MenuBarController

- (instancetype)initWithDelegate:(id<MenuBarDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        [self setupStatusItem];
    }
    return self;
}

- (void)setupStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    // Create custom vector template icon (18x18)
    NSImage *icon = [NSImage imageWithSize:NSMakeSize(18, 18) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [[NSColor blackColor] setStroke];
        
        // Outer camera body
        NSRect body = NSMakeRect(2, 2, 14, 11);
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:body xRadius:2 yRadius:2];
        path.lineWidth = 1.5;
        [path stroke];
        
        // Lens circle
        NSBezierPath *lens = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(6, 4.5, 6, 6)];
        lens.lineWidth = 1.5;
        [lens stroke];
        
        // Flash bump
        NSBezierPath *bump = [NSBezierPath bezierPathWithRect:NSMakeRect(5, 13, 4, 2)];
        bump.lineWidth = 1.2;
        [bump stroke];
        
        return YES;
    }];
    icon.template = YES;
    
    self.statusItem.button.image = icon;
    self.statusItem.button.toolTip = @"QuickSnag - Screen Capture & Annotator";
    
    [self updateMenu];
}

- (void)updateMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"QuickSnag"];
    
    NSMenuItem *titleItem = [[NSMenuItem alloc] initWithTitle:@"QuickSnag v1.0 (Native)" action:nil keyEquivalent:@""];
    [titleItem setEnabled:NO];
    [menu addItem:titleItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *captureItem = [[NSMenuItem alloc] initWithTitle:@"Capture Screen Area (Cmd+Shift+S)"
                                                         action:@selector(onCaptureClicked:)
                                                  keyEquivalent:@"s"];
    captureItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    captureItem.target = self;
    [menu addItem:captureItem];
    
    NSMenuItem *clipboardItem = [[NSMenuItem alloc] initWithTitle:@"Open from Clipboard (Cmd+V)"
                                                           action:@selector(onOpenClipboardClicked:)
                                                    keyEquivalent:@"v"];
    clipboardItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    clipboardItem.target = self;
    [menu addItem:clipboardItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    BOOL autoOpen = [self.delegate isAutoOpenEnabled];
    NSMenuItem *autoOpenItem = [[NSMenuItem alloc] initWithTitle:@"Auto-open on OS Screenshot"
                                                          action:@selector(onToggleAutoOpenClicked:)
                                                   keyEquivalent:@""];
    autoOpenItem.state = autoOpen ? NSControlStateValueOn : NSControlStateValueOff;
    autoOpenItem.target = self;
    [menu addItem:autoOpenItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit QuickSnag"
                                                      action:@selector(onQuitClicked:)
                                               keyEquivalent:@"q"];
    quitItem.target = self;
    [menu addItem:quitItem];
    
    self.statusItem.menu = menu;
}

- (void)onCaptureClicked:(id)sender {
    [self.delegate menuBarDidRequestCapture];
}

- (void)onOpenClipboardClicked:(id)sender {
    [self.delegate menuBarDidRequestOpenClipboard];
}

- (void)onToggleAutoOpenClicked:(id)sender {
    BOOL current = [self.delegate isAutoOpenEnabled];
    [self.delegate menuBarDidToggleAutoOpen:!current];
    [self updateMenu];
}

- (void)onQuitClicked:(id)sender {
    [NSApp terminate:nil];
}

@end
