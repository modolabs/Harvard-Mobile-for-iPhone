//
//  HoursAndLocationsViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/18/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "HoursAndLocationsViewController.h"
#import "MITUIConstants.h"
#import "Library.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "LibraryAlias.h"
#import "MITLoadingActivityView.h"
#import "AnalyticsWrapper.h"

@interface HoursAndLocationsViewController (Private)

- (NSArray *)currentLibraries;
- (void)showLoadingIndicator;
- (void)hideLoadingIndicator;

@end

@implementation HoursAndLocationsViewController
@synthesize showingMapView;
@synthesize librayLocationsMapView;
@synthesize showArchives;
@synthesize showBookmarks;
@synthesize typeOfRepo;

- (NSArray *)currentLibraries {
    
    NSArray *currentLibraries = nil;
    
    if (showBookmarks) {
        NSPredicate *bookmarkPred = [NSPredicate predicateWithFormat:@"name like library.primaryName AND library.isBookmarked == YES"];
        NSArray *bookmarkedLibraries = [CoreDataManager objectsForEntity:LibraryAliasEntityName matchingPredicate:bookmarkPred];
        currentLibraries = [bookmarkedLibraries sortedArrayUsingFunction:libraryNameSort context:nil];
        
    } else {    
        if (showArchives) {
            //if (showingOnlyOpen == NO) {
                currentLibraries = [[LibraryDataManager sharedManager] allArchives];
            //} else {
            //    currentLibraries = [[LibraryDataManager sharedManager] allOpenArchives];
            //}
        } else {
            if (showingOnlyOpen == NO) {
                currentLibraries = [[LibraryDataManager sharedManager] allLibraries];
            } else {
                currentLibraries = [[LibraryDataManager sharedManager] allOpenLibraries];
            }
        }
    }
    
    return currentLibraries;
}

- (void)pingLibraries {
    if (![[self currentLibraries] count]) {
        [self showLoadingIndicator];
        if (showArchives) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:showingOnlyOpen ? @selector(openLibrariesDidLoad) : @selector(librariesDidLoad)
                                                         name:LibraryRequestDidCompleteNotification
                                                       object:showingOnlyOpen ? LibraryDataRequestOpenLibraries : LibraryDataRequestArchives];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideLoadingIndicator)
                                                         name:LibraryRequestDidFailNotification
                                                       object:showingOnlyOpen ? LibraryDataRequestOpenLibraries : LibraryDataRequestArchives];
            [[LibraryDataManager sharedManager] requestArchives];
        } else {
            if (showingOnlyOpen) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openLibrariesDidLoad)
                                                             name:LibraryRequestDidCompleteNotification
                                                           object:LibraryDataRequestOpenLibraries];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideLoadingIndicator)
                                                             name:LibraryRequestDidFailNotification
                                                           object:LibraryDataRequestOpenLibraries];
                [[LibraryDataManager sharedManager] requestOpenLibraries];
            } else {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(librariesDidLoad)
                                                             name:LibraryRequestDidCompleteNotification
                                                           object:LibraryDataRequestLibraries];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideLoadingIndicator)
                                                             name:LibraryRequestDidFailNotification
                                                           object:LibraryDataRequestLibraries];
                [[LibraryDataManager sharedManager] requestLibraries];
            }
        }

    } else {
        if (showingOnlyOpen) {
            [self openLibrariesDidLoad];
        } else {
            [self librariesDidLoad];
        }
    }
}

- (void)showLoadingIndicator {
    MITLoadingActivityView *view = [[[MITLoadingActivityView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)] autorelease];
    view.tag = 4484;
    [self.view addSubview:view];
}

- (void)hideLoadingIndicator {
    UIView *view = [self.view viewWithTag:4484];
    [view removeFromSuperview];
}

