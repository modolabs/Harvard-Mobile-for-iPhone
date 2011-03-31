#import "CalendarEventsViewController.h"
#import "MITUIConstants.h"
#import "CalendarModule.h"
#import "CalendarDetailViewController.h"
#import "CalendarDataManager.h"
#import "CalendarEventMapAnnotation.h"
#import "MITSearchDisplayController.h"
#import <QuartzCore/QuartzCore.h>
#import "TileServerManager.h"
#import "EventListTableView.h"
#import "ModoSearchBar.h"

#define SCROLL_TAB_HORIZONTAL_PADDING 5.0
#define SCROLL_TAB_HORIZONTAL_MARGIN  5.0
#define SEARCH_BUTTON_TAG 7947

@interface CalendarEventsViewController (Private)

- (void)returnToToday;

// helper methods used in reloadView
- (BOOL)canShowMap:(CalendarEventListType)listType;
- (void)incrementStartDate:(BOOL)forward;
- (void)showPreviousDate;
- (void)showNextDate;
- (BOOL)shouldShowDatePicker:(CalendarEventListType)listType;
- (void)setupDatePicker;

// search bar animation
- (void)showSearchBar;
- (void)hideSearchBar;
- (void)releaseSearchBar;

- (void)addLoadingIndicatorForSearch:(BOOL)isSearch;
- (void)removeLoadingIndicator;

- (void)showSearchResultsMapView;
- (void)showSearchResultsTableView;

@end


@implementation CalendarEventsViewController

@synthesize startDate, endDate, events;
@synthesize activeEventList, showList, showScroller, categoriesRequestDispatched;
@synthesize tableView = theTableView, mapView = theMapView, catID = theCatID;
//@synthesize dateSelector;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		startDate = [[NSDate date] retain];
		endDate = [[NSDate date] retain];
		
		// these two properties should be set by the creator
		// defaults are here for safety
		activeEventList = CalendarEventListTypeEvents;
		showScroller = YES;
		theCatID = kCalendarTopLevelCategoryID;
    }
    return self;
}

