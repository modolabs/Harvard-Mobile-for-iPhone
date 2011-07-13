#import <UIKit/UIKit.h>
#import "ShareDetailViewController.h"
#import "JSONAPIRequest.h"

@class NewsStory;
//@class StoryListViewController;

@protocol NewsControllerDelegate <NSObject>

- (BOOL)canSelectPreviousStory;
- (BOOL)canSelectNextStory;
- (NewsStory *)selectPreviousStory;
- (NewsStory *)selectNextStory;

@end

@interface StoryDetailViewController : ShareDetailViewController <UIWebViewDelegate, ShareItemDelegate, JSONAPIDelegate, UIAlertViewDelegate> {
	//StoryListViewController *newsController;
    id<NewsControllerDelegate> newsController;
    NewsStory *story;
	
	UISegmentedControl *storyPager;
    
    UIWebView *storyView;
}

@property (nonatomic, retain) id<NewsControllerDelegate> newsController;
//@property (nonatomic, retain) StoryListViewController *newsController;
@property (nonatomic, retain) NewsStory *story;
@property (nonatomic, retain) UIWebView *storyView;

// these properties are only used if called from another
// module, and story details not yet available
@property (nonatomic, retain) NSString *storyGUID;
@property (nonatomic, retain) NSString *storySearchTitle;
@property (nonatomic, retain) NSArray *storyCategories; // an array category titles (NSString's)
@property (nonatomic, retain) UIView *loadingView; //loading story from server

- (void)displayStory:(NewsStory *)aStory;

@end
