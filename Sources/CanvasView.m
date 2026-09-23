#import "CanvasView.h"

@interface CanvasView () <NSTextFieldDelegate>

@property (nonatomic, strong) NSMutableArray<AnnotationShape *> *shapes;
@property (nonatomic, strong) HistoryManager *history;
@property (nonatomic, assign) BOOL isDrawing;
@property (nonatomic, assign) NSPoint startPoint;
@property (nonatomic, assign) NSPoint currentPoint;
@property (nonatomic, strong) NSMutableArray<NSValue *> *activeHighlightPoints;
@property (nonatomic, strong) NSTextField *activeTextField;
@property (nonatomic, assign) NSPoint textPlacementPoint;
@property (nonatomic, assign) BOOL isDraggingSelectedShape;
@property (nonatomic, assign) NSPoint lastDragLocation;

@property (nonatomic, assign) ShapeResizeHandle activeResizeHandle;
@property (nonatomic, assign) NSPoint resizeAnchorPoint;
@property (nonatomic, assign) NSRect resizeOriginalRect;
@property (nonatomic, strong, nullable) NSArray<NSValue *> *resizeOriginalPoints;
@property (nonatomic, assign) CGFloat resizeOriginalStrokeWidth;

@end

@implementation CanvasView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _shapes = [NSMutableArray array];
        _history = [[HistoryManager alloc] init];
        _currentTool = ToolTypeArrow;
        _currentColor = [NSColor systemRedColor];
        _currentStrokeWidth = 4.0;
        _stepCounter = 1;
        _activeHighlightPoints = [NSMutableArray array];
    }
    return self;
}

- (BOOL)isFlipped {
    return NO;
}

- (void)setSelectedShape:(AnnotationShape *)selectedShape {
    _selectedShape = selectedShape;
    [self.window invalidateCursorRectsForView:self];
    [self setNeedsDisplay:YES];
}

- (void)resetCursorRects {
    [super resetCursorRects];
    if (self.selectedShape) {
        CGFloat hSize = 14.0;
        if (self.selectedShape.type == ToolTypeArrow) {
            NSRect r1 = NSMakeRect(self.selectedShape.startPoint.x - hSize/2.0, self.selectedShape.startPoint.y - hSize/2.0, hSize, hSize);
            NSRect r2 = NSMakeRect(self.selectedShape.endPoint.x - hSize/2.0, self.selectedShape.endPoint.y - hSize/2.0, hSize, hSize);
            [self addCursorRect:r1 cursor:[NSCursor crosshairCursor]];
            [self addCursorRect:r2 cursor:[NSCursor crosshairCursor]];
        } else {
            NSRect r = NSInsetRect([self.selectedShape boundingRect], -4, -4);
            NSRect bl = NSMakeRect(NSMinX(r) - hSize/2.0, NSMinY(r) - hSize/2.0, hSize, hSize);
            NSRect br = NSMakeRect(NSMaxX(r) - hSize/2.0, NSMinY(r) - hSize/2.0, hSize, hSize);
            NSRect tr = NSMakeRect(NSMaxX(r) - hSize/2.0, NSMaxY(r) - hSize/2.0, hSize, hSize);
            NSRect tl = NSMakeRect(NSMinX(r) - hSize/2.0, NSMaxY(r) - hSize/2.0, hSize, hSize);
            [self addCursorRect:bl cursor:[NSCursor crosshairCursor]];
            [self addCursorRect:br cursor:[NSCursor crosshairCursor]];
            [self addCursorRect:tr cursor:[NSCursor crosshairCursor]];
            [self addCursorRect:tl cursor:[NSCursor crosshairCursor]];
        }
    }
}

- (void)loadImage:(NSImage *)image {
    self.baseImage = image;
    [self.shapes removeAllObjects];
    [self.history clear];
    self.stepCounter = 1;
    [self removeActiveTextField];
    [self setNeedsDisplay:YES];
    [self.delegate canvasDidChangeShapes];
}

- (void)undo {
    [self removeActiveTextField];
    NSArray *prev = [self.history undoWithCurrentState:self.shapes];
    if (prev) {
        self.shapes = [prev mutableCopy];
        [self setNeedsDisplay:YES];
        [self.delegate canvasDidChangeShapes];
    }
}