- (void)dealloc {
	
	[theTableView release];
    theMapView.delegate = nil;
	[theMapView release];
	[searchResultsTableView release];
    searchResultsMapView.delegate = nil;
    [searchResultsMapView release];
	[navScrollView release];
	[datePicker release];
	[events release];
	[startDate release];
	[endDate release];
	[loadingIndicator release];
	[nothingFound release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	if (showList) {
        theMapView.delegate = nil;
		[theMapView release];
		theMapView = nil;
	} else {
		[theTableView release];
		theTableView = nil;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if (showScroller) {
	 [self.view addSubview:navScrollView];
	 }
	 
	 if ([self shouldShowDatePicker:activeEventList]) {
	 [self.view addSubview:datePicker];
	 }
	
	apiRequest = [[JSONAPIRequest requestWithJSONAPIDelegate:self] retain];
	
	// sending in the request for Categories List from the server
	if (categoriesRequestDispatched == NO) {
        apiRequest.userData = [NSString stringWithString:@"categories"];
		categoriesRequestDispatched = [apiRequest requestObjectFromModule:@"calendar"
																   command:@"categories"
																parameters:nil];
    }
	else {
		[self reloadView:activeEventList];
	}

	
	//moved the following commented out code to the request:jsonLoaded function
	
	//self.view.backgroundColor = [UIColor clearColor];
	
	if (showScroller) {
		[self.view addSubview:navScrollView];
	}
	
	if ([self shouldShowDatePicker:activeEventList]) {
		[self.view addSubview:datePicker];
	}
	
	if (categoriesRequestDispatched) {
		[self addLoadingIndicatorForSearch:NO];
	}
}

- (void)viewDidUnload {
	
	[theTableView release];
    theMapView.delegate = nil;
	[theMapView release];
	[searchResultsTableView release];
    searchResultsMapView.delegate = nil;
    [searchResultsMapView release];
	[navScrollView release];
	[datePicker release];
	[loadingIndicator release];
	[nothingFound release];
}

#pragma mark View controller

- (void)loadView
{
	[super loadView];
	
	theTableView = nil;
	theMapView = nil;
	searchResultsTableView = nil;
	searchResultsMapView = nil;
	datePicker = nil;
	dateRangeDidChange = YES;
	requestDispatched = NO;
	loadingIndicator = nil;
	
	// TODO: clean up the code to remvoe the types: Exhibits, Academic and Holiday
	//CalendarEventListType buttonTypes[NumberOfCalendarEventListTypes] = {
	CalendarEventListType buttonTypes[3] = {
		CalendarEventListTypeEvents,
		//CalendarEventListTypeExhibits,
		CalendarEventListTypeCategory,
		CalendarEventListTypeAcademic,
		//CalendarEventListTypeHoliday
	};
	
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	
	if (showScroller) {
        if (!navScrollView) {
            navScrollView = [[NavScrollerView alloc] initWithFrame:CGRectMake(0, 0, appFrame.size.width, 44.0)];
            navScrollView.navScrollerDelegate = self;
        }
        
		UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage *searchImage = [UIImage imageNamed:MITImageNameSearch];
		[searchButton setImage:searchImage forState:UIControlStateNormal];
        searchButton.adjustsImageWhenHighlighted = NO;
		searchButton.tag = SEARCH_BUTTON_TAG; // random number that won't conflict with event list types
        navScrollView.currentXOffset += 4.0;
        [navScrollView addButton:searchButton shouldHighlight:NO];

        // increase tappable area for search button
        UIControl *searchTapRegion = [[UIControl alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
        searchTapRegion.backgroundColor = [UIColor clearColor];
        searchTapRegion.center = searchButton.center;
        [searchTapRegion addTarget:self action:@selector(showSearchBar) forControlEvents:UIControlEventTouchUpInside];
        
		// create buttons for nav scroller view		
		for (int i = 0; i < NumberOfCalendarEventListTypes; i++) {

			CalendarEventListType listType = buttonTypes[i];
			NSString *buttonTitle = [CalendarConstants titleForEventType:listType];
			UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
			aButton.tag = listType;           
			[aButton setTitle:buttonTitle forState:UIControlStateNormal];
            [navScrollView addButton:aButton shouldHighlight:YES];
		}
        
        [navScrollView setNeedsLayout];

        // TODO: use active category instead of always start at first tab
		UIButton *homeButton = [navScrollView buttonWithTag:0];

        [navScrollView buttonPressed:homeButton];
        searchTapRegion.tag = 8768; // all subviews of navscrollview need tag numbers that don't compete with buttons
        [navScrollView addSubview:searchTapRegion];
	}
	
}



- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// since we add our tableviews manually we also need to do this manually
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	[searchResultsTableView deselectRowAtIndexPath:[searchResultsTableView indexPathForSelectedRow] animated:YES];
}

- (NSArray *)events
{
	return events;
}

- (void)setEvents:(NSArray *)someEvents
{
	[events release];
	
	events = [someEvents retain];

	theMapView.events = someEvents;
	((EventListTableView *)self.tableView).events = someEvents;
}

- (void)returnToTodayAndReload {
    [self returnToToday];
    [self reloadView:activeEventList];
}

- (void)returnToToday {
    [startDate release];
    startDate = [[NSDate date] retain];
    dateRangeDidChange = YES;
}


- (void)pickDate {
	
	if (activeEventList != CalendarEventListTypeAcademic) {
	DatePickerViewController *dateSelector = [[DatePickerViewController alloc] init];
	dateSelector.delegate = self;
	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate presentAppModalViewController:dateSelector animated:YES];
    [dateSelector release];
	}
}
#pragma mark Redrawing logic and helper functions

- (void)reloadView:(CalendarEventListType)listType {
	
    if (isFederatedSearch) {
        return;
    }
    
	[self abortExtraneousRequest];
    
    [searchResultsMapView removeFromSuperview];
    [searchResultsTableView removeFromSuperview];
    
    [self.tableView removeFromSuperview];
    
	BOOL requestNeeded = YES;
	
	if (listType != activeEventList) {
		activeEventList = listType;
        [self returnToToday];
	}

	CGFloat yOffset = showScroller ? navScrollView.frame.size.height : 0.0;
	if ([self shouldShowDatePicker:activeEventList]) {
		[self setupDatePicker];
		yOffset += datePicker.frame.size.height - 4.0; // 4.0 is height of transparent shadow under image
	} else {
		[datePicker removeFromSuperview];
	}
	
	CGRect contentFrame = CGRectMake(0, self.view.bounds.origin.y + yOffset, 
									 self.view.bounds.size.width, 
									 self.view.bounds.size.height - yOffset);
	
	// see if we need a mapview
	if (![self canShowMap:activeEventList]) {
		showList = YES;
	} else if (self.mapView == nil) {
		self.mapView = [[CalendarMapView alloc] initWithFrame:contentFrame];
		self.mapView.delegate = self;
	}

	if (dateRangeDidChange && activeEventList != CalendarEventListTypeCategory) {
		requestNeeded = YES;
	}
	
	if (showScroller) {
		self.navigationItem.title = @"Events";
	}
	
	if (showList) {
		
		[self.tableView release];
		self.tableView = nil;
		
			if (nothingFound != nil) {
				[nothingFound removeFromSuperview];
			}
		
		if (activeEventList == CalendarEventListTypeCategory) {
			if (nothingFound != nil) {
				[nothingFound removeFromSuperview];
			}
			self.tableView = [[EventCategoriesTableView alloc] initWithFrame:contentFrame style:UITableViewStyleGrouped];			
			[self.tableView applyStandardColors];
			EventCategoriesTableView *categoriesTV = (EventCategoriesTableView *)self.tableView;
			categoriesTV.delegate = categoriesTV;
			categoriesTV.dataSource = categoriesTV;
			categoriesTV.parentViewController = self;

			// populate (sub)categories from core data
			// if we receive nil from core data, then make a trip to the server
			NSArray *categories = nil;
			if (theCatID != kCalendarTopLevelCategoryID) {
				EventCategory *category = [CalendarDataManager categoryWithID:theCatID];
				NSMutableArray *subCategories = [[[category.subCategories allObjects] mutableCopy] autorelease];
				// sort "All" category, i.e. the category that is a subcategory of itself, to the beginning
				[subCategories removeObject:category];
				categories = [[NSArray arrayWithObject:category] arrayByAddingObjectsFromArray:subCategories];
			} else {
				categories = [CalendarDataManager topLevelCategories];
			}
			
			if (categories == nil) {
				requestNeeded = YES;
			} else if (requestNeeded == NO){
				categoriesTV.categories = categories;
			}
			
		} else {
			self.tableView = [[EventListTableView alloc] initWithFrame:contentFrame];
			self.tableView.delegate = (EventListTableView *)self.tableView;
			self.tableView.dataSource = (EventListTableView *)self.tableView;
			((EventListTableView *)self.tableView).parentViewController = self;
			/*NSArray *someEvents = [CalendarDataManager eventsWithStartDate:startDate
                                                                  listType:activeEventList
																  category:(theCatID == kCalendarTopLevelCategoryID) ? nil : [NSNumber numberWithInt:theCatID]];*/
			
			NSArray *someEvents = nil;
			
			//if (someEvents != nil && [someEvents count] && (requestNeeded == NO)) {
			if (someEvents != nil && [someEvents count]) {
				self.events = someEvents;
				((EventListTableView *)self.tableView).events = self.events;
				if (listType == CalendarEventListTypeAcademic) {
					((EventListTableView *)self.tableView).isAcademic = YES;
				}
				else {
					((EventListTableView *)self.tableView).isAcademic = NO;
				}

				theMapView.events = self.events;
				[self.tableView reloadData];
                requestNeeded = NO;
			} else {
				requestNeeded = YES;
			}
			
		}
		
		self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				
		[self.view addSubview:self.tableView];
		
		self.navigationItem.rightBarButtonItem = [self canShowMap:activeEventList]
		? [[[UIBarButtonItem alloc] initWithTitle:@"Map"
											style:UIBarButtonItemStylePlain
										   target:self
										   action:@selector(mapButtonToggled)] autorelease]
		: nil;
		
		[self.mapView removeFromSuperview];
		
	} else {
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"List"
																				   style:UIBarButtonItemStylePlain
																				  target:self
																				  action:@selector(listButtonToggled)] autorelease];
		
        [self.view addSubview:self.mapView];
	}
	
	if ([self shouldShowDatePicker:activeEventList]) {
		[self setupDatePicker];
	}
	
	if (requestNeeded) {
		[self makeRequest];
	}
	
	dateRangeDidChange = NO;
}

