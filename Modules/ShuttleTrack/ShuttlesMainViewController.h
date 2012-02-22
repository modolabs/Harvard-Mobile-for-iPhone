#import <UIKit/UIKit.h>
#import "ShuttlesTabViewControl.h"
#import "ShuttleRoutes.h"
#import "AnnouncementsTableViewController.h"
#import "ContactsTableViewController.h"

@class AnnouncementsTableViewController;
@class ContactsTableViewController;
@class ShuttleRoutes;


@interface ShuttlesMainViewController : UIViewController
<TabViewControlDelegate, ShuttleDataManagerDelegate> {
	
	IBOutlet ShuttlesTabViewControl *tabView;
	IBOutlet UIImageView *newAnnouncement;
	IBOutlet UIView *tabViewContainer;
	
	NSMutableArray *_tabViewsArray;
	
	ShuttleRoutes *shuttleRoutesTableView; 

	AnnouncementsTableViewController * announcementsTab;
	ContactsTableViewController * contactsTab;
	
	UIView * loadingIndicator;
	
	BOOL haveNewAnnouncements;

}

@property (nonatomic, retain) ShuttlesTabViewControl *tabView;
@property (nonatomic) BOOL haveNewAnnouncements;

- (void)addLoadingIndicator;
-(void)removeLoadingIndicator;
@end