- (void)redo {
    [self removeActiveTextField];
    NSArray *next = [self.history redoWithCurrentState:self.shapes];
    if (next) {
        self.shapes = [next mutableCopy];
        [self setNeedsDisplay:YES];
        [self.delegate canvasDidChangeShapes];
    }
}

- (BOOL)canUndo {
    return [self.history canUndo];
}

- (BOOL)canRedo {
    return [self.history canRedo];
}

- (void)resetStepCounter {
    self.stepCounter = 1;
}

- (void)deleteSelectedShape {
    if (!self.selectedShape) return;
    [self.history pushState:self.shapes];
    [self.shapes removeObject:self.selectedShape];
    self.selectedShape = nil;
    [self.window invalidateCursorRectsForView:self];
    [self setNeedsDisplay:YES];
    [self.delegate canvasDidChangeShapes];
}

- (void)nudgeSelectedShapeByDx:(CGFloat)dx dy:(CGFloat)dy {
    if (!self.selectedShape) return;
    [self.history pushState:self.shapes];
    [self.selectedShape translateByDx:dx dy:dy];
    [self.window invalidateCursorRectsForView:self];
    [self setNeedsDisplay:YES];
    [self.delegate canvasDidChangeShapes];
}

- (void)clearSelection {
    if (self.selectedShape) {
        self.selectedShape = nil;
        [self.window invalidateCursorRectsForView:self];
        [self setNeedsDisplay:YES];
    }
}

- (AnnotationShape * _Nullable)findShapeAtPoint:(NSPoint)point {
    for (AnnotationShape *shape in [self.shapes reverseObjectEnumerator]) {
        if ([shape hitTestPoint:point tolerance:8.0]) {
            return shape;
        }
    }
    return nil;
}

- (void)drawSelectionOverlayForShape:(AnnotationShape *)shape {
    [NSGraphicsContext saveGraphicsState];

    if (shape.type == ToolTypeArrow) {
        // Dashed cyan line between arrow endpoints
        NSBezierPath *guide = [NSBezierPath bezierPath];
        [guide moveToPoint:shape.startPoint];
        [guide lineToPoint:shape.endPoint];
        CGFloat dash[2] = { 4.0, 3.0 };
        [guide setLineDash:dash count:2 phase:0.0];
        guide.lineWidth = 1.2;
        [[NSColor colorWithCalibratedRed:0.22 green:0.74 blue:0.97 alpha:0.7] setStroke];
        [guide stroke];

        // 2 endpoint resize handles (8px)
        CGFloat handleSize = 8.0;
        NSPoint pts[2] = { shape.startPoint, shape.endPoint };
        [[NSColor whiteColor] setFill];
        [[NSColor colorWithCalibratedRed:0.02 green:0.52 blue:0.92 alpha:1.0] setStroke];
        for (int i = 0; i < 2; i++) {
            NSRect hRect = NSMakeRect(pts[i].x - handleSize/2.0, pts[i].y - handleSize/2.0, handleSize, handleSize);
            NSBezierPath *hPath = [NSBezierPath bezierPathWithOvalInRect:hRect];
            [hPath fill];
            hPath.lineWidth = 1.5;
            [hPath stroke];
        }
    } else {
        NSRect r = [shape boundingRect];
        r = NSInsetRect(r, -4, -4);

        // Dashed cyan bounding box
        NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:r xRadius:4 yRadius:4];
        CGFloat dash[2] = { 4.0, 3.0 };
        [border setLineDash:dash count:2 phase:0.0];
        border.lineWidth = 1.5;
        [[NSColor colorWithCalibratedRed:0.22 green:0.74 blue:0.97 alpha:0.95] setStroke];
        [border stroke];

        // Corner handle dots (8px for comfortable grabbing)
        CGFloat handleSize = 8.0;
        NSPoint corners[4] = {
            NSMakePoint(NSMinX(r), NSMinY(r)), // bottom-left
            NSMakePoint(NSMaxX(r), NSMinY(r)), // bottom-right
            NSMakePoint(NSMaxX(r), NSMaxY(r)), // top-right
            NSMakePoint(NSMinX(r), NSMaxY(r))  // top-left
        };
        [[NSColor whiteColor] setFill];
        [[NSColor colorWithCalibratedRed:0.02 green:0.52 blue:0.92 alpha:1.0] setStroke];
        for (int i = 0; i < 4; i++) {
            NSRect hRect = NSMakeRect(corners[i].x - handleSize/2.0, corners[i].y - handleSize/2.0, handleSize, handleSize);
            NSBezierPath *hPath = [NSBezierPath bezierPathWithOvalInRect:hRect];
            [hPath fill];
            hPath.lineWidth = 1.5;
            [hPath stroke];
        }
    }
    [NSGraphicsContext restoreGraphicsState];
}

