#import "MenuBarController.h"

@interface MenuBarController ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenu *contextMenu;
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
    self.statusItem.button.toolTip = @"QuickSnag - Screen Capture & Annotator\nLeft-click: Capture | Right-click: Menu";
    self.statusItem.button.target = self;
    self.statusItem.button.action = @selector(onStatusItemClicked:);
    [self.statusItem.button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];
    
    [self updateMenu];
}

- (void)onStatusItemClicked:(id)sender {
    NSEvent *event = [NSApp currentEvent];
    if (event.type == NSEventTypeRightMouseUp || (event.modifierFlags & NSEventModifierFlagControl)) {
        // Right click: pop up context menu with Quit option
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.statusItem popUpStatusItemMenu:self.contextMenu];
#pragma clang diagnostic pop
    } else {
        // Left click: instant interactive screenshot capture
        [self.delegate menuBarDidRequestCapture];
    }
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
    
    self.contextMenu = menu;
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
