/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "MainSearchGroupedCoursesTableViewController.h"
#import "StellarCoursesViewController.h"
#import "StellarDetailViewController.h"
#import "StellarClassTableCell.h"
#import "MITModuleList.h"
#import "MITModule.h"
#import "MITLoadingActivityView.h"
#import "UITableView+MITUIAdditions.h"
#import "MultiLineTableViewCell.h"
#import "ModoSearchBar.h"
#import "MITUIConstants.h"
#import "MITSearchDisplayController.h"
#import "AnalyticsWrapper.h"

#define searchBarHeight NAVIGATION_BAR_HEIGHT

@interface MainSearchGroupedCoursesTableViewController (Private)
- (void) alertViewCancel: (UIAlertView *)alertView;
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex: (NSInteger)buttonIndex;
@end

@implementation MainSearchGroupedCoursesTableViewController
@synthesize classes; //currentClassLoader;
@synthesize loadingView;
@synthesize url;

@synthesize searchController;
@synthesize doSearchTerms;
@synthesize searchTerm;

@synthesize mainSearchClassesTableView;

- (MainSearchGroupedCoursesTableViewController *) initWithViewController: (UIViewController *)controller {
	
	viewController = [[MainSearchGroupedCoursesTableViewController alloc] initWithCourse:nil];
	[controller.navigationController pushViewController:viewController animated:YES];
	viewController.navigationItem.title = @"Search Results";
	actualCount = 0;
	self.searchTerm = nil;
	return [viewController autorelease];
}

-(void)setSearchString: (NSString *)searchTerms {
	self.searchTerm = nil;
	self.searchTerm = searchTerms;
	searchController.searchBar.text = self.searchTerm;
}

-(void)setCourseGroupString: (NSString *)courseGroupString {
	
	stellarCourseGroupString = courseGroupString;
}


- (id) initWithCourse: (StellarCourse *)aCourse {
	//if (self = [super initWithStyle:UITableViewStylePlain]) {
	course = [aCourse retain];
	classes = [[NSArray array] retain];
	loadingView = nil;
	url = [[MITModuleURL alloc] initWithTag:StellarTag];
	
	//}
	return self;
}

- (void) dealloc {
	//currentClassLoader.tableController = nil;
	[url release];
	[loadingView release];
	//[currentClassLoader release];
	[classes release];
	[course release];
	[searchTerm release];
	[mainSearchClassesTableView release];
	[viewController release];
	[stellarSearch release];
	[searchController release];
	
	[super dealloc];
}

- (void) showLoadingView {
	//self.tableView.tableHeaderView = loadingView;
	//self.tableView.backgroundColor = [UIColor clearColor];
	[self.view addSubview:loadingView];
	//self.mainSearchClassesTableView.tableHeaderView = loadingView;
	self.mainSearchClassesTableView.backgroundColor = [UIColor clearColor];
}

- (void) hideLoadingView {
	//self.tableView.tableHeaderView = nil;
	//self.tableView.backgroundColor = [UIColor whiteColor];
	[loadingView removeFromSuperview];
	self.mainSearchClassesTableView.tableHeaderView = nil;
	self.mainSearchClassesTableView.backgroundColor = [UIColor whiteColor];
}

