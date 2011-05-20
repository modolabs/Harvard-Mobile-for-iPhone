#import "StellarCoursesViewController.h"
#import "StellarCourse.h"
#import "StellarClassesViewController.h"
#import "MITModuleList.h"
#import "MITModule.h"
#import "UITableView+MITUIAdditions.h"
#import "UITableViewCell+MITUIAdditions.h"
#import "MultiLineTableViewCell.h"
#import "MITUIConstants.h"

#import "MITLoadingActivityView.h"
#import "MITModuleURL.h"
#import "ModoSearchBar.h"
#import "MITSearchDisplayController.h"
#import "StellarClassesViewController.h"
#import "CoreDataManager.h"
#import "AnalyticsWrapper.h"


#define searchBarHeight NAVIGATION_BAR_HEIGHT

@implementation StellarCoursesViewController

@synthesize courseGroup;
@synthesize url;

@synthesize searchController;
@synthesize loadingView;
@synthesize doSearchTerms;


- (id) initWithCourseGroup: (StellarCourseGroup *)aCourseGroup {
		self.courseGroup = aCourseGroup;
		NSString *path = [NSString stringWithFormat:@"courses/%@", [courseGroup serialize]];
		url = [[MITModuleURL alloc] initWithTag:StellarTag path:path query:nil];
		self.title = aCourseGroup.short_name;
	
	if ([aCourseGroup.short_name isEqualToString:@"Faculty of Arts and Sciences"]) { 
		UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"FAS" style: UIBarButtonItemStyleBordered target: nil action: nil];	
		[[self navigationItem] setBackBarButtonItem: newBackButton];
		[newBackButton release];
	}
	else if ([aCourseGroup.short_name isEqualToString:@"Arts and Sciences"]) { 
		UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"FAS" style: UIBarButtonItemStyleBordered target: nil action: nil];	
		[[self navigationItem] setBackBarButtonItem: newBackButton];
		[newBackButton release];
	}
	else if ([aCourseGroup.short_name isEqualToString:@"Business - Doctoral Program"]) { 
		UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"HBS PhD" style: UIBarButtonItemStyleBordered target: nil action: nil];	
		[[self navigationItem] setBackBarButtonItem: newBackButton];
		[newBackButton release];
	}
	else if ([aCourseGroup.short_name isEqualToString:@"Business - MBA Program"]) { 
		UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"HBS MBA" style: UIBarButtonItemStyleBordered target: nil action: nil];	
		[[self navigationItem] setBackBarButtonItem: newBackButton];
		[newBackButton release];
	}
	
	return self;
}

- (void) dealloc {
	[url release];
	[courseGroup release];
	[doSearchTerms release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[stellarSearch release];
	[searchController release];
	[loadingView release];
	[super dealloc];
}

- (void) viewDidLoad {
	self.title = courseGroup.short_name;
	self.navigationItem.title = courseGroup.short_name;

	CGRect viewFrame = self.view.frame;
	ModoSearchBar *searchBar = [[[ModoSearchBar alloc] initWithFrame:CGRectMake(0, 0, viewFrame.size.width, searchBarHeight)] autorelease];
    [self.view addSubview:searchBar];
	
	self.searchController = [[[MITSearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self] autorelease];
    self.searchController.delegate = self;
	
	stellarSearch = [[StellarSearch alloc] initWithViewController:self];
	self.searchController.searchResultsDelegate = stellarSearch;
	self.searchController.searchResultsDataSource = stellarSearch;
	searchBar.placeholder = [[NSString alloc] initWithFormat:@"Search within %@", self.courseGroup.title];
	
	
	coursesTableView = nil;
	
	coursesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, searchBarHeight, 320.0, 420.0) style: UITableViewStylePlain];
	coursesTableView.delegate= self;
	coursesTableView.dataSource = self;
	coursesTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:coursesTableView];
    [searchBar addDropShadow];
    
    NSString *detailString = [NSString stringWithFormat:@"/courses/courses?school=%@", self.courseGroup.short_name];
    [[AnalyticsWrapper sharedWrapper] trackPageview:detailString];
}

- (void) viewDidAppear:(BOOL)animated {
	[url setAsModulePath];
}

// "DataSource" methods
- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return [self.courseGroup.courses count];//1;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
	MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"StellarCourses"];
	if(cell == nil) {
		cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StellarCourses"] autorelease];
		[cell applyStandardFonts];
	}
	StellarCourse *stellarCourse = (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.section];

	cell.textLabel.text = stellarCourse.title;
	
	if ([self.courseGroup.courses count] < 10) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.hasIndex = YES;
    }
	
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	return cell;
}

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return 1;//[self.courseGroup.courses count];
}


- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	//StellarCourse *stellarCourse = (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.row];
	StellarCourse *stellarCourse = (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.section];

	BOOL indexPane = NO;
    UITableViewCellAccessoryType accessoryType;
	if ([self.courseGroup.courses count] >= 10) {
		indexPane = YES;
        accessoryType = UITableViewCellAccessoryNone;
    } else {
        accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
	
    return [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleDefault
                                                tableView:tableView 
                                                     text:stellarCourse.title//was nil
                                             maxTextLines:2 //was 1
                                               detailText:nil // was stellarCourse.title
                                           maxDetailLines:0
                                                     font:[UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE] 
                                               detailFont:nil 
                                            accessoryType:accessoryType
                                                cellImage:NO
												 hasIndex:indexPane] + 2.0; // was 2.0;
}


- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	[self.navigationController
	 pushViewController: [[[StellarClassesViewController alloc] 
						   //initWithCourse: (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.row]] autorelease]
						   initWithCourse: (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.section]] autorelease]				  
	 animated:YES];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	
	if ([self.courseGroup.courses count] < 10)
		return nil;
	
	NSMutableArray *tempIndexArray = [NSMutableArray array];
	
	
	for(StellarCourse *course in self.courseGroup.courses) {
		if (![tempIndexArray containsObject:[course.title substringToIndex:1]])
			[tempIndexArray addObject:[course.title substringToIndex:1]];		
	}

	NSArray *indexArray = (NSArray *)tempIndexArray;
			 
	return indexArray;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	
	int ind = 0;
	
	for(StellarCourse *course in self.courseGroup.courses) {
		if ([[course.title substringToIndex:1] isEqualToString:title])
			break;
		ind++;
	}
	
	return ind;
}


#pragma mark Search and search UI


- (void) searchBarSearchButtonClicked: (UISearchBar *)theSearchBar {
	[self showLoadingView];
	hasSearchInitiated = YES;
	[StellarModel executeStellarSearch:theSearchBar.text courseGroupName:courseGroup.title courseName:@"" delegate:stellarSearch];
	
	[self.url setPath:@"search-complete" query:theSearchBar.text];
	[self.url setAsModulePath];
    
    [[AnalyticsWrapper sharedWrapper] trackPageview:[NSString stringWithFormat:@"/courses/search?filter=%@", theSearchBar.text]];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    
	[self.url setPath:@"search-begin" query:nil];
	[self.url setAsModulePath];
    
    return YES;
}

- (void) searchBar: (UISearchBar *)searchBar textDidChange: (NSString *)searchText {
	[self hideLoadingView]; // just in case the loading view is showing
	
	hasSearchInitiated = NO;
	
	[self.url setPath:@"search-begin" query:searchText];
	[self.url setAsModulePath];
}

- (void) searchOverlayTapped {
	[self hideLoadingView];
	//[self reloadMyStellarUI];
	[coursesTableView reloadData];
	
	[self.url setPath:@"" query:nil];
	[self.url setAsModulePath];
}

- (void)presentSearchResults:(NSArray *)searchResults query:(NSString *)query {
    self.searchController.searchBar.text = query;
    [stellarSearch searchComplete:searchResults searchTerms:query actualCount:0];
}

// TODO: clean up redundant -[searchBar becomeFirstResponder]
- (void) doSearch:(NSString *)searchTerms execute:(BOOL)execute {
	if(isViewAppeared) {
		self.searchController.active = YES;
		self.searchController.searchBar.text = searchTerms;
		if (execute) {
			self.searchController.searchBar.text = searchTerms;
			[stellarSearch performSelector:@selector(searchBarSearchButtonClicked:) withObject:self.searchController.searchBar afterDelay:0.3];
		} else {
			// using a delay gets rid of a mysterious wait_fences warning
			[self.searchController.searchBar performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.001];
		}
		self.doSearchTerms = nil;
	} else {
		// since view has not appeared yet, this search needs to be delay to either viewWillAppear or viewDidAppear
		// this is a work around for funky behavior when module is in the more list controller
		self.doSearchTerms = searchTerms;
		doSearchExecute = execute;
	}
}

- (void) showSearchResultsTable {
	[self.view addSubview:searchController.searchResultsTableView];
}

- (void) showLoadingView {
	[self.view addSubview:loadingView];
}

- (void) hideSearchResultsTable {
	[searchController.searchResultsTableView removeFromSuperview];
}

- (void) hideLoadingView {
	[loadingView removeFromSuperview];
}

/* To make the compiler happy */
- (void) reloadData {
}


@end
