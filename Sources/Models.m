#import "Models.h"

@implementation AnnotationShape

+ (instancetype)shapeWithType:(ToolType)type
                        start:(NSPoint)start
                          end:(NSPoint)end
                        color:(NSColor *)color
                  strokeWidth:(CGFloat)width {
    AnnotationShape *s = [[AnnotationShape alloc] init];
    s.type = type;
    s.startPoint = start;
    s.endPoint = end;
    s.color = color ?: [NSColor redColor];
    s.strokeWidth = width > 0 ? width : 4.0;
    s.pointsArray = [NSMutableArray array];
    return s;
}

- (id)copyWithZone:(NSZone *)zone {
    AnnotationShape *copy = [[[self class] allocWithZone:zone] init];
    copy.type = self.type;
    copy.startPoint = self.startPoint;
    copy.endPoint = self.endPoint;
    copy.color = self.color;
    copy.strokeWidth = self.strokeWidth;
    copy.stepNumber = self.stepNumber;
    copy.textString = [self.textString copy];
    copy.pointsArray = [self.pointsArray mutableCopy];
    return copy;
}

static CGFloat DistanceFromPointToLineSegment(NSPoint p, NSPoint a, NSPoint b) {
    CGFloat l2 = (b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y);
    if (l2 == 0) return hypot(p.x - a.x, p.y - a.y);
    CGFloat t = ((p.x - a.x) * (b.x - a.x) + (p.y - a.y) * (b.y - a.y)) / l2;
    t = MAX(0.0, MIN(1.0, t));
    NSPoint projection = NSMakePoint(a.x + t * (b.x - a.x), a.y + t * (b.y - a.y));
    return hypot(p.x - projection.x, p.y - projection.y);
}

- (NSRect)boundingRect {
    switch (self.type) {
        case ToolTypeArrow: {
            CGFloat minX = MIN(self.startPoint.x, self.endPoint.x);
            CGFloat minY = MIN(self.startPoint.y, self.endPoint.y);
            CGFloat maxX = MAX(self.startPoint.x, self.endPoint.x);
            CGFloat maxY = MAX(self.startPoint.y, self.endPoint.y);
            return NSInsetRect(NSMakeRect(minX, minY, MAX(maxX - minX, 10), MAX(maxY - minY, 10)), -8, -8);
        }
        case ToolTypeRect:
        case ToolTypeBlur: {
            CGFloat minX = MIN(self.startPoint.x, self.endPoint.x);
            CGFloat minY = MIN(self.startPoint.y, self.endPoint.y);
            CGFloat w = fabs(self.endPoint.x - self.startPoint.x);
            CGFloat h = fabs(self.endPoint.y - self.startPoint.y);
            return NSMakeRect(minX, minY, w, h);
        }
        case ToolTypeCircle: {
            CGFloat minX = MIN(self.startPoint.x, self.endPoint.x);
            CGFloat minY = MIN(self.startPoint.y, self.endPoint.y);
            CGFloat w = fabs(self.endPoint.x - self.startPoint.x);
            CGFloat h = fabs(self.endPoint.y - self.startPoint.y);
            return NSMakeRect(minX, minY, w, h);
        }
        case ToolTypeStepBadge: {
            CGFloat radius = 16.0;
            return NSMakeRect(self.startPoint.x - radius, self.startPoint.y - radius, radius * 2, radius * 2);
        }
        case ToolTypeText: {
            if (self.textString.length == 0) return NSMakeRect(self.startPoint.x, self.startPoint.y, 40, 24);
            CGFloat fontSize = MAX(18.0, self.strokeWidth * 4.5);
            NSDictionary *attrs = @{ NSFontAttributeName: [NSFont boldSystemFontOfSize:fontSize] };
            NSSize strSize = [self.textString sizeWithAttributes:attrs];
            return NSMakeRect(self.startPoint.x, self.startPoint.y, MAX(strSize.width, 30), MAX(strSize.height, fontSize + 4));
        }
        case ToolTypeHighlight: {
            if (self.pointsArray.count == 0) return NSZeroRect;
            CGFloat minX = CGFLOAT_MAX, minY = CGFLOAT_MAX, maxX = -CGFLOAT_MAX, maxY = -CGFLOAT_MAX;
            for (NSValue *val in self.pointsArray) {
                NSPoint pt = [val pointValue];
                minX = MIN(minX, pt.x);
                minY = MIN(minY, pt.y);
                maxX = MAX(maxX, pt.x);
                maxY = MAX(maxY, pt.y);
            }
            CGFloat pad = MAX(12.0, self.strokeWidth / 2.0);
            return NSInsetRect(NSMakeRect(minX, minY, MAX(maxX - minX, 10), MAX(maxY - minY, 10)), -pad, -pad);
        }
        default:
            return NSZeroRect;
    }
}