-(void) viewDidLoad {
    
    if (showBookmarks) {
        CGRect frame = CGRectMake(0, 0, 400, 44);
        UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:15.0];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        self.navigationItem.titleView = label;
        label.text = NSLocalizedString(@"Bookmarked Repositories", @"");
    }
	
	gpsPressed = NO;
	showingOnlyOpen = NO;
	
	if (nil == _viewTypeButton)
		_viewTypeButton = [[[UIBarButtonItem alloc] initWithTitle:@"Map"
                                                            style:UIBarButtonItemStylePlain 
                                                           target:self
                                                           action:@selector(displayTypeChanged:)] autorelease];

	self.navigationItem.rightBarButtonItem = _viewTypeButton;

	NSString * typeOfRepoString = @"All Libraries";
	
	if (!showBookmarks && (nil != typeOfRepo) && ([typeOfRepo isEqualToString:@"Archives"]))
		typeOfRepoString = @"All Archives";
	
	CGFloat footerDisplacementFromTop = self.view.frame.size.height;
	
	if (!showBookmarks && ![typeOfRepo isEqualToString:@"Archives"])
		footerDisplacementFromTop -= NAVIGATION_BAR_HEIGHT;

	// segmented control
	if (!showBookmarks && ![typeOfRepo isEqualToString:@"Archives"]){
        NSArray *itemArray = [NSArray arrayWithObjects: typeOfRepoString, @"Open Now", nil];
        segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
        segmentedControl.tintColor = [UIColor darkGrayColor];
        segmentedControl.frame = CGRectMake(80, footerDisplacementFromTop + 8, 170, 30);
        segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        segmentedControl.selectedSegmentIndex = 0;
        segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        [segmentedControl addTarget:self
                             action:@selector(pickOne:)
                   forControlEvents:UIControlEventValueChanged];
        
        UIImage *backgroundImage = [UIImage imageNamed:MITImageNameScrollTabBackgroundOpaque];
        UIImageView *imageView = [[[UIImageView alloc] initWithImage:[backgroundImage stretchableImageWithLeftCapWidth:0 topCapHeight:0]] autorelease];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        imageView.frame = CGRectMake(0, footerDisplacementFromTop, imageView.frame.size.width, imageView.frame.size.height);
        imageView.tag = 1005;
        
		[self.view addSubview:imageView];
		[self.view addSubview:segmentedControl];
	}
	
	// map button
	UIImage *gpsImage = [UIImage imageNamed:@"maps/map_button_icon_locate.png"];
	NSArray *gpsArray = [NSArray arrayWithObjects: gpsImage, nil];
	gpsButtonControl = [[UISegmentedControl alloc] initWithItems:gpsArray];
	gpsButtonControl.tintColor = [UIColor darkGrayColor];
	gpsButtonControl.frame = CGRectMake(10,footerDisplacementFromTop + 8, 30, 30);
	gpsButtonControl.segmentedControlStyle = UISegmentedControlStyleBar;
	[gpsButtonControl addTarget:self
							action:@selector(gpsButtonPressed:)
				  forControlEvents:UIControlEventValueChanged];
	
	if (self.showingMapView == YES)
		[self.view addSubview:gpsButtonControl];

    // table view
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, footerDisplacementFromTop);
    _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_tableView.delegate = self;
	_tableView.dataSource = self;

    [self.view addSubview:_tableView];
    
    [self pingLibraries];
    
    NSMutableArray *queryParams = [NSMutableArray array];
    
    NSString *pageName = nil;
    if (showBookmarks) {
        pageName = @"/libraries/bookmarks";
        [queryParams addObject:@"type=library|archive"];
    } else if (showArchives) {
        pageName = @"/libraries/archives";
    } else {
        pageName = @"/libraries/libraries";
    }
    
    if (showingOnlyOpen) {
        [queryParams addObject:@"openOnly=1"];
    }
    if (showingMapView) {
        [queryParams addObject:@"mapView=1"];
    }
    
    pageName = [NSString stringWithFormat:@"%@?%@", pageName, [queryParams componentsJoinedByString:@"&"]];
    [[AnalyticsWrapper sharedWrapper] trackPageview:pageName];
}

