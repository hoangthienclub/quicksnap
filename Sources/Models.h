#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, ToolType) {
    ToolTypeSelect = 0,
    ToolTypeArrow,
    ToolTypeRect,
    ToolTypeCircle,
    ToolTypeStepBadge,
    ToolTypeBlur,
    ToolTypeText,
    ToolTypeHighlight
};

NS_ASSUME_NONNULL_BEGIN

@interface AnnotationShape : NSObject <NSCopying>

@property (nonatomic, assign) ToolType type;
@property (nonatomic, assign) NSPoint startPoint;
@property (nonatomic, assign) NSPoint endPoint;
@property (nonatomic, strong) NSColor *color;
@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, assign) NSInteger stepNumber;
@property (nonatomic, copy, nullable) NSString *textString;
@property (nonatomic, strong) NSMutableArray<NSValue *> *pointsArray;

+ (instancetype)shapeWithType:(ToolType)type
                        start:(NSPoint)start
                          end:(NSPoint)end
                        color:(NSColor *)color
                  strokeWidth:(CGFloat)width;

- (NSRect)boundingRect;
- (BOOL)hitTestPoint:(NSPoint)point tolerance:(CGFloat)tolerance;
- (void)translateByDx:(CGFloat)dx dy:(CGFloat)dy;

@end

@interface HistoryManager : NSObject

- (void)pushState:(NSArray<AnnotationShape *> *)shapes;
- (NSArray<AnnotationShape *> * _Nullable)undoWithCurrentState:(NSArray<AnnotationShape *> *)current;
- (NSArray<AnnotationShape *> * _Nullable)redoWithCurrentState:(NSArray<AnnotationShape *> *)current;
- (BOOL)canUndo;
- (BOOL)canRedo;
- (void)clear;

@end

NS_ASSUME_NONNULL_END