#pragma mark - Geometry Helpers

- (NSRect)imageDisplayRect {
    if (!self.baseImage) return NSZeroRect;
    NSSize imgSize = self.baseImage.size;
    if (imgSize.width <= 0 || imgSize.height <= 0) return NSZeroRect;

    NSRect bounds = self.bounds;
    CGFloat scale = MIN(bounds.size.width / imgSize.width, bounds.size.height / imgSize.height);
    scale = MIN(scale, 1.0); // Don't upscale past 100%

    NSSize displaySize = NSMakeSize(imgSize.width * scale, imgSize.height * scale);
    CGFloat x = (bounds.size.width - displaySize.width) / 2.0;
    CGFloat y = (bounds.size.height - displaySize.height) / 2.0;
    return NSMakeRect(x, y, displaySize.width, displaySize.height);
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Dark background with subtle grid pattern
    [[NSColor colorWithCalibratedRed:0.06 green:0.08 blue:0.12 alpha:1.0] setFill];
    NSRectFill(self.bounds);

    if (!self.baseImage) return;

    NSRect imgRect = [self imageDisplayRect];

    // Card shadow around image
    NSShadow *cardShadow = [[NSShadow alloc] init];
    cardShadow.shadowColor = [NSColor colorWithWhite:0 alpha:0.6];
    cardShadow.shadowBlurRadius = 24.0;
    cardShadow.shadowOffset = NSMakeSize(0, -6);
    [cardShadow set];

    [[NSColor blackColor] setFill];
    NSRectFill(imgRect);

    [NSGraphicsContext saveGraphicsState];
    [self.baseImage drawInRect:imgRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];

    // Draw Blur/Pixelate shapes first (onto image)
    for (AnnotationShape *shape in self.shapes) {
        if (shape.type == ToolTypeBlur) {
            [self drawBlurShape:shape inRect:imgRect];
        }
    }

    // Draw Vector Annotation Shapes
    for (AnnotationShape *shape in self.shapes) {
        if (shape.type != ToolTypeBlur) {
            [self drawShape:shape inRect:imgRect];
        }
    }

    // Live drawing preview
    if (self.isDrawing) {
        AnnotationShape *preview = [AnnotationShape shapeWithType:self.currentTool
                                                           start:self.startPoint
                                                             end:self.currentPoint
                                                           color:self.currentColor
                                                     strokeWidth:self.currentStrokeWidth];
        if (self.currentTool == ToolTypeHighlight) {
            preview.pointsArray = self.activeHighlightPoints;
        }
    }
    
    // Draw selection highlight overlay if not exporting
    if (self.selectedShape && !self.isRenderingForExport) {
        [self drawSelectionOverlayForShape:self.selectedShape];
    }
}

