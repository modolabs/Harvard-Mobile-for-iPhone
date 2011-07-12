#import <UIKit/UIKit.h>
#import "MITThumbnailView.h"
#import "Video.h"

@interface VideoDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate >{
    BOOL bookmarkButtonState;
    
}

@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *durationLabel;
@property (nonatomic, retain) IBOutlet UILabel *uploadedLabel;
@property (nonatomic, retain) IBOutlet UILabel *summaryLabel;
@property (nonatomic, retain) IBOutlet UIView *middleContentContainer;
@property (nonatomic, retain) IBOutlet UIButton *bookmarkButton;
@property (nonatomic, retain) IBOutlet UIWebView *playerWebview;
@property (nonatomic, retain) IBOutlet UITableView *relatedNewsTableView;

@property (nonatomic, retain) NSArray *videos;
@property (nonatomic, retain) Video *currentVideo;
@property (nonatomic, retain) NSArray *relatedPosts;

- (IBAction)bookmarkButtonTapped:(id)sender;

@end