- (void)librariesDidLoad {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryRequestDidCompleteNotification object:LibraryDataRequestLibraries];
    [self hideLoadingIndicator];
    [self setupSectionIndex];
    [_tableView reloadData];
}

- (void)openLibrariesDidLoad {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryRequestDidCompleteNotification object:LibraryDataRequestOpenLibraries];
    [self hideLoadingIndicator];
    [self setupSectionIndex];
    [_tableView reloadData];
}

- (void)setupSectionIndex {
	
    // table section index
    sectionIndexTitles = nil;
    
	NSMutableArray *tempIndexArray = [NSMutableArray array];
	for(LibraryAlias *lib in [self currentLibraries]) {
		if (![tempIndexArray containsObject:[lib.name substringToIndex:1]])
			[tempIndexArray addObject:[lib.name substringToIndex:1]];		
	}
    
    if ([tempIndexArray count] >= 8) {
        sectionIndexTitles = [[NSArray alloc] initWithArray:tempIndexArray];
    }
}

// called when user toggles "all" vs "open now" segment at the bottom
- (void) pickOne:(id)sender{
	//UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	//[segmentedControl selectedSegmentIndex];
	
	showingOnlyOpen = !showingOnlyOpen;
    [self pingLibraries];
    
	[_tableView reloadData];
	
	
	if (showingMapView == YES) {
        
        [librayLocationsMapView setAllLibraryLocations:[self currentLibraries]];
        
        [librayLocationsMapView viewWillAppear:YES];
	}
	
	//label.text = [segmentedControl titleForSegmentAtIndex: [segmentedControl selectedSegmentIndex]];
} 


-(void)displayTypeChanged:(id)sender {
	
	if([_viewTypeButton.title isEqualToString:@"Map"]) {
		[self setMapViewMode:YES animated:YES];
		showingMapView = YES;
	}
	else if ([_viewTypeButton.title isEqualToString:@"List"]) {
		[self setMapViewMode:NO animated:YES];
		showingMapView = NO;
	}
	
	if (self.showingMapView == YES)
		[self.view addSubview:gpsButtonControl];
	
	else {
		
		[gpsButtonControl removeFromSuperview];
		[gpsButtonControl retain];
	}
}

-(void) gpsButtonPressed:(id)sender {
	UISegmentedControl *segmentedController = (UISegmentedControl *)sender;
	segmentedController.selectedSegmentIndex = -1;

	if (showingMapView == YES)
	{
		//self.librayLocationsMapView.mapView.showsUserLocation = !self.librayLocationsMapView.mapView.showsUserLocation;
		
		if (!self.librayLocationsMapView.mapView.showsUserLocation) {	
			

				BOOL successful = [self.librayLocationsMapView mapView:self.librayLocationsMapView.mapView 
									   didUpdateUserLocation:self.librayLocationsMapView.mapView.userLocation];
			
				if (successful == YES)
					self.librayLocationsMapView.mapView.showsUserLocation = YES;
			
			}
		
		else {	
			self.librayLocationsMapView.mapView.showsUserLocation = NO;
				self.librayLocationsMapView.mapView.region = [self.librayLocationsMapView 
															  regionForAnnotations:self.librayLocationsMapView.mapView.annotations];

			
		}
	}		
		
	gpsPressed = !gpsPressed;
}


