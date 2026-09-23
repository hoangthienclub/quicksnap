#import <Cocoa/Cocoa.h>
#import "Models.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CanvasViewDelegate <NSObject>
- (void)canvasDidChangeShapes;
@end

@interface CanvasView : NSView

@property (nonatomic, weak, nullable) id<CanvasViewDelegate> delegate;
@property (nonatomic, strong, nullable) NSImage *baseImage;
@property (nonatomic, assign) ToolType currentTool;
@property (nonatomic, strong) NSColor *currentColor;
@property (nonatomic, assign) CGFloat currentStrokeWidth;
@property (nonatomic, assign) NSInteger stepCounter;

@property (nonatomic, strong, nullable) AnnotationShape *selectedShape;
@property (nonatomic, assign) BOOL isRenderingForExport;

- (void)loadImage:(NSImage *)image;
- (void)undo;
- (void)redo;
- (BOOL)canUndo;
- (BOOL)canRedo;
- (void)resetStepCounter;
- (void)deleteSelectedShape;
- (void)nudgeSelectedShapeByDx:(CGFloat)dx dy:(CGFloat)dy;
- (void)clearSelection;
- (NSImage * _Nullable)renderComposedImage;

@end

NS_ASSUME_NONNULL_END