- (void)drawBlurShape:(AnnotationShape *)shape inRect:(NSRect)imgRect {
    NSRect rawRect = NSMakeRect(MIN(shape.startPoint.x, shape.endPoint.x),
                                MIN(shape.startPoint.y, shape.endPoint.y),
                                fabs(shape.endPoint.x - shape.startPoint.x),
                                fabs(shape.endPoint.y - shape.startPoint.y));
    NSRect target = NSIntersectionRect(rawRect, imgRect);
    if (NSIsEmptyRect(target) || target.size.width < 4 || target.size.height < 4) return;

    [NSGraphicsContext saveGraphicsState];
    NSBezierPath *clip = [NSBezierPath bezierPathWithRoundedRect:target xRadius:4 yRadius:4];
    [clip addClip];

    // Simulate crisp pixelation by sampling average colors across 12x12 grid
    CGFloat blockSize = 10.0;
    for (CGFloat y = target.origin.y; y < NSMaxY(target); y += blockSize) {
        for (CGFloat x = target.origin.x; x < NSMaxX(target); x += blockSize) {
            NSRect blockRect = NSMakeRect(x, y, MIN(blockSize, NSMaxX(target) - x), MIN(blockSize, NSMaxY(target) - y));
            // Semi-frosted blur blocks
            CGFloat hash = sin(x * 12.9898 + y * 78.233) * 43758.5453;
            CGFloat shade = 0.45 + (hash - floor(hash)) * 0.15;
            [[NSColor colorWithWhite:shade alpha:0.9] setFill];
            NSRectFill(blockRect);
        }
    }
    
    [[NSColor colorWithWhite:1.0 alpha:0.3] setStroke];
    clip.lineWidth = 1.0;
    [clip stroke];
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawShape:(AnnotationShape *)shape inRect:(NSRect)imgRect {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [NSColor colorWithWhite:0 alpha:0.45];
    shadow.shadowBlurRadius = 4.0;
    shadow.shadowOffset = NSMakeSize(1, -1);

    switch (shape.type) {
        case ToolTypeSelect:
            break;
        case ToolTypeArrow: {
            [NSGraphicsContext saveGraphicsState];
            [shadow set];
            
            CGFloat dx = shape.endPoint.x - shape.startPoint.x;
            CGFloat dy = shape.endPoint.y - shape.startPoint.y;
            CGFloat length = hypot(dx, dy);
            if (length < 4) {
                [NSGraphicsContext restoreGraphicsState];
                return;
            }
            
            CGFloat angle = atan2(dy, dx);
            CGFloat headLen = MAX(16.0, shape.strokeWidth * 3.5);
            CGFloat headAngle = M_PI / 6.0;
            
            // Draw shaft
            NSBezierPath *shaft = [NSBezierPath bezierPath];
            [shaft moveToPoint:shape.startPoint];
            NSPoint shaftEnd = NSMakePoint(shape.endPoint.x - (headLen * 0.7) * cos(angle),
                                           shape.endPoint.y - (headLen * 0.7) * sin(angle));
            [shaft lineToPoint:shaftEnd];
            shaft.lineWidth = shape.strokeWidth;
            shaft.lineCapStyle = NSLineCapStyleRound;
            [shape.color setStroke];
            [shaft stroke];
            
            // Draw arrow head
            NSBezierPath *head = [NSBezierPath bezierPath];
            [head moveToPoint:shape.endPoint];
            [head lineToPoint:NSMakePoint(shape.endPoint.x - headLen * cos(angle - headAngle),
                                          shape.endPoint.y - headLen * sin(angle - headAngle))];
            [head lineToPoint:NSMakePoint(shape.endPoint.x - (headLen * 0.6) * cos(angle),
                                          shape.endPoint.y - (headLen * 0.6) * sin(angle))];
            [head lineToPoint:NSMakePoint(shape.endPoint.x - headLen * cos(angle + headAngle),
                                          shape.endPoint.y - headLen * sin(angle + headAngle))];
            [head closePath];
            [shape.color setFill];
            [head fill];
            
            [NSGraphicsContext restoreGraphicsState];
            break;
        }
        case ToolTypeRect: {
            [NSGraphicsContext saveGraphicsState];
            [shadow set];
            NSRect r = NSMakeRect(MIN(shape.startPoint.x, shape.endPoint.x),
                                  MIN(shape.startPoint.y, shape.endPoint.y),
                                  fabs(shape.endPoint.x - shape.startPoint.x),
                                  fabs(shape.endPoint.y - shape.startPoint.y));
            if (r.size.width > 2 && r.size.height > 2) {
                NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:r xRadius:6 yRadius:6];
                path.lineWidth = shape.strokeWidth;
                [shape.color setStroke];
                [path stroke];
            }
            [NSGraphicsContext restoreGraphicsState];
            break;
        }
        case ToolTypeCircle: {
            [NSGraphicsContext saveGraphicsState];
            [shadow set];
            NSRect r = NSMakeRect(MIN(shape.startPoint.x, shape.endPoint.x),
                                  MIN(shape.startPoint.y, shape.endPoint.y),
                                  fabs(shape.endPoint.x - shape.startPoint.x),
                                  fabs(shape.endPoint.y - shape.startPoint.y));
            if (r.size.width > 2 && r.size.height > 2) {
                NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:r];
                path.lineWidth = shape.strokeWidth;
                [shape.color setStroke];
                [path stroke];
            }
            [NSGraphicsContext restoreGraphicsState];
            break;
        }
        case ToolTypeStepBadge: {
            [NSGraphicsContext saveGraphicsState];
            [shadow set];
            CGFloat radius = 16.0;
            NSRect badgeRect = NSMakeRect(shape.startPoint.x - radius, shape.startPoint.y - radius, radius * 2, radius * 2);
            NSBezierPath *badge = [NSBezierPath bezierPathWithOvalInRect:badgeRect];
            [shape.color setFill];
            [badge fill];

            [[NSColor whiteColor] setStroke];
            badge.lineWidth = 2.5;
            [badge stroke];

            NSString *numStr = [NSString stringWithFormat:@"%ld", (long)shape.stepNumber];
            NSDictionary *attrs = @{
                NSFontAttributeName: [NSFont boldSystemFontOfSize:15],
                NSForegroundColorAttributeName: [NSColor whiteColor]
            };
            NSSize strSize = [numStr sizeWithAttributes:attrs];
            NSRect textRect = NSMakeRect(shape.startPoint.x - strSize.width / 2.0,
                                         shape.startPoint.y - strSize.height / 2.0,
                                         strSize.width,
                                         strSize.height);
            [numStr drawInRect:textRect withAttributes:attrs];
            [NSGraphicsContext restoreGraphicsState];
            break;
        }
        case ToolTypeText: {
            if (shape.textString.length == 0) return;
            [NSGraphicsContext saveGraphicsState];

            // Soft dark shadow for contrast on both light and dark photo backgrounds
            NSShadow *textShadow = [[NSShadow alloc] init];
            textShadow.shadowColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.8];
            textShadow.shadowBlurRadius = 3.5;
            textShadow.shadowOffset = NSMakeSize(1.0, -1.0);

            CGFloat fontSize = MAX(18.0, shape.strokeWidth * 4.5);
            NSDictionary *attrs = @{
                NSFontAttributeName: [NSFont boldSystemFontOfSize:fontSize],
                NSForegroundColorAttributeName: shape.color,
                NSShadowAttributeName: textShadow
            };

            // Draw purely transparent text onto the image with contrast shadow
            [shape.textString drawAtPoint:shape.startPoint withAttributes:attrs];
            [NSGraphicsContext restoreGraphicsState];
            break;
        }
        case ToolTypeHighlight: {
            if (shape.pointsArray.count < 2) return;
            [NSGraphicsContext saveGraphicsState];
            NSBezierPath *path = [NSBezierPath bezierPath];
            NSPoint first = [shape.pointsArray.firstObject pointValue];
            [path moveToPoint:first];
            for (NSUInteger i = 1; i < shape.pointsArray.count; i++) {
                [path lineToPoint:[shape.pointsArray[i] pointValue]];
            }
            path.lineWidth = shape.strokeWidth * 2.5;
            path.lineCapStyle = NSLineCapStyleSquare;
            path.lineJoinStyle = NSLineJoinStyleRound;
            [[shape.color colorWithAlphaComponent:0.4] setStroke];
            [path stroke];
            [NSGraphicsContext restoreGraphicsState];
            break;
        }
        case ToolTypeBlur:
            break;
    }
}

