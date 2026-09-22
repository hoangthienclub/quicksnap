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