- (void)selectScrollerButton:(NSString *)buttonTitle
{
	//for (UIButton *aButton in navButtons) {
    for (UIButton *aButton in navScrollView.buttons) {
		if ([aButton.titleLabel.text isEqualToString:buttonTitle]) {			
			[self buttonPressed:aButton];
			break;
		}
	}
}

- (void)incrementStartDate:(BOOL)forward
{
	NSTimeInterval interval = [CalendarConstants intervalForEventType:activeEventList
															 fromDate:startDate
															  forward:forward];
	@synchronized(self) {
		NSDate *otherDate = startDate;
		startDate = nil;
		startDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:otherDate];
		[otherDate release];
	}
    
	dateRangeDidChange = YES;
	[self reloadView:activeEventList];
}

- (void)showPreviousDate {
	[self incrementStartDate:NO];
}

- (void)showNextDate {
	[self incrementStartDate:YES];
}

- (BOOL)canShowMap:(CalendarEventListType)listType {
	return (listType == CalendarEventListTypeEvents || listType == CalendarEventListTypeExhibits);
}

- (BOOL)shouldShowDatePicker:(CalendarEventListType)listType {
	// TODO: refine date picker criteria
	// ideally we would find a better source for holiday info
	// and activate prev/next for holiday view
	return (listType != CalendarEventListTypeCategory && listType != CalendarEventListTypeHoliday);
}