- (void) viewDidLoad {
	//self.navigationItem.title = stellarCourseGroupString;
	CGRect viewFrame = self.view.frame;
	ModoSearchBar *searchBar = [[[ModoSearchBar alloc] initWithFrame:CGRectMake(0, 0, viewFrame.size.width, searchBarHeight)] autorelease];
    [self.view addSubview:searchBar];
	
	self.searchController = [[[MITSearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self] autorelease];
    self.searchController.delegate = self;
	
	stellarSearch = [[StellarSearch alloc] initWithViewController:self];
	self.searchController.searchResultsDelegate = stellarSearch;
	self.searchController.searchResultsDataSource = stellarSearch;
	//searchBar.placeholder = [[NSString alloc] initWithFormat:@"Search within %@", stellarCourseGroupString];
	if (self.searchTerm != nil)
		searchController.searchBar.text = self.searchTerm;
	
	mainSearchClassesTableView = nil;
	
	mainSearchClassesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, searchBarHeight, 320.0, 420.0 - searchBarHeight) style: UITableViewStylePlain];
	mainSearchClassesTableView.backgroundColor = [UIColor whiteColor];
	self.view.backgroundColor = [UIColor whiteColor];
	mainSearchClassesTableView.delegate= self;
	mainSearchClassesTableView.dataSource = self;
	mainSearchClassesTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:mainSearchClassesTableView];
	
    [searchBar addDropShadow];

	self.title = course.title;
	//self.currentClassLoader = [[LoadClassesInTable new] autorelease];
	//self.currentClassLoader.tableController = self;
	
	//[self.tableView applyStandardCellHeight];
	[mainSearchClassesTableView applyStandardCellHeight];
	self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:CGRectMake(0.0, searchBarHeight, 320.0, 420.0)] autorelease];
	
	[self showLoadingView];
	
	//[StellarModel loadClassesForCourse:course delegate:self.currentClassLoader];
	
	[url setPathWithViewController:self extension:course.number];
    
    NSString *detailString = [NSString stringWithFormat:@"/courses/search?courseGroup=%@", stellarCourseGroupString];
NSLog(@"%@", detailString);
    [[AnalyticsWrapper sharedWrapper] trackPageview:detailString];
}

- (void) viewDidAppear: (BOOL)animated {
	[url setAsModulePath];
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StellarClasses"];
	if(cell == nil) {
		cell = [[[StellarClassTableCell alloc] initWithReusableCellIdentifier:@"StellarClasses"] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	StellarClass *stellarClass = [classes objectAtIndex:indexPath.row];
	
	StellarClass *stellarPreviousClass;
	
	if (indexPath.row > 0)
		stellarPreviousClass = [classes objectAtIndex:indexPath.row - 1];
	else {
		if ([classes count] > 1)
			stellarPreviousClass = [classes objectAtIndex:indexPath.row + 1];
		
		else 
			stellarPreviousClass = nil;
	}
	
	return [StellarClassTableCell configureCell:cell withStellarClass:stellarClass previousClassInList:stellarPreviousClass];
}	

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return [classes count];
}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	[StellarDetailViewController 
	 launchClass:(StellarClass *)[classes objectAtIndex:indexPath.row]
	 viewController: self];
}

- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
	//return [StellarClassTableCell cellHeightForTableView:tableView class:[classes objectAtIndex:indexPath.row]];
	
	StellarClass *stellarClass = [classes objectAtIndex:indexPath.row];
	StellarClass *stellarPreviousClass;
	
	if (indexPath.row > 0)
		stellarPreviousClass = [classes objectAtIndex:indexPath.row - 1];
	else {
		if ([classes count] > 1)
			stellarPreviousClass = [classes objectAtIndex:indexPath.row + 1];
		
		else 
			stellarPreviousClass = nil;
	}
	NSString *detail = [StellarClassTableCell setStaffNames:stellarClass previousClassInList:stellarPreviousClass];
	return [StellarClassTableCell cellHeightForTableView:tableView class:stellarClass detailString:detail];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex: (NSInteger)buttonIndex {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) alertViewCancel: (UIAlertView *)alertView {
	[self.navigationController popViewControllerAnimated:YES];
}

- (NSString *) tableView: (UITableView *)tableView titleForHeaderInSection: (NSInteger)section {
	
	/*if (actualCount > [classes count]) {
		return [NSString stringWithFormat:@"Displaying %i of many", [classes count]];
	}*/
	
	if([classes count]) {
		if (actualCount > [classes count])
			return [NSString stringWithFormat:@"Displaying %i of many", [classes count]];
		
		return [NSString stringWithFormat:@"%i found", [classes count]];
	}
	return nil;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString *headerTitle = nil;
	
	/*if (actualCount > [classes count]) {
		return [NSString stringWithFormat:@"Displaying %i of many in %@", [classes count], stellarCourseGroupString];
	}*/
	
	if([classes count]) {
		if (actualCount > [classes count])
			headerTitle = [NSString stringWithFormat:@"Displaying %i of many in %@", [classes count], stellarCourseGroupString];

		else {
			headerTitle = [NSString stringWithFormat:@"%i found in %@", [classes count], stellarCourseGroupString];
		}
		return [UITableView ungroupedSectionHeaderWithTitle:headerTitle];
	}
	return nil;
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UNGROUPED_SECTION_HEADER_HEIGHT;//UNGROUPED_SECTION_HEADER_HEIGHT;
}


