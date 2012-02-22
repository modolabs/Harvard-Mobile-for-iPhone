#import "ShuttlesMainViewController.h"
#import "MITUIConstants.h"
#import "AnalyticsWrapper.h"

enum {
    RunningTabIndex = 0,
    OfflineTabIndex,
    NewsTabIndex,
    InfoTabIndex
};

static const NSInteger kAnnouncementBadgeLabel = 0x41;


#pragma mark Private methods

@interface ShuttlesMainViewController (Private)

- (void)addBadgeLabelToAnnouncement;

@end

@implementation ShuttlesMainViewController (Private)

// Add a label that sits over the newAnnouncement UIImageView.
- (void)addBadgeLabelToAnnouncement {
	UILabel *badgeLabel = [[UILabel alloc] initWithFrame:
						   CGRectMake(0, 
									  -1, 
									  newAnnouncement.frame.size.width, 
									  newAnnouncement.frame.size.height)];
	badgeLabel.backgroundColor = [UIColor clearColor];
	badgeLabel.textColor = [UIColor whiteColor];
	badgeLabel.font = [UIFont boldSystemFontOfSize:14.0f];
	badgeLabel.textAlignment = UITextAlignmentCenter;
	badgeLabel.tag = kAnnouncementBadgeLabel;
	[newAnnouncement addSubview:badgeLabel];
	[badgeLabel release];
}

@end


@implementation ShuttlesMainViewController
@synthesize tabView;
@synthesize haveNewAnnouncements;

