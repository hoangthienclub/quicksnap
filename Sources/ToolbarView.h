#import <Cocoa/Cocoa.h>
#import "Models.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ToolbarViewDelegate <NSObject>
- (void)toolbarDidSelectTool:(ToolType)tool;
- (void)toolbarDidSelectColor:(NSColor *)color;
- (void)toolbarDidSelectStrokeWidth:(CGFloat)width;
- (void)toolbarDidClickUndo;
- (void)toolbarDidClickRedo;
- (void)toolbarDidClickCopy;
- (void)toolbarDidClickSave;
- (void)toolbarDidClickClose;
- (void)toolbarDidClickCaptureNew;
@end

@interface ToolbarView : NSVisualEffectView

@property (nonatomic, weak, nullable) id<ToolbarViewDelegate> delegate;

+ (CGFloat)recommendedWidth;
+ (CGFloat)recommendedHeight;

- (void)setSelectedTool:(ToolType)tool;
- (void)setSelectedColor:(NSColor *)color;
- (void)setCanUndo:(BOOL)canUndo canRedo:(BOOL)canRedo;
- (void)updateStepCounter:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
