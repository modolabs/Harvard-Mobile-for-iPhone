#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"

NSInteger strLenSort(NSString *str1, NSString *str2, void *context);

@class ModoSearchBar;
@class MITSearchDisplayController;

@interface PeopleSearchViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, JSONAPIDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
	
    MITSearchDisplayController *searchController;
    UITableView *_tableView;
	NSArray *searchResults;
	NSString *searchTerms;
	NSArray *searchTokens;
	UIView *loadingView;
    ModoSearchBar *theSearchBar;
	BOOL requestWasDispatched;
	JSONAPIRequest *api;
	UIView *recentlyViewedHeader;
}

- (void)beginExternalSearch:(NSString *)externalSearchTerms;
- (void)performSearch;
- (void)presentSearchResults:(NSArray *)theSearchResults;
- (void)showLoadingView;
- (void)cleanUpConnection;
- (void)phoneIconTappedAtIndexPath:(NSIndexPath *)indexPath;
- (void)showActionSheet;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MITSearchDisplayController *searchController;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) NSString *searchTerms;
@property (nonatomic, retain) NSArray *searchTokens;
@property (nonatomic, retain) ModoSearchBar *searchBar;
@property (nonatomic, retain) UIView *loadingView;

@end
