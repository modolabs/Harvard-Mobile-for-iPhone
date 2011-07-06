#import <UIKit/UIKit.h>
#import "Video.h"
#import "VideoButton.h"
#import "VideoDataManager.h"


@interface VideoHomeViewController : UIViewController <UISearchBarDelegate,
                                                        UISearchDisplayDelegate, 
                                                        UITableViewDataSource, 
                                                        UITableViewDelegate,
                                                        VideosReceivedDelegate,
                                                        UIWebViewDelegate> {
    
}

@property (nonatomic, retain) IBOutlet UIWebView *featuredVideoWebview;
@property (nonatomic, retain) IBOutlet UIView *searchDisplayContent;
@property (nonatomic, retain) UISearchDisplayController *searchController;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITableViewCell *videoCell;
@property (nonatomic, retain) IBOutlet UIView *thumbnailsContainer;
@property (nonatomic, retain) IBOutlet VideoButton *selectedButton;
@property (nonatomic, retain) IBOutlet UIButton *bookmarksButton;

@property (nonatomic, retain) Video *selectedVideo;
@property (nonatomic, retain) NSArray *videos;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) UIView *loadingView;

- (IBAction)showBookmarks:(id)sender;

@end