// set the view to either map or list mode
-(void) setMapViewMode:(BOOL)showMap animated:(BOOL)animated {
	//NSLog(@"map is showing=%i", _mapShowing);
	if (showMap == showingMapView) {
        return;
	}

	// flip to the correct view. 
	if (animated) {
		[UIView beginAnimations:@"flip" context:nil];
		[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.view cache:NO];
	}
	
	if (!showMap) {
		
		if (nil != self.librayLocationsMapView)
			[self.librayLocationsMapView.view removeFromSuperview];
		
        [self.view addSubview:_tableView];
        [_tableView reloadData];
        self.librayLocationsMapView = nil;
        _viewTypeButton.title = @"Map";


	} else {
		[_tableView removeFromSuperview];
				
		if (nil == librayLocationsMapView) {
            librayLocationsMapView = [[LibraryLocationsMapViewController alloc] initWithMapViewFrame:self.view.frame];
		}
		librayLocationsMapView.navController = self;
		
        librayLocationsMapView.view.frame = self.view.frame;
        [self.view addSubview:librayLocationsMapView.view];
        
        [librayLocationsMapView setAllLibraryLocations:[self currentLibraries]];
         
		[librayLocationsMapView viewWillAppear:YES];
		_viewTypeButton.title = @"List";

	}
	
	if(animated) {
		[UIView commitAnimations];
	}
	
}


/*- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}*/

- (void)viewDidUnload {
    [super viewDidUnload];

    
	// Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_tableView release];
    [librayLocationsMapView release];
    [segmentedControl release];
    [filterButtonControl release];
    [gpsButtonControl release];
    [sectionIndexTitles release];
    
    self.typeOfRepo = nil;
    
    [super dealloc];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	int count = [[self currentLibraries] count];
	
	return count;

}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LibraryAlias * lib = [[self currentLibraries] objectAtIndex:indexPath.section];
    
    UIFont *cellFont = [UIFont fontWithName:BOLD_FONT size:17];
    CGFloat width = tableView.frame.size.width - 20; // interior padding
    if (sectionIndexTitles != nil) {
        width -= 30;  // extra space for section index
    }
    CGFloat height = [lib.name sizeWithFont:cellFont].height; // first get one line
    height = [lib.name sizeWithFont:cellFont constrainedToSize:CGSizeMake(width, height * 2.2) lineBreakMode:UILineBreakModeWordWrap].height;

    return height + 20; // top and bottom padding
}



// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *optionsForMainViewTableStringConstant = @"listViewCellMultiLine";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:optionsForMainViewTableStringConstant];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:optionsForMainViewTableStringConstant] autorelease];
	}
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.textLabel.text = nil;

	LibraryAlias * lib = [[self currentLibraries] objectAtIndex:indexPath.section];
    
    UIFont *cellFont = [UIFont fontWithName:BOLD_FONT size:17];
    CGFloat width = tableView.frame.size.width - 20; // interior padding
    if (sectionIndexTitles != nil) {
        width -= 30;  // extra space for section index
    }
    CGFloat height = [lib.name sizeWithFont:cellFont].height; // first get one line
    height = [lib.name sizeWithFont:cellFont constrainedToSize:CGSizeMake(width, height * 2.2) lineBreakMode:UILineBreakModeWordWrap].height;
    UILabel *textLabel = (UILabel *)[cell.contentView viewWithTag:325];
    if (!textLabel) {
        textLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, width, height)] autorelease];
        textLabel.font = cellFont;
        textLabel.textColor = [UIColor colorWithHexString:@"#1A1611"];
        textLabel.tag = 325;
        textLabel.text = lib.name;
        textLabel.numberOfLines = 2;
        [cell.contentView addSubview:textLabel];
    } else {
        textLabel.frame = CGRectMake(10, 10, width, height);
    }
    textLabel.text = lib.name;
    
    return cell;
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {

    NSArray *tempLibraries = [self currentLibraries];
	int ind = 0;
	
	for(LibraryAlias *lib in tempLibraries) {
		if ([[lib.name substringToIndex:1] isEqualToString:title])
			break;
		ind++;
	}
	
	return ind;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	LibraryDetailViewController *vc = [[LibraryDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
	
	NSArray * tempArray;

    tempArray = [self currentLibraries];
    
	LibraryAlias * lib = (LibraryAlias *) [tempArray objectAtIndex:indexPath.section];
	vc.lib = lib;
	vc.otherLibraries = tempArray;
	vc.currentlyDisplayingLibraryAtIndex = indexPath.section;

    [self.navigationController pushViewController:vc animated:YES];

	[vc release];
	
}

@end