- (void)setupDatePicker
{
	
	NSInteger calendarButtonTag = 2487;
	
	if (datePicker == nil) {
		
		CGFloat yOffset = showScroller ? navScrollView.frame.size.height : 0.0;
		CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
		
		datePicker = [[UIView alloc] initWithFrame:CGRectMake(0.0, yOffset, appFrame.size.width, 44.0)];
		UIImageView *datePickerBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, datePicker.frame.size.width, datePicker.frame.size.height)];
		datePickerBackground.image = [[UIImage imageNamed:@"global/subheadbar_background.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
		[datePicker addSubview:datePickerBackground];
		[datePickerBackground release];

		UIImage *buttonImage;  // = [UIImage imageNamed:@"global/subheadbar_button"];
		
		UIButton *prevDate = [UIButton buttonWithType:UIButtonTypeCustom];
		buttonImage = [UIImage imageNamed:@"global/subheadbar_button_previous"];
		prevDate.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
		prevDate.center = CGPointMake(appFrame.size.width - buttonImage.size.width - 21.0, 21.0);
		[prevDate setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[prevDate setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_previous_pressed"] forState:UIControlStateHighlighted];
		//[prevDate setImage:[UIImage imageNamed:MITImageNameLeftArrow] forState:UIControlStateNormal];
		[prevDate addTarget:self action:@selector(showPreviousDate) forControlEvents:UIControlEventTouchUpInside];
		[datePicker addSubview:prevDate];
		
		UIButton *nextDate = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonImage = [UIImage imageNamed:@"global/subheadbar_button_next"];
		nextDate.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
		nextDate.center = CGPointMake(appFrame.size.width - 21.0, 21.0);
		[nextDate setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[nextDate setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_next_pressed"] forState:UIControlStateHighlighted];
		//[nextDate setImage:[UIImage imageNamed:MITImageNameRightArrow] forState:UIControlStateNormal];
		[nextDate addTarget:self action:@selector(showNextDate) forControlEvents:UIControlEventTouchUpInside];
		[datePicker addSubview:nextDate];
	}
	
	[datePicker removeFromSuperview];
    
    NSInteger randomTag = 3289;
	
	for (UIView *view in [datePicker subviews]) {
		
		if (view.tag == randomTag) {
			[view removeFromSuperview];
		}
		if (view.tag == calendarButtonTag)
			[view removeFromSuperview];
	}
	
	if (activeEventList != CalendarEventListTypeAcademic) {
		UIImage *buttonImage1 = [UIImage imageNamed:@"global/subheadbar_button"];
		UIButton *showCalendar = [UIButton buttonWithType:UIButtonTypeCustom];
		showCalendar.frame = CGRectMake(0, 0, buttonImage1.size.width, buttonImage1.size.height);
		showCalendar.center = CGPointMake(21.0, 21.0);
		[showCalendar setBackgroundImage:buttonImage1 forState:UIControlStateNormal];
		[showCalendar setBackgroundImage:[UIImage imageNamed:@"global/subheadbar_button_pressed"] forState:UIControlEventTouchUpInside];
		[showCalendar setImage:[UIImage imageNamed:@"global/subheadbar_calendar"] forState:UIControlStateNormal];
		[showCalendar addTarget:self action:@selector(pickDate) forControlEvents:UIControlEventTouchUpInside];
		showCalendar.tag = calendarButtonTag;
	[	datePicker addSubview:showCalendar];
	}
    
	NSString *dateText = [CalendarConstants dateStringForEventType:activeEventList forDate:startDate];
	UIFont *dateFont = [UIFont fontWithName:BOLD_FONT size:18.0];
	CGSize textSize = [dateText sizeWithFont:dateFont];

    UIButton *dateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dateButton.frame = CGRectMake(0.0, 0.0, textSize.width, textSize.height);
    dateButton.titleLabel.text = dateText;
    dateButton.titleLabel.font = dateFont;
    dateButton.titleLabel.textColor = [UIColor whiteColor];
    [dateButton setTitle:dateText forState:UIControlStateNormal];
    dateButton.center = CGPointMake(datePicker.center.x, datePicker.center.y - datePicker.frame.origin.y);
    dateButton.tag = randomTag;
    [datePicker addSubview:dateButton];
	
	[self.view addSubview:datePicker];
}


#pragma mark -
#pragma mark Search bar activation

- (void)showSearchBar
{
    if (!theSearchBar) {
        theSearchBar = [[ModoSearchBar alloc] initWithFrame:navScrollView.frame];
        theSearchBar.tintColor = SEARCH_BAR_TINT_COLOR;
        theSearchBar.delegate = self;
        theSearchBar.alpha = 0.0;
        searchController = [[MITSearchDisplayController alloc] initWithSearchBar:theSearchBar contentsController:self];
        searchController.delegate = self;
        [self.view addSubview:theSearchBar];
    }
    [self.view bringSubviewToFront:theSearchBar];
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
	theSearchBar.alpha = 1.0;
	[UIView commitAnimations];
    [searchController setActive:YES animated:YES];
}

- (void)hideSearchBar {
	if (theSearchBar) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.4];
        [UIView setAnimationDidStopSelector:@selector(releaseSearchBar)];
		theSearchBar.alpha = 0.0;
		[UIView commitAnimations];
	}
}

- (void)releaseSearchBar {
    [theSearchBar removeFromSuperview];
    [theSearchBar release];
    theSearchBar = nil;
    [searchController release];
}

- (void)searchOverlayTapped
{
    if (searchResultsTableView.events == nil) {
		[self searchBarCancelButtonClicked:theSearchBar];
	}
    isFederatedSearch = NO;
}

- (void)presentSearchResults:(NSArray *)results searchText:(NSString *)searchText searchSpan:(NSString *)searchSpan
{
    [self showSearchBar];
    [theSearchBar resignFirstResponder];
    theSearchBar.text = searchText;
    
    isFederatedSearch = YES;
    
    // make sure both map and list are populated if user wants to switch
    // but only one is shown
    if (showList) {
        [self showSearchResultsMapView];
        searchResultsMapView.events = results;
        
        [self showSearchResultsTableView];
        searchResultsTableView.searchSpan = searchSpan;
        searchResultsTableView.events = results;
    } else {
        [self showSearchResultsTableView];
        searchResultsTableView.searchSpan = searchSpan;
        searchResultsTableView.events = results;
        
        [self showSearchResultsMapView];
        searchResultsMapView.events = results;
    }
}

#pragma mark Search delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self makeSearchRequest:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{	
	[self abortExtraneousRequest];
	[self hideSearchBar];
    isFederatedSearch = NO;
    
	[self reloadView:activeEventList];
}

#pragma mark -

- (void)showSearchResultsMapView {
	showList = NO;

	if (searchResultsMapView == nil) {
		searchResultsMapView = [[CalendarMapView alloc] initWithFrame:CGRectMake(0.0, theSearchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - theSearchBar.frame.size.height)];
        searchResultsMapView.region = self.mapView.region;
		searchResultsMapView.delegate = self;
	}
    
	[self.view addSubview:searchResultsMapView];
	[searchResultsTableView removeFromSuperview];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"List"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																			  action:@selector(showSearchResultsTableView)] autorelease];
}