- (BOOL)hitTestPoint:(NSPoint)point tolerance:(CGFloat)tolerance {
    tolerance = MAX(tolerance, 6.0);
    switch (self.type) {
        case ToolTypeArrow: {
            CGFloat effectiveTolerance = MAX(tolerance, self.strokeWidth / 2.0 + 5.0);
            return DistanceFromPointToLineSegment(point, self.startPoint, self.endPoint) <= effectiveTolerance;
        }
        case ToolTypeRect: {
            NSRect r = [self boundingRect];
            if (r.size.width <= tolerance * 2 || r.size.height <= tolerance * 2) {
                return NSPointInRect(point, NSInsetRect(r, -tolerance, -tolerance));
            }
            NSRect outer = NSInsetRect(r, -tolerance, -tolerance);
            NSRect inner = NSInsetRect(r, tolerance, tolerance);
            return NSPointInRect(point, outer) && !NSPointInRect(point, inner);
        }
        case ToolTypeCircle: {
            NSRect r = [self boundingRect];
            if (r.size.width <= 2 || r.size.height <= 2) return NO;
            CGFloat cx = r.origin.x + r.size.width / 2.0;
            CGFloat cy = r.origin.y + r.size.height / 2.0;
            CGFloat rx = r.size.width / 2.0;
            CGFloat ry = r.size.height / 2.0;
            if (rx <= 0 || ry <= 0) return NO;
            CGFloat dx = (point.x - cx) / rx;
            CGFloat dy = (point.y - cy) / ry;
            CGFloat normDist = sqrt(dx * dx + dy * dy);
            CGFloat minRadius = MIN(rx, ry);
            CGFloat relTolerance = tolerance / minRadius;
            return fabs(normDist - 1.0) <= relTolerance;
        }
        case ToolTypeStepBadge: {
            CGFloat dist = hypot(point.x - self.startPoint.x, point.y - self.startPoint.y);
            return dist <= (16.0 + tolerance);
        }
        case ToolTypeText: {
            NSRect r = [self boundingRect];
            return NSPointInRect(point, NSInsetRect(r, -tolerance, -tolerance));
        }
        case ToolTypeBlur: {
            NSRect r = [self boundingRect];
            return NSPointInRect(point, NSInsetRect(r, -tolerance, -tolerance));
        }
        case ToolTypeHighlight: {
            if (self.pointsArray.count < 2) return NO;
            CGFloat effectiveTol = MAX(tolerance, self.strokeWidth / 2.0 + 4.0);
            for (NSUInteger i = 0; i < self.pointsArray.count - 1; i++) {
                NSPoint p1 = [self.pointsArray[i] pointValue];
                NSPoint p2 = [self.pointsArray[i+1] pointValue];
                if (DistanceFromPointToLineSegment(point, p1, p2) <= effectiveTol) {
                    return YES;
                }
            }
            return NO;
        }
        default:
            return NO;
    }
}