#pragma mark Search and search UI


- (void) searchBarSearchButtonClicked: (UISearchBar *)theSearchBar {
	[self showLoadingView];
	hasSearchInitiated = YES;
	
	//MainSearchGroupedCoursesTableViewController *mvc = [[MainSearchGroupedCoursesTableViewController alloc] initWithViewController:viewController];
	//NSString *searchStr = [[NSString alloc] initWithFormat:@"%@ %@", theSearchBar.text, stellarCourseGroupString];
	[StellarModel executeStellarSearch:theSearchBar.text courseGroupName:stellarCourseGroupString courseName:course.title delegate:self];
	
	[self.url setPath:@"search-complete" query:theSearchBar.text];
	[self.url setAsModulePath];
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
	[mainSearchClassesTableView reloadData];
	
	[self.url setPath:@"" query:nil];
	[self.url setAsModulePath];
}

- (void)presentSearchResults:(NSArray *)searchResults query:(NSString *)query {
    self.searchController.searchBar.text = query;
    [stellarSearch searchComplete:searchResults searchTerms:query actualCount:actualCount];
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


- (void) hideSearchResultsTable {
	[searchController.searchResultsTableView removeFromSuperview];
}


#pragma mark ClassesSearchDelegate methods

- (void) searchComplete: (NSArray *)classesLoaded searchTerms:searchTerms actualCount:(int)actual_count{
	//if([viewController.searchController.searchBar.text isEqualToString:searchTerms]) {
	
	actualCount = actual_count;
	self.classes = classesLoaded;
	//[self viewDidLoad];
	[mainSearchClassesTableView reloadData];
	[self hideLoadingView];
	
		
		
		
		// if exactly one result found forward user to that result
		if([classes count] == 1) {
			[StellarDetailViewController 
			 launchClass:(StellarClass *)[classesLoaded lastObject]
			 viewController: viewController];
		}
	//}
}

- (void) handleCouldNotReachStellarWithSearchTerms: (NSString *)searchTerms {
	//if([viewController.searchController.searchBar.text isEqualToString:searchTerms]) {
		//[viewController hideLoadingView];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Connection Failed", nil)
							  message:NSLocalizedString(@"Could not connect to server. Please try again later.", nil)
							  delegate:nil
							  cancelButtonTitle:@"OK" 
							  otherButtonTitles:nil];
		
	//	[viewController.searchController.searchResultsTableView reloadData];
		
		[alert show];
		[alert release];
	//}
}

- (void) handleTooManySearchResults {
	
	//[viewController hideLoadingView];
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:NSLocalizedString(@"Too Many Results", nil) 
						  message:NSLocalizedString(@"Too many results to display. Please refine your query", nil)
						  delegate:nil
						  cancelButtonTitle:@"OK" 
						  otherButtonTitles:nil];
	
	//[viewController.searchController.searchResultsTableView reloadData];
	
	[alert show];
	[alert release];
}

/* To make the complier happy */
-(void) reloadData {
}

/* To make the compiler happy */
-(void) handleTooManySearchResultsForMainSearch:(id)object {
}


@end

/*

@implementation LoadClassesInMainTable
@synthesize tableController;

- (void) classesLoaded: (NSArray *)aClassList {
	if(tableController.currentClassLoader == self) {
		tableController.classes = aClassList;
		[tableController hideLoadingView];
		//[tableController.tableView reloadData];
		[tableController.harvardClassesTableView reloadData];
	}
}

- (void) handleCouldNotReachStellar {
	if(tableController.currentClassLoader == self) {
		[tableController hideLoadingView];
		
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Connection Failed" 
							  message:[NSString stringWithFormat:@"Could not connect to retrieve classes for %@, please try again later", tableController.title]
							  delegate:tableController
							  cancelButtonTitle:@"OK" 
							  otherButtonTitles:nil];
		[alert show];
        [alert release];
	}
}
@end*/