- (void)showSearchResultsTableView {
	showList = YES;

	if (searchResultsTableView == nil) {
		searchResultsTableView = [[EventListTableView alloc] initWithFrame:CGRectMake(0.0, theSearchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - theSearchBar.frame.size.height)];
        searchResultsTableView.isSearchResults = YES;
		searchResultsTableView.parentViewController = self;
		searchResultsTableView.delegate = searchResultsTableView;
		searchResultsTableView.dataSource = searchResultsTableView;
	}
	
	[self.view addSubview:searchResultsTableView];
	[searchResultsMapView removeFromSuperview];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Map"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																			  action:@selector(showSearchResultsMapView)] autorelease];
}

#pragma mark -
#pragma mark UI Event observing

- (void)mapButtonToggled {
	showList = NO;
	[self reloadView:activeEventList];
}

- (void)listButtonToggled {
	showList = YES;
	[self reloadView:activeEventList];
}

- (void)buttonPressed:(id)sender {
    UIButton *pressedButton = (UIButton *)sender;
    if (pressedButton.tag == SEARCH_BUTTON_TAG) {
        [self showSearchBar];
    } else {
        [self reloadView:pressedButton.tag];
    }
}

- (void)addLoadingIndicatorForSearch:(BOOL)isSearch
{
	if (loadingIndicator == nil) {
		static NSString *loadingString = @"Loading...";
		UIFont *loadingFont = [UIFont fontWithName:STANDARD_FONT size:17.0];
		CGSize stringSize = [loadingString sizeWithFont:loadingFont];

        CGFloat verticalPadding = 10.0;
        CGFloat horizontalPadding = 16.0;
        CGFloat horizontalSpacing = 3.0;
        CGFloat cornerRadius = 8.0;
        
        UIActivityIndicatorViewStyle style = (showList) ? UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleWhite;
		UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
       // spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
		spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
		[spinny startAnimating];
        
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(spinny.frame.size.width + horizontalPadding + horizontalSpacing, verticalPadding, stringSize.width, stringSize.height + 2.0)];
		label.textColor = (showList) ? [UIColor colorWithWhite:0.5 alpha:1.0] : [UIColor whiteColor];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];
        
		loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, stringSize.width + spinny.frame.size.width + horizontalPadding * 2, stringSize.height + verticalPadding * 2)];
        loadingIndicator.layer.cornerRadius = cornerRadius;
        loadingIndicator.backgroundColor = (showList) ? [UIColor clearColor] : [UIColor colorWithWhite:0.0 alpha:0.8];
		[loadingIndicator addSubview:spinny];
		[spinny release];
		[loadingIndicator addSubview:label];
		[label release];

		//loadingIndicator.backgroundColor = label.backgroundColor;
	}

	// self.view.frame changes depending on whether it's the first time we're looking at this,
	// so we need to figure out its position based on things that don't change
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	/*CGFloat yOffset = showScroller ? navScrollView.frame.size.height : 0.0;
	if (!isSearch && [self shouldShowDatePicker:activeEventList]) {
		yOffset += datePicker.frame.size.height;
	}*/

	CGPoint center = CGPointMake(appFrame.size.width / 2, (appFrame.size.height) / 2);
	loadingIndicator.center = center;
	
	[self.view addSubview:loadingIndicator];
}