#pragma mark - Mouse Events

- (void)mouseDown:(NSEvent *)event {
    [self removeActiveTextField];
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    BOOL isCmd = (event.modifierFlags & NSEventModifierFlagCommand) != 0;

    // 1. Check if clicking on a resize handle of the currently selected shape
    if (self.selectedShape) {
        ShapeResizeHandle handle = [self.selectedShape hitTestHandleAtPoint:location tolerance:12.0];
        if (handle != ShapeResizeHandleNone) {
            [self.history pushState:self.shapes];
            self.activeResizeHandle = handle;
            self.resizeOriginalRect = [self.selectedShape boundingRect];
            self.resizeOriginalStrokeWidth = self.selectedShape.strokeWidth;
            if (self.selectedShape.pointsArray) {
                self.resizeOriginalPoints = [self.selectedShape.pointsArray copy];
            }
            if (self.selectedShape.type == ToolTypeArrow) {
                self.resizeAnchorPoint = (handle == ShapeResizeHandleArrowStart) ? self.selectedShape.endPoint : self.selectedShape.startPoint;
            } else {
                NSRect r = [self.selectedShape boundingRect];
                switch (handle) {
                    case ShapeResizeHandleBottomLeft:
                        self.resizeAnchorPoint = NSMakePoint(NSMaxX(r), NSMaxY(r));
                        break;
                    case ShapeResizeHandleBottomRight:
                        self.resizeAnchorPoint = NSMakePoint(NSMinX(r), NSMaxY(r));
                        break;
                    case ShapeResizeHandleTopRight:
                        self.resizeAnchorPoint = NSMakePoint(NSMinX(r), NSMinY(r));
                        break;
                    case ShapeResizeHandleTopLeft:
                        self.resizeAnchorPoint = NSMakePoint(NSMaxX(r), NSMinY(r));
                        break;
                    default:
                        break;
                }
            }
            return;
        }
    }

    // 2. Select Tool or Cmd-drag mode: hit-test shapes to select & move
    if (self.currentTool == ToolTypeSelect || isCmd) {
        AnnotationShape *hit = [self findShapeAtPoint:location];
        if (hit) {
            self.selectedShape = hit;
            self.isDraggingSelectedShape = YES;
            self.lastDragLocation = location;
            [self.history pushState:self.shapes];
            [self.window invalidateCursorRectsForView:self];
            [self setNeedsDisplay:YES];
            return;
        } else {
            if (self.currentTool == ToolTypeSelect) {
                self.selectedShape = nil;
                [self.window invalidateCursorRectsForView:self];
                [self setNeedsDisplay:YES];
                return;
            }
        }
    }

    // 3. If clicking on the currently selected shape, allow moving it directly
    if (self.selectedShape && [self.selectedShape hitTestPoint:location tolerance:8.0]) {
        self.isDraggingSelectedShape = YES;
        self.lastDragLocation = location;
        [self.history pushState:self.shapes];
        return;
    }

    // 4. Clear previous selection when starting to draw something else
    self.selectedShape = nil;
    [self.window invalidateCursorRectsForView:self];

    if (self.currentTool == ToolTypeSelect) {
        [self setNeedsDisplay:YES];
        return;
    }

    if (self.currentTool == ToolTypeStepBadge) {
        [self.history pushState:self.shapes];
        AnnotationShape *s = [AnnotationShape shapeWithType:ToolTypeStepBadge
                                                      start:location
                                                        end:location
                                                      color:self.currentColor
                                                strokeWidth:self.currentStrokeWidth];
        s.stepNumber = self.stepCounter++;
        [self.shapes addObject:s];
        self.selectedShape = s;
        [self setNeedsDisplay:YES];
        [self.delegate canvasDidChangeShapes];
        return;
    }

    if (self.currentTool == ToolTypeText) {
        self.textPlacementPoint = location;
        [self showTextInputAt:location];
        return;
    }

    self.isDrawing = YES;
    self.startPoint = location;
    self.currentPoint = location;
    [self.activeHighlightPoints removeAllObjects];
    if (self.currentTool == ToolTypeHighlight) {
        [self.activeHighlightPoints addObject:[NSValue valueWithPoint:location]];
    }
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];

    // Handling shape resizing
    if (self.activeResizeHandle != ShapeResizeHandleNone && self.selectedShape) {
        if (self.selectedShape.type == ToolTypeArrow) {
            if (self.activeResizeHandle == ShapeResizeHandleArrowStart) {
                self.selectedShape.startPoint = location;
            } else {
                self.selectedShape.endPoint = location;
            }
        } else if (self.selectedShape.type == ToolTypeRect ||
                   self.selectedShape.type == ToolTypeCircle ||
                   self.selectedShape.type == ToolTypeBlur) {
            self.selectedShape.startPoint = self.resizeAnchorPoint;
            self.selectedShape.endPoint = location;
        } else if (self.selectedShape.type == ToolTypeText) {
            CGFloat newH = fabs(location.y - self.resizeAnchorPoint.y);
            CGFloat newStroke = MAX(1.0, (newH - 4.0) / 4.5);
            self.selectedShape.strokeWidth = newStroke;
            if (location.x < self.resizeAnchorPoint.x) {
                self.selectedShape.startPoint = NSMakePoint(location.x, MIN(location.y, self.resizeAnchorPoint.y));
            }
        } else if (self.selectedShape.type == ToolTypeStepBadge) {
            CGFloat dist = hypot(location.x - self.selectedShape.startPoint.x, location.y - self.selectedShape.startPoint.y);
            self.selectedShape.strokeWidth = MAX(2.0, MIN(12.0, dist / 4.0));
        } else if (self.selectedShape.type == ToolTypeHighlight && self.resizeOriginalPoints.count > 0) {
            CGFloat origW = MAX(10.0, self.resizeOriginalRect.size.width);
            CGFloat origH = MAX(10.0, self.resizeOriginalRect.size.height);
            CGFloat newW = MAX(10.0, fabs(location.x - self.resizeAnchorPoint.x));
            CGFloat newH = MAX(10.0, fabs(location.y - self.resizeAnchorPoint.y));
            CGFloat minX = MIN(location.x, self.resizeAnchorPoint.x);
            CGFloat minY = MIN(location.y, self.resizeAnchorPoint.y);
            NSMutableArray *scaled = [NSMutableArray arrayWithCapacity:self.resizeOriginalPoints.count];
            for (NSValue *val in self.resizeOriginalPoints) {
                NSPoint pt = [val pointValue];
                CGFloat nx = (pt.x - self.resizeOriginalRect.origin.x) / origW;
                CGFloat ny = (pt.y - self.resizeOriginalRect.origin.y) / origH;
                NSPoint newPt = NSMakePoint(minX + nx * newW, minY + ny * newH);
                [scaled addObject:[NSValue valueWithPoint:newPt]];
            }
            self.selectedShape.pointsArray = scaled;
        }
        [self.window invalidateCursorRectsForView:self];
        [self setNeedsDisplay:YES];
        return;
    }

    if (self.isDraggingSelectedShape && self.selectedShape) {
        CGFloat dx = location.x - self.lastDragLocation.x;
        CGFloat dy = location.y - self.lastDragLocation.y;
        [self.selectedShape translateByDx:dx dy:dy];
        self.lastDragLocation = location;
        [self.window invalidateCursorRectsForView:self];
        [self setNeedsDisplay:YES];
        return;
    }

    if (!self.isDrawing) return;
    self.currentPoint = location;

    if (self.currentTool == ToolTypeHighlight) {
        [self.activeHighlightPoints addObject:[NSValue valueWithPoint:location]];
    }
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)event {
    if (self.activeResizeHandle != ShapeResizeHandleNone) {
        self.activeResizeHandle = ShapeResizeHandleNone;
        [self.window invalidateCursorRectsForView:self];
        [self setNeedsDisplay:YES];
        [self.delegate canvasDidChangeShapes];
        return;
    }

    if (self.isDraggingSelectedShape) {
        self.isDraggingSelectedShape = NO;
        [self.window invalidateCursorRectsForView:self];
        [self setNeedsDisplay:YES];
        [self.delegate canvasDidChangeShapes];
        return;
    }

    if (!self.isDrawing) return;
    self.isDrawing = NO;
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];

    CGFloat dist = hypot(location.x - self.startPoint.x, location.y - self.startPoint.y);
    if (self.currentTool != ToolTypeHighlight && dist < 3.0) {
        [self setNeedsDisplay:YES];
        return;
    }

    [self.history pushState:self.shapes];
    AnnotationShape *s = [AnnotationShape shapeWithType:self.currentTool
                                                  start:self.startPoint
                                                    end:location
                                                  color:self.currentColor
                                            strokeWidth:self.currentStrokeWidth];
    if (self.currentTool == ToolTypeHighlight) {
        s.pointsArray = [self.activeHighlightPoints mutableCopy];
    }
    [self.shapes addObject:s];
    self.selectedShape = s;
    [self.activeHighlightPoints removeAllObjects];
    [self setNeedsDisplay:YES];
    [self.delegate canvasDidChangeShapes];
}