- (void)viewWillDisappear:(BOOL)animated
{
    [[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[ShuttleDataManager sharedDataManager] registerDelegate:self];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	newAnnouncement.hidden = YES;
	newAnnouncement.image = [UIImage imageNamed:@"shuttles/shuttle-news-badge.png"];
	[self addBadgeLabelToAnnouncement];
	
	shuttleRoutesTableView = [[ShuttleRoutes alloc] initWithStyle: UITableViewStyleGrouped];
	shuttleRoutesTableView.parentNavigationViewController = self.navigationController;
	shuttleRoutesTableView.mainViewController = self;
	
	announcementsTab  = [[AnnouncementsTableViewController alloc] initWithStyle:UITableViewStylePlain];
	announcementsTab.parentNavigationViewController = self.navigationController;
    
    [[ShuttleDataManager sharedDataManager] registerDelegate:self];
    [[ShuttleDataManager sharedDataManager] requestInfo];
    [[ShuttleDataManager sharedDataManager] requestAnnouncements];
	
	contactsTab = [[ContactsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	contactsTab.parentNavigationViewController = self.navigationController;
	
	if (_tabViewsArray == nil) {
		_tabViewsArray = [[NSMutableArray alloc] initWithCapacity:3];
	}
	
	[tabView addTab:@"Running"];	
	[_tabViewsArray insertObject:shuttleRoutesTableView.view atIndex: RunningTabIndex];
	
	[tabView addTab:@"Offline"];
	[_tabViewsArray insertObject:shuttleRoutesTableView.view atIndex: OfflineTabIndex];
	
	[tabView addTab:@"News"];
	[_tabViewsArray insertObject:announcementsTab.view atIndex: NewsTabIndex];
	
	[tabView addTab:@"Info"];
	[_tabViewsArray insertObject:contactsTab.view atIndex: InfoTabIndex];

	[tabView setDelegate:self];
	tabView.hidden = NO;
	tabViewContainer.hidden = NO;
	
	[self addLoadingIndicator];
	
	if (haveNewAnnouncements == YES) {
		newAnnouncement.hidden = NO;
	}
	else {
		newAnnouncement.hidden = YES;
	}
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                           target:self
                                                                                           action:@selector(refreshRoutes)];
	
	[tabView setSelectedTab:RunningTabIndex];
	shuttleRoutesTableView.currentTabMainView = RunningTabIndex;

    //[tabView setNeedsDisplay];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
   // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    
	[tabView release];
	[tabViewContainer release];
	[shuttleRoutesTableView release];
	[super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[tabView release];
	[tabViewContainer release];
	[shuttleRoutesTableView release];

    [announcementsTab release];
    [contactsTab release];
    [loadingIndicator release];
    [_tabViewsArray release];
    [super dealloc];
}


#pragma mark - TabViewControlDelegate methods
-(void) tabControl:(ShuttlesTabViewControl*)control changedToIndex:(int)tabIndex tabText:(NSString*)tabText{
	
	// change the content based on the tab that was selected
	for(UIView* subview in [tabView subviews])
	{
		[subview removeFromSuperview];
	}
    
    NSString *analyticsAction = nil;;
    shuttleRoutesTableView.currentTabMainView = tabIndex;
    [tabViewContainer addSubview:[_tabViewsArray objectAtIndex:tabIndex]];
    
    announcementsTab.view.hidden = YES;
    contactsTab.view.hidden = YES;
    shuttleRoutesTableView.view.hidden = YES;

	switch (tabIndex) {
        case RunningTabIndex:
            shuttleRoutesTableView.view.hidden = NO;
            //-[ShuttleRoutes setShuttleRoutes:] calls tableView reloadData as a side effect
            [shuttleRoutesTableView setShuttleRoutes:shuttleRoutesTableView.shuttleRoutes];
            analyticsAction = @"running tab pressed";
            break;
        case OfflineTabIndex:
            shuttleRoutesTableView.view.hidden = NO;
            [shuttleRoutesTableView setShuttleRoutes:shuttleRoutesTableView.shuttleRoutes];
            analyticsAction = @"offline tab pressed";
            break;
        case NewsTabIndex:
            announcementsTab.view.hidden = NO;
            [announcementsTab.tableView reloadData];
            analyticsAction = @"news tab pressed";
            break;
        case InfoTabIndex:
            contactsTab.view.hidden = NO;
            [contactsTab.tableView reloadData];
            analyticsAction = @"info tab pressed";
            break;
    }

    if (analyticsAction) {
        [[AnalyticsWrapper sharedWrapper] trackEvent:@"shuttleschedule" action:analyticsAction label:nil];
    }

	if (haveNewAnnouncements == YES) {
		newAnnouncement.hidden = NO;
	}
	else {
		newAnnouncement.hidden = YES;
	}
}

- (void)announcementsReceived:(NSDictionary *)announcements urgentCount:(NSUInteger)urgentCount
{
    // TODO: redo AnnouncementsTableViewController so it doesn't hard code agencies
    NSArray *harvard = [announcements objectForKey:@"harvard"];
    if ([harvard isKindOfClass:[NSArray class]] && harvard.count) {
        announcementsTab.harvardAnnouncements = harvard;
    }
    NSArray *masco = [announcements objectForKey:@"masco"];
    if ([masco isKindOfClass:[NSArray class]] && masco.count) {
        announcementsTab.mascoAnnouncements = masco;
    }
	[announcementsTab.tableView reloadData];

    if (urgentCount) {
        newAnnouncement.hidden = NO;
        haveNewAnnouncements = YES;
        UILabel *badgeLabel = (UILabel *)[newAnnouncement viewWithTag:kAnnouncementBadgeLabel];
        badgeLabel.text = [NSString stringWithFormat:@"%d", urgentCount];
    } else {
        newAnnouncement.hidden = YES;
    }
}

- (void)infoReceived:(NSDictionary *)info
{
}

- (void)addLoadingIndicator
{
	if (loadingIndicator == nil) {
		static NSString *loadingString = @"Loading...";
		UIFont *loadingFont = [UIFont fontWithName:STANDARD_FONT size:17.0];
		CGSize stringSize = [loadingString sizeWithFont:loadingFont];
		
        CGFloat verticalPadding = tabViewContainer.frame.size.height/2 -10;
        CGFloat horizontalPadding = tabViewContainer.frame.size.width/2 - 25;
        CGFloat horizontalSpacing = 15.0;
		// CGFloat cornerRadius = 8.0;
        
        UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray;
		UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
		// spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
		spinny.center = CGPointMake(horizontalPadding, verticalPadding);
		[spinny startAnimating];
        
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(horizontalPadding + horizontalSpacing, verticalPadding - 10, stringSize.width, stringSize.height + 2.0)];
		label.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];

		loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tabViewContainer.frame.size.width, tabViewContainer.frame.size.height)];
		
		[loadingIndicator setBackgroundColor:[UIColor whiteColor]];
		[loadingIndicator addSubview:spinny];
		[spinny release];
		[loadingIndicator addSubview:label];
		[label release];

	}

	
	[tabViewContainer addSubview:loadingIndicator];
}

- (void)removeLoadingIndicator
{
	[loadingIndicator removeFromSuperview];
	 [loadingIndicator release];
	 loadingIndicator = nil;

}


- (void)refreshRoutes {
	int selectedTab = tabView.selectedTab;
	[[ShuttleDataManager sharedDataManager] requestRoutes];
	[self tabControl:tabView changedToIndex:selectedTab tabText:@""];
	
}


@end