- (void)removeLoadingIndicator
{
	[loadingIndicator removeFromSuperview];
    [loadingIndicator release];
    loadingIndicator = nil;
}

#pragma mark Map View Delegate
 
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	CalendarEventMapAnnotation *annotation = view.annotation;
	MITCalendarEvent *event = nil;
	CalendarMapView *calMapView = (CalendarMapView *)mapView;
	for (event in calMapView.events) {
		if (event.eventID == annotation.event.eventID) {
			break;
		}
	}

	if (event != nil) {
		CalendarDetailViewController *detailVC = [[CalendarDetailViewController alloc] init];
		detailVC.event = event;
		[self.navigationController pushViewController:detailVC animated:YES];
		[detailVC release];
	}
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKPinAnnotationView *annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"adsf"] autorelease];
    annotationView.animatesDrop = YES;
    annotationView.canShowCallout = YES;
    UIButton *disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    annotationView.rightCalloutAccessoryView = disclosureButton;
	
	//MKAnnotationView *annotationView = [mapView viewForAnnotation:annotation];
    
	return annotationView;
}

#pragma mark Server connection methods

- (void)abortExtraneousRequest
{
	if (requestDispatched) {
		[apiRequest abortRequest];
		[self removeLoadingIndicator];
		requestDispatched = NO;
	}
}

- (void)makeSearchRequest:(NSString *)searchTerms
{
	[self abortExtraneousRequest];

	apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	apiRequest.userData = CalendarEventAPISearch;
	requestDispatched = [apiRequest requestObjectFromModule:CalendarTag 
												   command:@"search" 
												parameters:[NSDictionary dictionaryWithObjectsAndKeys:searchTerms, @"q", nil]];

	if (requestDispatched) {
		if (showList) {
			searchResultsTableView.events = nil;
            searchResultsTableView.isSearchResults = NO;
			[searchResultsTableView reloadData];
			[self showSearchResultsTableView];
		} else {
			searchResultsMapView.events = nil;
			[self showSearchResultsMapView];
		}
		
		[self addLoadingIndicatorForSearch:YES];
	}
}