- (ShapeResizeHandle)hitTestHandleAtPoint:(NSPoint)point tolerance:(CGFloat)tolerance {
    if (self.type == ToolTypeArrow) {
        if (hypot(point.x - self.startPoint.x, point.y - self.startPoint.y) <= tolerance) {
            return ShapeResizeHandleArrowStart;
        }
        if (hypot(point.x - self.endPoint.x, point.y - self.endPoint.y) <= tolerance) {
            return ShapeResizeHandleArrowEnd;
        }
        return ShapeResizeHandleNone;
    }

    NSRect r = NSInsetRect([self boundingRect], -4, -4);
    if (hypot(point.x - NSMinX(r), point.y - NSMinY(r)) <= tolerance) {
        return ShapeResizeHandleBottomLeft;
    }
    if (hypot(point.x - NSMaxX(r), point.y - NSMinY(r)) <= tolerance) {
        return ShapeResizeHandleBottomRight;
    }
    if (hypot(point.x - NSMaxX(r), point.y - NSMaxY(r)) <= tolerance) {
        return ShapeResizeHandleTopRight;
    }
    if (hypot(point.x - NSMinX(r), point.y - NSMaxY(r)) <= tolerance) {
        return ShapeResizeHandleTopLeft;
    }
    return ShapeResizeHandleNone;
}

- (void)translateByDx:(CGFloat)dx dy:(CGFloat)dy {
    self.startPoint = NSMakePoint(self.startPoint.x + dx, self.startPoint.y + dy);
    self.endPoint = NSMakePoint(self.endPoint.x + dx, self.endPoint.y + dy);
    if (self.pointsArray.count > 0) {
        NSMutableArray *updated = [NSMutableArray arrayWithCapacity:self.pointsArray.count];
        for (NSValue *val in self.pointsArray) {
            NSPoint pt = [val pointValue];
            [updated addObject:[NSValue valueWithPoint:NSMakePoint(pt.x + dx, pt.y + dy)]];
        }
        self.pointsArray = updated;
    }
}

@end

@interface HistoryManager ()
@property (nonatomic, strong) NSMutableArray<NSArray<AnnotationShape *> *> *undoStack;
@property (nonatomic, strong) NSMutableArray<NSArray<AnnotationShape *> *> *redoStack;
@end

@implementation HistoryManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _undoStack = [NSMutableArray array];
        _redoStack = [NSMutableArray array];
    }
    return self;
}

- (void)pushState:(NSArray<AnnotationShape *> *)shapes {
    NSMutableArray *copied = [NSMutableArray arrayWithCapacity:shapes.count];
    for (AnnotationShape *s in shapes) {
        [copied addObject:[s copy]];
    }
    [self.undoStack addObject:copied];
    [self.redoStack removeAllObjects];
}

- (NSArray<AnnotationShape *> *)undoWithCurrentState:(NSArray<AnnotationShape *> *)current {
    if (self.undoStack.count == 0) return nil;
    
    NSMutableArray *currentCopied = [NSMutableArray arrayWithCapacity:current.count];
    for (AnnotationShape *s in current) {
        [currentCopied addObject:[s copy]];
    }
    [self.redoStack addObject:currentCopied];
    
    NSArray *last = [self.undoStack lastObject];
    [self.undoStack removeLastObject];
    return last;
}

- (NSArray<AnnotationShape *> *)redoWithCurrentState:(NSArray<AnnotationShape *> *)current {
    if (self.redoStack.count == 0) return nil;
    
    NSMutableArray *currentCopied = [NSMutableArray arrayWithCapacity:current.count];
    for (AnnotationShape *s in current) {
        [currentCopied addObject:[s copy]];
    }
    [self.undoStack addObject:currentCopied];
    
    NSArray *next = [self.redoStack lastObject];
    [self.redoStack removeLastObject];
    return next;
}

- (BOOL)canUndo {
    return self.undoStack.count > 0;
}

- (BOOL)canRedo {
    return self.redoStack.count > 0;
}

- (void)clear {
    [self.undoStack removeAllObjects];
    [self.redoStack removeAllObjects];
}

@end
