#import <Cocoa/Cocoa.h>

@protocol MenuBarDelegate <NSObject>
- (void)menuBarDidRequestCapture;
- (void)menuBarDidRequestOpenClipboard;
- (void)menuBarDidToggleAutoOpen:(BOOL)enabled;
- (BOOL)isAutoOpenEnabled;
@end

@interface MenuBarController : NSObject

@property (nonatomic, weak) id<MenuBarDelegate> delegate;

- (instancetype)initWithDelegate:(id<MenuBarDelegate>)delegate;
- (void)updateMenu;

@end