- (void)makeRequest
{
	[self abortExtraneousRequest];
	
	apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
	apiRequest.userData = [CalendarConstants titleForEventType:activeEventList];
	
	switch (activeEventList) {
		case CalendarEventListTypeEvents:
			if (theCatID != kCalendarTopLevelCategoryID) {
				NSTimeInterval interval = [startDate timeIntervalSince1970];
				NSString *timeString = [NSString stringWithFormat:@"%d", (int)interval];
				requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
																command:@"category"
															 parameters:[NSDictionary dictionaryWithObjectsAndKeys:
																		 [NSString stringWithFormat:@"%d", theCatID], @"id",
																		 timeString, @"start", nil]];
				break;
			}
			// fall through
		case CalendarEventListTypeExhibits:
		{
			// TODO: add other time ranges
			NSTimeInterval interval = [startDate timeIntervalSince1970];
			NSString *timeString = [NSString stringWithFormat:@"%d", (int)interval];
			
			requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
															command:[CalendarConstants apiCommandForEventType:activeEventList]
														 parameters:[NSDictionary dictionaryWithObjectsAndKeys:
																	 [CalendarConstants titleForEventType:activeEventList], @"type", 
																	 timeString, @"time", nil]];
			break;
		}
		case CalendarEventListTypeAcademic:
		{
			NSCalendar *calendar = [NSCalendar currentCalendar];
			NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit;
			NSDateComponents *comps = [calendar components:unitFlags fromDate:startDate];
			NSString *month = [NSString stringWithFormat:@"%d", [comps month]];
			NSString *year = [NSString stringWithFormat:@"%d", [comps year]];

			requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
															command:[CalendarConstants apiCommandForEventType:activeEventList]
														 parameters:[NSDictionary dictionaryWithObjectsAndKeys:year, @"year", month, @"month", nil]];
			break;
		}
		default:
			requestDispatched = [apiRequest requestObjectFromModule:CalendarTag
															command:[CalendarConstants apiCommandForEventType:activeEventList]
														 parameters:nil];
			break;
	}
	
	if (requestDispatched) {
		[self addLoadingIndicatorForSearch:NO];
	}
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
	
	[self removeLoadingIndicator];

	// moved the following from viewDidLoad to ensure that the categories request completed before a load view
	// if (categoriesRequestDispatched == YES)
    if ([request.userData isEqualToString:@"categories"])
    {
		 NSMutableArray *arrayForTable = [NSMutableArray arrayWithCapacity:[result count]];
		 
			 for (NSDictionary *catDict in result) {
				 EventCategory *category = [CalendarDataManager categoryWithDict:catDict];
				 [arrayForTable addObject:category];
			 }
        if ([self.tableView isKindOfClass:[EventCategoriesTableView class]]) {
			 ((EventCategoriesTableView *)self.tableView).categories = [NSArray arrayWithArray:arrayForTable];
        }
		 
		 self.view.backgroundColor = [UIColor clearColor];	 
		 [self reloadView:activeEventList];
	 
		 categoriesRequestDispatched = YES;
        return;
	 }	
	
	requestDispatched = NO;

	if (![request.userData isEqualToString:CalendarEventAPISearch]
		&& ![request.userData isEqualToString:[CalendarConstants titleForEventType:activeEventList]]) {
		//NSLog(@"received result for request %@", request.userData);
		return; // we are no longer interested in this result
	}
    
    if (result && [request.userData isEqualToString:CalendarEventAPISearch] && [result isKindOfClass:[NSDictionary class]]) {
		
		BOOL resultEventsExist = NO;
        NSArray *resultEvents = [result objectForKey:@"events"];
		NSString *resultSpan;
		NSMutableArray *arrayForTable;
		
		if (![resultEvents isKindOfClass:[NSNull class]]) {
			
			resultEventsExist = YES;
			resultSpan = [result objectForKey:@"span"];
			arrayForTable = [NSMutableArray arrayWithCapacity:[resultEvents count]];
		
			for (NSDictionary *eventDict in resultEvents) {
				MITCalendarEvent *event = [CalendarDataManager eventWithDict:eventDict];
				[arrayForTable addObject:event];
			}
        }
		
		if ((resultEventsExist == YES) && ([resultEvents count] > 0)) {
            
			NSArray *eventsArray = [NSArray arrayWithArray:arrayForTable];
			searchResultsMapView.events = eventsArray;
			searchResultsTableView.events = eventsArray;
			searchResultsTableView.searchSpan = resultSpan;
			searchResultsTableView.isSearchResults = YES;
            [searchController hideSearchOverlayAnimated:YES]; // this isn't actually visible, but it releases the overlay object
			[searchResultsTableView reloadData];
            
			if (showList) {
				[self showSearchResultsTableView];
			} else {
				[self showSearchResultsMapView];
			}
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Results Found", nil)
                                                                message:NSLocalizedString(@"Your query returned no matches.", nil)
                                                               delegate:self
                                                      cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
            [alertView release];
        }
        
    } else if (result && [result isKindOfClass:[NSArray class]]) {
		
		NSMutableArray *arrayForTable = [NSMutableArray arrayWithCapacity:[result count]];
		
		if (activeEventList == CalendarEventListTypeCategory) {

			for (NSDictionary *catDict in result) {
				EventCategory *category = [CalendarDataManager categoryWithDict:catDict];
				[arrayForTable addObject:category];
			}
			((EventCategoriesTableView *)self.tableView).categories = [NSArray arrayWithArray:arrayForTable];
		
		} else {
            // academic & holiday events have no category so we assign something to differentiate them
            EventCategory *category = nil;
            switch (activeEventList) {
                case CalendarEventListTypeAcademic:
                    category = [CalendarDataManager categoryWithID:kCalendarAcademicCategoryID];
                    break;
                case CalendarEventListTypeHoliday:
                    category = [CalendarDataManager categoryWithID:kCalendarHolidayCategoryID];
                    break;
                case CalendarEventListTypeExhibits:
                    category = [CalendarDataManager categoryWithID:kCalendarExhibitCategoryID];
                    break;
                default:
                    if (theCatID != kCalendarTopLevelCategoryID) {
                        category = [CalendarDataManager categoryWithID:theCatID];
                    }
                    break;
            }
            
			if (([result count] == 0) && ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"Map"])){
				UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 125, 300, 20)];
				label.font = [UIFont systemFontOfSize:17];
																		   
				label.text = @"No Events Found";															   
				NSInteger vertical_margin = 45;
				
				if (theCatID == -1)
					vertical_margin += 50;
				
				CGRect contentFrame = CGRectMake(0,self.view.bounds.origin.y + vertical_margin, 
												 self.view.bounds.size.width, 
												 self.view.bounds.size.height);
				

				nothingFound = nil;
				
				if (nothingFound == nil)
					nothingFound = [[UIView alloc] initWithFrame:contentFrame];
				
				[nothingFound setBackgroundColor:[UIColor whiteColor]];
				
				[nothingFound addSubview:label];
                [label release];
				[self.view addSubview:nothingFound];
               // [nothingFound release];
			}
			else if (nothingFound != nil) {
				[nothingFound removeFromSuperview];
			}
			
			if (([result count] == 0) && (activeEventList == CalendarEventListTypeAcademic)) {
				UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 125, 300, 20)];
				label.font = [UIFont systemFontOfSize:17];
				
				label.text = @"No events for this Academic Year";															   
				NSInteger vertical_margin = 45;
				
				if (theCatID == -1)
					vertical_margin += 50;
				
				CGRect contentFrame = CGRectMake(0,self.view.bounds.origin.y + vertical_margin, 
												 self.view.bounds.size.width, 
												 self.view.bounds.size.height);
				
				if (nothingFound == nil)
					nothingFound = [[UIView alloc] initWithFrame:contentFrame];
				
				[nothingFound setBackgroundColor:[UIColor whiteColor]];
				
				[nothingFound addSubview:label];
                [label release];
				[self.view addSubview:nothingFound];
                //[nothingFound release];
			}
			
			for (NSDictionary *eventDict in result) {
				MITCalendarEvent *event = [CalendarDataManager eventWithDict:eventDict];
				[arrayForTable addObject:event];
			}
			
			self.events = [NSArray arrayWithArray:arrayForTable];			
		}
		
		if (showList) {
			if (activeEventList == CalendarEventListTypeAcademic) {
				((EventListTableView *)self.tableView).isAcademic = YES;
			}
			[self.tableView reloadData];
		}
	}
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
    return YES;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [searchController setActive:YES animated:YES];
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error
{
	requestDispatched = NO;
    [self removeLoadingIndicator];
}


#pragma mark -
#pragma mark DatePickerViewControllerDelegate functions

- (void)datePickerViewControllerDidCancel:(DatePickerViewController *)controller {
	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate dismissAppModalViewControllerAnimated:YES];
	
	return;
}

- (void)datePickerViewController:(DatePickerViewController *)controller didSelectDate:(NSDate *)date {
	
	if ([controller class] == [DatePickerViewController class]) {
		startDate = nil;
		startDate = [[NSDate alloc] initWithTimeInterval:0 sinceDate:date];    
		dateRangeDidChange = YES;

		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate dismissAppModalViewControllerAnimated:YES];
		
		[self reloadView:activeEventList];
	}
	return;
}
- (void)datePickerValueChanged:(id)sender {
	return;
}

@end









