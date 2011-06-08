#import <UIKit/UIKit.h>
#import "Video.h"


@interface VideoHomeViewController : UIViewController {
    
}

@property (nonatomic, retain) IBOutlet UIWebView *featuredVideoWebview;
@property (nonatomic, retain) Video *selectedVideo;
@property (nonatomic, retain) NSArray *videos;
@property (nonatomic, retain) UIView *loadingView;

@end