#pragma mark - Inline Text Input

- (void)showTextInputAt:(NSPoint)point {
    CGFloat fontSize = MAX(18.0, self.currentStrokeWidth * 4.5);
    NSTextField *tf = [[NSTextField alloc] initWithFrame:NSMakeRect(point.x, point.y - 4, 260, fontSize + 16)];
    tf.drawsBackground = NO;
    tf.bordered = NO;
    tf.backgroundColor = [NSColor clearColor];
    tf.textColor = self.currentColor;
    tf.font = [NSFont boldSystemFontOfSize:fontSize];
    tf.placeholderString = @"Type note & press Enter";
    tf.focusRingType = NSFocusRingTypeNone;
    tf.wantsLayer = YES;
    tf.layer.backgroundColor = [NSColor clearColor].CGColor;
    tf.layer.cornerRadius = 4;
    tf.layer.borderWidth = 1.0;
    tf.layer.borderColor = [self.currentColor colorWithAlphaComponent:0.75].CGColor;
    tf.delegate = self;
    tf.target = self;
    tf.action = @selector(commitText);
    
    [self addSubview:tf];
    [self.window makeFirstResponder:tf];
    self.activeTextField = tf;
}

- (void)commitText {
    if (!self.activeTextField) return;
    NSString *txt = [self.activeTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (txt.length > 0) {
        [self.history pushState:self.shapes];
        AnnotationShape *s = [AnnotationShape shapeWithType:ToolTypeText
                                                      start:self.textPlacementPoint
                                                        end:self.textPlacementPoint
                                                      color:self.currentColor
                                                strokeWidth:self.currentStrokeWidth];
        s.textString = txt;
        [self.shapes addObject:s];
        [self.delegate canvasDidChangeShapes];
    }
    [self removeActiveTextField];
    [self setNeedsDisplay:YES];
}

- (void)removeActiveTextField {
    if (self.activeTextField) {
        [self.activeTextField removeFromSuperview];
        self.activeTextField = nil;
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    [self commitText];
}

#pragma mark - Composed Image Export

- (NSImage *)renderComposedImage {
    if (!self.baseImage) return nil;
    NSSize size = self.baseImage.size;
    if (size.width <= 0 || size.height <= 0) return nil;

    NSRect fullRect = NSMakeRect(0, 0, size.width, size.height);
    NSRect dispRect = [self imageDisplayRect];
    if (dispRect.size.width <= 0 || dispRect.size.height <= 0) return self.baseImage;

    CGFloat scaleX = size.width / dispRect.size.width;
    CGFloat scaleY = size.height / dispRect.size.height;

    NSImage *output = [[NSImage alloc] initWithSize:size];
    [output lockFocus];

    [self.baseImage drawInRect:fullRect fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];

    // Scale context so we can draw annotations in original image resolution
    CGContextRef cg = [[NSGraphicsContext currentContext] CGContext];
    CGContextSaveGState(cg);

    // Transform from canvas display coords to image coords
    CGContextTranslateCTM(cg, -dispRect.origin.x * scaleX, -dispRect.origin.y * scaleY);
    CGContextScaleCTM(cg, scaleX, scaleY);

    for (AnnotationShape *shape in self.shapes) {
        if (shape.type == ToolTypeBlur) {
            [self drawBlurShape:shape inRect:dispRect];
        }
    }
    for (AnnotationShape *shape in self.shapes) {
        if (shape.type != ToolTypeBlur) {
            [self drawShape:shape inRect:dispRect];
        }
    }

    CGContextRestoreGState(cg);
    [output unlockFocus];
    return output;
}

@end
