#import <UIKit/UIKit.h>
#import "Video.h"
#import "VideoButton.h"


@interface VideoHomeViewController : UIViewController {
    
}

@property (nonatomic, retain) IBOutlet UIWebView *featuredVideoWebview;
@property (nonatomic, retain) IBOutlet UIView *thumbnailsContainer;
@property (nonatomic, retain) IBOutlet VideoButton *selectedButton;

@property (nonatomic, retain) Video *selectedVideo;
@property (nonatomic, retain) NSArray *videos;
@property (nonatomic, retain) UIView *loadingView;

@end
