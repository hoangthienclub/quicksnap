#import "ToolbarView.h"

@interface ToolbarView ()

@property (nonatomic, strong) NSMutableArray<NSButton *> *toolButtons;
@property (nonatomic, strong) NSMutableArray<NSButton *> *colorButtons;
@property (nonatomic, strong) NSMutableArray<NSButton *> *widthButtons;
@property (nonatomic, strong) NSButton *undoButton;
@property (nonatomic, strong) NSButton *redoButton;
@property (nonatomic, strong) NSButton *clipboardButton;
@property (nonatomic, strong) NSButton *saveButton;
@property (nonatomic, strong) NSButton *captureButton;
@property (nonatomic, strong) NSButton *closeButton;

@end

@implementation ToolbarView

+ (CGFloat)recommendedWidth {
    return 888.0;
}

+ (CGFloat)recommendedHeight {
    return 42.0;
}

+ (NSImage *)selectCursorIcon {
    NSImage *img = nil;
    if (@available(macOS 11.0, *)) {
        img = [NSImage imageWithSystemSymbolName:@"cursorarrow" accessibilityDescription:@"Select & Resize"];
    }
    if (!img) {
        img = [NSImage imageWithSize:NSMakeSize(16, 16) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
            NSBezierPath *p = [NSBezierPath bezierPath];
            [p moveToPoint:NSMakePoint(2.5, 14.5)];
            [p lineToPoint:NSMakePoint(2.5, 2.5)];
            [p lineToPoint:NSMakePoint(6.5, 6.5)];
            [p lineToPoint:NSMakePoint(9.5, 1.5)];
            [p lineToPoint:NSMakePoint(11.5, 2.7)];
            [p lineToPoint:NSMakePoint(8.5, 7.8)];
            [p lineToPoint:NSMakePoint(13.5, 7.8)];
            [p closePath];
            [[NSColor whiteColor] setFill];
            [p fill];
            [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] setStroke];
            p.lineWidth = 1.0;
            [p stroke];
            return YES;
        }];
    }
    img.template = YES;
    return img;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.material = NSVisualEffectMaterialHUDWindow;
        self.blendingMode = NSVisualEffectBlendingModeWithinWindow;
        self.state = NSVisualEffectStateActive;
        self.wantsLayer = YES;
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [NSColor colorWithWhite:1.0 alpha:0.18].CGColor;
        
        // Subtle drop shadow under the floating bar
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = [NSColor colorWithWhite:0 alpha:0.4];
        shadow.shadowBlurRadius = 12.0;
        shadow.shadowOffset = NSMakeSize(0, -3);
        self.shadow = shadow;
        
        _toolButtons = [NSMutableArray array];
        _colorButtons = [NSMutableArray array];
        _widthButtons = [NSMutableArray array];
        
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    CGFloat x = 10.0;
    CGFloat y = 7.0;
    CGFloat btnH = 28.0;

    // Logo / Title
    NSTextField *title = [[NSTextField alloc] initWithFrame:NSMakeRect(x, y + 3, 72, 22)];
    title.stringValue = @"QuickSnag";
    title.font = [NSFont boldSystemFontOfSize:12];
    title.textColor = [NSColor colorWithCalibratedRed:0.22 green:0.74 blue:0.98 alpha:1.0];
    title.editable = NO;
    title.selectable = NO;
    title.bezeled = NO;
    title.drawsBackground = NO;
    [self addSubview:title];
    x += 74;

    [self addSeparatorAt:x];
    x += 9;

    // Tool Buttons (compact icons + tooltips)
    NSArray *tools = @[
        @{@"icon": @"", @"tip": @"Select, Move & Resize (V)", @"tool": @(ToolTypeSelect), @"w": @30},
        @{@"icon": @"↗", @"tip": @"Arrow (A)", @"tool": @(ToolTypeArrow), @"w": @30},
        @{@"icon": @"▭", @"tip": @"Rectangle (R)", @"tool": @(ToolTypeRect), @"w": @30},
        @{@"icon": @"◯", @"tip": @"Circle / Oval (C)", @"tool": @(ToolTypeCircle), @"w": @30},
        @{@"icon": @"①", @"tip": @"Step Badge (S)", @"tool": @(ToolTypeStepBadge), @"w": @34},
        @{@"icon": @"T", @"tip": @"Transparent Text (T)", @"tool": @(ToolTypeText), @"w": @28},
        @{@"icon": @"▨", @"tip": @"Blur / Pixelate (B)", @"tool": @(ToolTypeBlur), @"w": @30},
        @{@"icon": @"🖍", @"tip": @"Highlighter (H)", @"tool": @(ToolTypeHighlight), @"w": @30}
    ];

    for (NSDictionary *dict in tools) {
        ToolType t = [dict[@"tool"] integerValue];
        CGFloat w = [dict[@"w"] doubleValue];
        NSButton *btn = nil;
        if (t == ToolTypeSelect) {
            btn = [NSButton buttonWithTitle:@"" target:self action:@selector(onToolClick:)];
            btn.image = [ToolbarView selectCursorIcon];
            btn.imagePosition = NSImageOnly;
            btn.imageScaling = NSImageScaleProportionallyDown;
        } else {
            btn = [NSButton buttonWithTitle:dict[@"icon"] target:self action:@selector(onToolClick:)];
            btn.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
        }
        btn.frame = NSMakeRect(x, y, w, btnH);
        btn.bezelStyle = NSBezelStyleRecessed;
        btn.tag = t;
        btn.toolTip = dict[@"tip"];
        btn.wantsLayer = YES;
        btn.layer.cornerRadius = 5;
        [self addSubview:btn];
        [self.toolButtons addObject:btn];
        x += w + 2;
    }

    [self addSeparatorAt:x];
    x += 9;

    // Color Palette (16x16 circular buttons)
    NSArray *colors = @[
        [NSColor systemRedColor],
        [NSColor systemOrangeColor],
        [NSColor systemYellowColor],
        [NSColor systemGreenColor],
        [NSColor systemBlueColor],
        [NSColor systemPurpleColor],
        [NSColor whiteColor],
        [NSColor blackColor]
    ];

    for (NSColor *c in colors) {
        NSButton *btn = [NSButton buttonWithTitle:@"" target:self action:@selector(onColorClick:)];
        btn.frame = NSMakeRect(x, y + 5, 17, 17);
        btn.bezelStyle = NSBezelStyleCircular;
        btn.wantsLayer = YES;
        btn.layer.backgroundColor = c.CGColor;
        btn.layer.cornerRadius = 8.5;
        btn.layer.borderWidth = 1.0;
        btn.layer.borderColor = [NSColor colorWithWhite:1.0 alpha:0.4].CGColor;
        [self addSubview:btn];
        [self.colorButtons addObject:btn];
        x += 20;
    }

    [self addSeparatorAt:x];
    x += 9;

    // Stroke width buttons (compact)
    NSArray *widths = @[@{@"w": @2.0, @"label": @"2p"},
                        @{@"w": @4.0, @"label": @"4p"},
                        @{@"w": @8.0, @"label": @"8p"}];
    for (NSDictionary *wDict in widths) {
        NSNumber *val = wDict[@"w"];
        NSButton *btn = [NSButton buttonWithTitle:wDict[@"label"]
                                           target:self
                                           action:@selector(onStrokeClick:)];
        btn.frame = NSMakeRect(x, y, 26, btnH);
        btn.bezelStyle = NSBezelStyleRecessed;
        btn.tag = [val integerValue];
        btn.toolTip = [NSString stringWithFormat:@"Stroke %@px", val];
        btn.font = [NSFont systemFontOfSize:10];
        btn.wantsLayer = YES;
        btn.layer.cornerRadius = 4;
        [self addSubview:btn];
        [self.widthButtons addObject:btn];
        x += 28;
    }

    [self addSeparatorAt:x];
    x += 9;

    // Undo / Redo (compact icons)
    self.undoButton = [NSButton buttonWithTitle:@"↩" target:self action:@selector(onUndoClick:)];
    self.undoButton.frame = NSMakeRect(x, y, 26, btnH);
    self.undoButton.bezelStyle = NSBezelStyleRecessed;
    self.undoButton.toolTip = @"Undo (Cmd+Z)";
    self.undoButton.font = [NSFont systemFontOfSize:13];
    [self addSubview:self.undoButton];
    x += 28;

    self.redoButton = [NSButton buttonWithTitle:@"↪" target:self action:@selector(onRedoClick:)];
    self.redoButton.frame = NSMakeRect(x, y, 26, btnH);
    self.redoButton.bezelStyle = NSBezelStyleRecessed;
    self.redoButton.toolTip = @"Redo (Cmd+Shift+Z)";
    self.redoButton.font = [NSFont systemFontOfSize:13];
    [self addSubview:self.redoButton];
    x += 30;

    [self addSeparatorAt:x];
    x += 9;

    // Capture New
    self.captureButton = [NSButton buttonWithTitle:@"📷" target:self action:@selector(onCaptureClick:)];
    self.captureButton.frame = NSMakeRect(x, y, 28, btnH);
    self.captureButton.bezelStyle = NSBezelStyleRecessed;
    self.captureButton.toolTip = @"Capture New Area";
    self.captureButton.font = [NSFont systemFontOfSize:13];
    [self addSubview:self.captureButton];
    x += 30;

    // Save
    self.saveButton = [NSButton buttonWithTitle:@"💾" target:self action:@selector(onSaveClick:)];
    self.saveButton.frame = NSMakeRect(x, y, 28, btnH);
    self.saveButton.bezelStyle = NSBezelStyleRecessed;
    self.saveButton.toolTip = @"Save Image (Cmd+S)";
    self.saveButton.font = [NSFont systemFontOfSize:13];
    [self addSubview:self.saveButton];
    x += 32;

    // Clean Modern Copy Button (flat, high contrast, zero glare)
    self.clipboardButton = [[NSButton alloc] initWithFrame:NSMakeRect(x, y, 92, btnH)];
    self.clipboardButton.target = self;
    self.clipboardButton.action = @selector(onCopyClick:);
    self.clipboardButton.bordered = NO;
    self.clipboardButton.toolTip = @"Copy to Clipboard & Close (Enter / Cmd+C)";
    self.clipboardButton.wantsLayer = YES;
    self.clipboardButton.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.12 green:0.42 blue:0.86 alpha:1.0].CGColor;
    self.clipboardButton.layer.cornerRadius = 6;
    self.clipboardButton.layer.borderWidth = 1.0;
    self.clipboardButton.layer.borderColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.18].CGColor;

    NSMutableParagraphStyle *copyParaStyle = [[NSMutableParagraphStyle alloc] init];
    copyParaStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *copyAttrStr = [[NSAttributedString alloc] initWithString:@"📋 Copy ↵" attributes:@{
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSFontAttributeName: [NSFont boldSystemFontOfSize:11.5],
        NSParagraphStyleAttributeName: copyParaStyle
    }];
    self.clipboardButton.attributedTitle = copyAttrStr;
    [self addSubview:self.clipboardButton];
    x += 96;

    // Close Button
    self.closeButton = [NSButton buttonWithTitle:@"✕" target:self action:@selector(onCloseClick:)];
    self.closeButton.frame = NSMakeRect(x, y, 24, btnH);
    self.closeButton.bezelStyle = NSBezelStyleRecessed;
    self.closeButton.toolTip = @"Close Window (Esc)";
    self.closeButton.font = [NSFont boldSystemFontOfSize:12];
    self.closeButton.contentTintColor = [NSColor systemRedColor];
    [self addSubview:self.closeButton];

    [self setSelectedTool:ToolTypeArrow];
    [self setSelectedStrokeWidth:4.0];
}

