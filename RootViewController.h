// Thanks or unthanks to stack overflow
// a work around to detect when videos from webviews go into fullscreen mode
// this also makes sure videos appear in front of everything else
// http://stackoverflow.com/questions/2718606/mpmovieplayercontroller-fullscreen-movie-inside-a-uiwebview

#import <UIKit/UIKit.h>

@class RootView;
@protocol RootViewDelegate

- (void)rootView:(RootView *)view didAddSubview:(UIView *)view;
- (void)rootView:(RootView *)view willRemoveSubview:(UIView *)view;

@end

@interface RootView : UIView {
@private
}

@property (nonatomic, assign) id<RootViewDelegate> delegate;
@end

@interface RootViewController : UIViewController <RootViewDelegate> {
    
}

@end
