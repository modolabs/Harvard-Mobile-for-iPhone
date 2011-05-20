//
//  ShuttlesMainViewController.m
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/17/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "ShuttlesMainViewController.h"
#import "MITUIConstants.h"
#import "AnalyticsWrapper.h"

#define RunningTabIndex 0
#define OfflineTabIndex 1
#define NewsTabIndex 2
#define InfoTabIndex 3

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
									  0, 
									  newAnnouncement.frame.size.width, 
									  newAnnouncement.frame.size.height)];
	badgeLabel.backgroundColor = [UIColor clearColor];
	badgeLabel.textColor = [UIColor whiteColor];
	badgeLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	badgeLabel.textAlignment = UITextAlignmentCenter;
	badgeLabel.tag = kAnnouncementBadgeLabel;
	[newAnnouncement addSubview:badgeLabel];
	[badgeLabel release];
}

@end


@implementation ShuttlesMainViewController
@synthesize tabView;
@synthesize haveNewAnnouncements;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	newAnnouncement.hidden = YES;
	newAnnouncement.image = [UIImage imageNamed:@"shuttles/shuttle-news-badge.png"];
	[self addBadgeLabelToAnnouncement];
	
	self.view.backgroundColor = [UIColor clearColor];
	
	shuttleRoutesTableView = [[ShuttleRoutes alloc] initWithStyle: UITableViewStyleGrouped];
	shuttleRoutesTableView.parentViewController = self.navigationController;
	shuttleRoutesTableView.mainViewController = self;
	
	//tabViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 420.0)];
	tabViewContainer.backgroundColor = [UIColor whiteColor];
	
	announcementsTab  = [[AnnouncementsTableViewController alloc] initWithStyle:UITableViewStylePlain];
	//announcementsTab = [[AnnouncementsViewController alloc] initWithNibName:@"AnnouncementsViewController" bundle:nil];
	announcementsTab.parentViewController = self.navigationController;
	
	JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	BOOL dispatched = [api requestObjectFromModule:@"shuttles" command:@"announcements" parameters:nil];
	
	contactsTab = [[ContactsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	contactsTab.parentViewController = self.navigationController;
	
	if (dispatched == NO)
		[self couldNotConnectToServer];
	
	if (_tabViewsArray == nil)
		_tabViewsArray = [[NSMutableArray alloc] initWithCapacity:3];
	
	
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
	
	[tabView setNeedsDisplay];
	[tabView setDelegate:self];
		
	[self addLoadingIndicator];
	//[tabViewContainer addSubview:shuttleRoutesTableView.view];
	//[tabViewContainer addSubview:webView];
	
	if (haveNewAnnouncements == YES) {
		newAnnouncement.hidden = NO;
		[[newAnnouncement superview] bringSubviewToFront:newAnnouncement];
	}
	else {
		newAnnouncement.hidden = YES;
		[[newAnnouncement superview] sendSubviewToBack:newAnnouncement];
	}
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshRoutes)];
	
	[tabView setSelectedTab:0];
	shuttleRoutesTableView.currentTabMainView = RunningTabIndex;
		[tabView setNeedsDisplay];
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
	
	if (tabIndex == RunningTabIndex) {
		announcementsTab.view.hidden = YES;
		contactsTab.view.hidden = YES;
		shuttleRoutesTableView.currentTabMainView = RunningTabIndex;
		[shuttleRoutesTableView setShuttleRoutes:shuttleRoutesTableView.shuttleRoutes];
		//[shuttleRoutesTableView.tableView reloadData];
		//[self removeLoadingIndicator];
		[tabViewContainer addSubview:[_tabViewsArray objectAtIndex:tabIndex]];
		shuttleRoutesTableView.view.hidden = NO;
        [[AnalyticsWrapper sharedWrapper] trackEvent:@"shuttleschedule" action:@"running tab pressed" label:nil];
	}
	
	else if (tabIndex == OfflineTabIndex) {
		announcementsTab.view.hidden = YES;
		contactsTab.view.hidden = YES;
		shuttleRoutesTableView.currentTabMainView = OfflineTabIndex;
		[shuttleRoutesTableView setShuttleRoutes:shuttleRoutesTableView.shuttleRoutes];
		[shuttleRoutesTableView.tableView reloadData];
		[tabViewContainer addSubview:[_tabViewsArray objectAtIndex:tabIndex]];
		shuttleRoutesTableView.view.hidden = NO;
        [[AnalyticsWrapper sharedWrapper] trackEvent:@"shuttleschedule" action:@"offline tab pressed" label:nil];
	}
	
	else if (tabIndex == NewsTabIndex) {
		shuttleRoutesTableView.view.hidden = YES;
		contactsTab.view.hidden = YES;
		shuttleRoutesTableView.currentTabMainView = NewsTabIndex;
		//[tabViewContainer addSubview:[_tabViewsArray objectAtIndex:tabIndex]];
		[tabViewContainer addSubview:[_tabViewsArray objectAtIndex:tabIndex]];
		[announcementsTab.tableView reloadData];
		announcementsTab.view.hidden = NO;
        [[AnalyticsWrapper sharedWrapper] trackEvent:@"shuttleschedule" action:@"news tab pressed" label:nil];
	}
	
	else {
		announcementsTab.view.hidden = YES;
		shuttleRoutesTableView.view.hidden = YES;
		shuttleRoutesTableView.currentTabMainView = InfoTabIndex;
		//[shuttleRoutesTableView setShuttleRoutes:shuttleRoutesTableView.shuttleRoutes];
		//[shuttleRoutesTableView.tableView reloadData];
		[tabViewContainer addSubview:[_tabViewsArray objectAtIndex:tabIndex]];
		[contactsTab.tableView reloadData];
		contactsTab.view.hidden = NO;
        [[AnalyticsWrapper sharedWrapper] trackEvent:@"shuttleschedule" action:@"info tab pressed" label:nil];
	}
	
	if (haveNewAnnouncements == YES) {
		newAnnouncement.hidden = NO;
		[[newAnnouncement superview] bringSubviewToFront:newAnnouncement];
	}
	else {
		newAnnouncement.hidden = YES;
		[[newAnnouncement superview] sendSubviewToBack:newAnnouncement];
	}

}


- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
	
	NSArray * agencies =(NSArray *)[result objectForKey:@"agencies"];	
	NSMutableArray * announcementsTemp = [NSMutableArray array];
	
	int new = 0;
	for (int i =0; i < [agencies count]; i++) {
		
		NSDictionary * agency = (NSDictionary *)[agencies objectAtIndex:i];
		NSString * agencyName = [agency objectForKey:@"name"];
		
		NSArray * announcements = [agency objectForKey:@"announcements"];
		
		for (int j =0; j < [announcements count]; j ++) {
			[announcementsTemp addObject:[announcements objectAtIndex:j]];
			NSDictionary * announcementDetails = [announcements objectAtIndex:j];
			BOOL urgent = [[announcementDetails objectForKey:@"urgent"] boolValue];
			NSString * dateString = [announcementDetails objectForKey:@"date"];
			
			NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"YYYY/MM/dd"];
			NSDate* dateAnnouncement = [dateFormatter dateFromString:dateString];
			
			NSDate *today = [NSDate date];
			
			if (([today timeIntervalSinceDate:dateAnnouncement] <= (48*60*60)) || (urgent == YES)) {
				new++;
			}
		}
		
		
		if ([agencyName isEqualToString:@"harvard"]) {
			announcementsTab.harvardAnnouncements = announcementsTemp;
			//announcementsTab.mascoAnnouncements = announcementsTemp;
		}
		else if ([agencyName isEqualToString:@"masco"])
			announcementsTab.mascoAnnouncements = announcementsTemp;
	}

	
	[announcementsTab.tableView reloadData];
	//[announcementsTab.harvardAnnouncementsTableView reloadData];
	//[announcementsTab.mascoAnnouncementsTableView

	if (new > 0) {
		newAnnouncement.hidden = NO;
		haveNewAnnouncements = YES;
		UILabel *badgeLabel = (UILabel *)[newAnnouncement viewWithTag:
										  kAnnouncementBadgeLabel];
		if ([badgeLabel isKindOfClass:[UILabel class]])
		{
			badgeLabel.text = [NSString stringWithFormat:@"%d", new];
			[[newAnnouncement superview] bringSubviewToFront:newAnnouncement];			
		}
	}	
	else {
		newAnnouncement.hidden = YES;
		haveNewAnnouncements = NO;
		[[newAnnouncement superview] sendSubviewToBack:newAnnouncement];
	}
}

-(void)couldNotConnectToServer {
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