- (void)addSeparatorAt:(CGFloat)x {
    NSBox *sep = [[NSBox alloc] initWithFrame:NSMakeRect(x, 10, 1, 22)];
    sep.boxType = NSBoxSeparator;
    [self addSubview:sep];
}

- (void)onToolClick:(NSButton *)sender {
    ToolType tool = (ToolType)sender.tag;
    [self setSelectedTool:tool];
    [self.delegate toolbarDidSelectTool:tool];
}

- (void)onColorClick:(NSButton *)sender {
    NSColor *color = [NSColor colorWithCGColor:sender.layer.backgroundColor];
    [self setSelectedColor:color];
    [self.delegate toolbarDidSelectColor:color];
}

- (void)onStrokeClick:(NSButton *)sender {
    CGFloat w = (CGFloat)sender.tag;
    [self setSelectedStrokeWidth:w];
    [self.delegate toolbarDidSelectStrokeWidth:w];
}

- (void)onUndoClick:(id)sender {
    [self.delegate toolbarDidClickUndo];
}

- (void)onRedoClick:(id)sender {
    [self.delegate toolbarDidClickRedo];
}

- (void)onCopyClick:(id)sender {
    [self.delegate toolbarDidClickCopy];
}

- (void)onSaveClick:(id)sender {
    [self.delegate toolbarDidClickSave];
}

- (void)onCaptureClick:(id)sender {
    [self.delegate toolbarDidClickCaptureNew];
}

- (void)onCloseClick:(id)sender {
    [self.delegate toolbarDidClickClose];
}

- (void)setSelectedTool:(ToolType)tool {
    for (NSButton *btn in self.toolButtons) {
        BOOL isSelected = (btn.tag == tool);
        btn.state = isSelected ? NSControlStateValueOn : NSControlStateValueOff;
        btn.layer.borderWidth = isSelected ? 1.5 : 0;
        btn.layer.borderColor = [NSColor systemBlueColor].CGColor;
    }
}

- (void)setSelectedColor:(NSColor *)color {
    for (NSButton *btn in self.colorButtons) {
        BOOL matches = CGColorEqualToColor(btn.layer.backgroundColor, color.CGColor);
        btn.layer.borderWidth = matches ? 2.5 : 1.0;
        btn.layer.borderColor = matches ? [NSColor whiteColor].CGColor : [NSColor colorWithWhite:1.0 alpha:0.4].CGColor;
    }
}

- (void)setSelectedStrokeWidth:(CGFloat)width {
    for (NSButton *btn in self.widthButtons) {
        BOOL isSelected = (btn.tag == (NSInteger)width);
        btn.state = isSelected ? NSControlStateValueOn : NSControlStateValueOff;
        btn.layer.borderWidth = isSelected ? 1.5 : 0;
        btn.layer.borderColor = [NSColor systemBlueColor].CGColor;
    }
}

- (void)setCanUndo:(BOOL)canUndo canRedo:(BOOL)canRedo {
    self.undoButton.enabled = canUndo;
    self.redoButton.enabled = canRedo;
}

- (void)updateStepCounter:(NSInteger)count {
    for (NSButton *btn in self.toolButtons) {
        if (btn.tag == ToolTypeStepBadge) {
            btn.title = [NSString stringWithFormat:@"① %ld", (long)count];
            break;
        }
    }
}

@end
