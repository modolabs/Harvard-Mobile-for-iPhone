//
//  LibItemDetailViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 11/24/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "LibItemDetailViewController.h"
#import "MITUIConstants.h"
#import "CoreDataManager.h"
#import "ItemAvailabilityDetailViewController.h"
#import "LibraryLocationsMapViewController.h"
#import "LibrariesSearchViewController.h"
#import "LibraryAlias.h"
#import "MIT_MobileAppDelegate.h"
#import "RequestWebViewModalViewController.h"
#import "Foundation+MITAdditions.h"
#import "AnalyticsWrapper.h"

@interface LibItemDetailViewController (Private)

- (void)bookmarkButtonToggled:(id)sender;
- (void)mapButtonPressed:(id)sender;
- (void)authorLinkTapped:(id)sender;

- (void)setupTableHeader;
- (void)setupNavBar;

@end


@implementation LibItemDetailViewController
@synthesize bookmarkButtonIsOn;
@synthesize displayImage;


#pragma mark -
#pragma mark Initialization

-(id) initWithStyle:(UITableViewStyle)style 
		libraryItem:(LibraryItem *) libraryItem
		  itemArray: (NSDictionary *) results
	currentItemIdex: (int) itemIndex
	   imageDisplay:(BOOL) imageDisplay{
	
	self = [super initWithStyle:style];
	
	if (self) {

		libItem = [libraryItem retain];
		libItemDictionary = [results retain];
		currentIndex = itemIndex;
		displayImage = imageDisplay;
		
        locationsWithItem = nil;
        canShowMap = NO;
        displayLibraries = [[NSMutableArray alloc] init];
	}
	
	return self;
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self.tableView applyStandardColors];
	
    [self setupNavBar];
    [self setupTableHeader];
    
    if (!libItem.catalogLink) { // cataloglink is something itemdetail returns but search does not
        [self detailsDidLoadForItem:libItem];
    }
    
    [[LibraryDataManager sharedManager] setItemDelegate:self];
    [[LibraryDataManager sharedManager] setLibDelegate:self];
    
    [[LibraryDataManager sharedManager] requestDetailsForItem:libItem];

    // subscribe to libdetail notifications in case LibraryDataManager gets more info
    // while loading full availability
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryDetailsDidLoad:) name:LibraryRequestDidCompleteNotification object:LibraryDataRequestLibraryDetail];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryDetailsDidLoad:) name:LibraryRequestDidCompleteNotification object:LibraryDataRequestArchiveDetail];
    
    NSString *pageName = [NSString stringWithFormat:@"/libraries/detail?id=%@", libItem.itemId];
    [[AnalyticsWrapper sharedWrapper] trackPageview:pageName];
}

- (void)setupNavBar {
    if ([libItemDictionary count] && [libItemDictionary count] > 1) {
        UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                                                        [UIImage imageNamed:MITImageNameUpArrow],
                                                                                        [UIImage imageNamed:MITImageNameDownArrow], nil]];
        [segmentControl setMomentary:YES];
        [segmentControl addTarget:self action:@selector(showNextLibItem:) forControlEvents:UIControlEventValueChanged];
        segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
        segmentControl.frame = CGRectMake(0, 0, 80.0, segmentControl.frame.size.height);
        UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentControl];
        self.navigationItem.rightBarButtonItem = segmentBarItem;
        
        if (currentIndex == 0)
            [segmentControl setEnabled:NO forSegmentAtIndex:0];
        
        if (currentIndex == [libItemDictionary count] - 1)
            [segmentControl setEnabled:NO forSegmentAtIndex:1];
        
        [segmentControl release];
        [segmentBarItem release];
        
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void) setupTableHeader {
    
    if (headerView == nil) {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)]; // setting this to 1px tall makes sizeThatFits work in webViewDidFinishLoad
    }
    
    if (headerWebView == nil) {
        headerWebView = [[UIWebView alloc] initWithFrame:headerView.frame];
        headerWebView.backgroundColor = [UIColor clearColor];
        headerWebView.opaque = NO;
        headerWebView.delegate = self;
        
        for (id subview in headerWebView.subviews)
            if ([[subview class] isSubclassOfClass: [UIScrollView class]])
                ((UIScrollView *)subview).bounces = NO;
        
        
        [headerView addSubview:headerWebView];
    }
    
    // strings
    
    NSString *edition = libItem.edition;
    NSString *pubYear = [libItem.publisher length] ? [NSString stringWithFormat:@"%@ %@", libItem.publisher, libItem.year] : libItem.year;
    NSString *formatDetails = [NSString string];
    if (([libItem.formatDetail length] > 0) && ([libItem.typeDetail length] > 0))
        formatDetails = [NSString stringWithFormat:@"%@: %@", libItem.formatDetail, libItem.typeDetail];
    else if (([libItem.formatDetail length] == 0) && ([libItem.typeDetail length] > 0))
        formatDetails = [NSString stringWithFormat:@"%@", libItem.typeDetail];
    else if (([libItem.formatDetail length] > 0) && ([libItem.typeDetail length] == 0))
        formatDetails = [NSString stringWithFormat:@"%@", libItem.formatDetail];
    
    NSString *itemTitle = nil;
    if (displayImage) {
        itemTitle = [NSString stringWithFormat:@"%@\nHOLLIS # %@", libItem.title, libItem.itemId];
    } else if ([libItem.nonLatinTitle length]) {
        itemTitle = [NSString stringWithFormat:@"%@ (%@)", libItem.title, libItem.nonLatinTitle];
    } else {
        itemTitle = libItem.title;
    }
    
    NSString *authorString = nil;
    if (![libItem.author length] && [libItem.nonLatinAuthor length]) {
        authorString = [NSString stringWithFormat:@"<a href=\"searchAuthor\">%@</a>", libItem.nonLatinAuthor];
    } else if ([libItem.author length] && [libItem.nonLatinAuthor length]) {
        authorString = [NSString stringWithFormat:@"<a href=\"searchAuthor\">%@</a> (%@)", libItem.author, libItem.nonLatinAuthor];
    } else {
        authorString = [NSString stringWithFormat:@"<a href=\"searchAuthor\">%@</a>", libItem.author];
    }
    
    NSString *isBookmarked = ([libItem.isBookmarked boolValue]) ? @"on" : @"";
    NSString *mapDisplay = canShowMap ? @"inline-block" : @"none";
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"libraries/item_detail_header.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
        return;
    }
    
    NSArray *keys = [NSArray arrayWithObjects: @"__TITLE__", @"__AUTHOR__", @"__EDITION__", @"__PUBYEAR__", @"__FORMAT__", @"__MAPDISPLAY__", @"__BOOKMARKED__", nil];
    NSArray *values = [NSArray arrayWithObjects:itemTitle, authorString, edition, pubYear, formatDetails, mapDisplay, isBookmarked, nil];
    
    [htmlString replaceOccurrencesOfStrings:keys withStrings:values options:NSLiteralSearch];
    [headerWebView loadHTMLString:htmlString baseURL:baseURL];
    
	if (displayImage) {
        CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
        [thumbnail release];
        thumbnail = [[UIView alloc] initWithFrame:CGRectMake((screenRect.size.width - 150.0) / 2, headerView.frame.size.height, 150.0, 150.0)];
        thumbnail.backgroundColor = [UIColor clearColor];
        
        CGRect frame = headerView.frame;
        if (frame.size.height == headerWebView.frame.size.height) {
            frame.size.height += thumbnail.frame.size.height;
            headerView.frame = frame;
        }
        
        if (![thumbnail isDescendantOfView:headerView]) {
            [headerView addSubview:thumbnail];
        }
        
        [self addLoadingIndicator:thumbnail];
        
	} else {
        [thumbnail removeFromSuperview];
        [thumbnail release];
        thumbnail = nil;
    }
    
    self.tableView.tableHeaderView = headerView;
}

#pragma mark User Interaction

-(void) authorLinkTapped:(id)sender{
	NSArray *viewControllerArray = [self.navigationController viewControllers];
	NSUInteger parentViewControllerIndex = [viewControllerArray count] - 2;
	DLog(@"Parent view controller: %@", [viewControllerArray objectAtIndex:parentViewControllerIndex]);
	DLog(@"Total vc: %d", [viewControllerArray count]);
	
	//if ([sender isKindOfClass:[UIButton class]]){
        
        NSDictionary *params = nil;
        if ([libItem.authorLink length]) {
            params = [NSDictionary dictionaryWithObjectsAndKeys:libItem.authorLink, @"q", nil];
        } else if ([libItem.author length]) {
            params = [NSDictionary dictionaryWithObjectsAndKeys:libItem.author, @"author", nil];
        }
        
        if (params) {
			
			LibrariesSearchViewController *vc = [[LibrariesSearchViewController alloc] initWithViewController: nil];
            if ([libItem.authorLink length])
                vc.searchTerms = libItem.authorLink;
			
			JSONAPIRequest *apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:vc];
			BOOL requestWasDispatched = [apiRequest requestObjectFromModule:@"libraries"
														command:@"search"
													 parameters:params];
			
			if (requestWasDispatched) {
				vc.searchTerms = libItem.author;
				
				// break the navigation stack and only have the springboard, library-home and the next vc
				UIViewController * rootVC = [[self.navigationController viewControllers] objectAtIndex:0];
				UIViewController * nextVC = [[self.navigationController viewControllers] objectAtIndex:1];
				
				NSArray *controllersArray = [NSArray arrayWithObjects: rootVC, nextVC, vc,nil];
				
				[self.navigationController setViewControllers:controllersArray animated:YES];
				
			}
			
			[vc release];
		}
	//}
}

#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    CGRect frame = webView.frame;
    frame.size.height = 1;
    webView.frame = frame;
	
    CGSize size = [webView sizeThatFits:CGSizeZero];
    frame.size.height = size.height + 5; // the fact that the webview scrolls without extra height drives me insane
    webView.frame = frame;
    
    if (displayImage) {
        frame = thumbnail.frame;
        frame.origin.y = webView.frame.origin.y + webView.frame.size.height;
        thumbnail.frame = frame;
        
        frame = webView.frame;
        frame.size.height += thumbnail.frame.size.height;
    }
    
    headerView.frame = frame;
    self.tableView.tableHeaderView = headerView;
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	BOOL result = YES;
    
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		NSURL *url = [request URL];

        if ([[url path] rangeOfString:@"bookmark" options:NSBackwardsSearch].location != NSNotFound) {
            [self bookmarkButtonToggled:nil];
        } else if ([[url path] rangeOfString:@"map" options:NSBackwardsSearch].location != NSNotFound) {
            [self mapButtonPressed:nil];
        } else if ([[url path] rangeOfString:@"searchAuthor" options:NSBackwardsSearch].location != NSNotFound) {
            [self authorLinkTapped:nil];
        }
        result = NO;
	}
	return result;
}



#pragma mark -

-(void) showNextLibItem: (id) sender {
	
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger index = theControl.selectedSegmentIndex;
		
		if ([libItemDictionary count] > 1) {
			int tempLibIndex;
			
			if (index == 0) { // going up
				
				tempLibIndex = currentIndex - 1;
			}
			else
				tempLibIndex = currentIndex + 1;
			
			
			if ((tempLibIndex >= 0) && (tempLibIndex < [libItemDictionary count])){
				
				LibraryItem *nextLibItem = (LibraryItem *)[libItemDictionary objectForKey:[NSString stringWithFormat:@"%d", tempLibIndex +1]];
                if (nextLibItem) {
                    if (!nextLibItem.catalogLink) { // cataloglink is something itemdetail returns but search does not
                        [[LibraryDataManager sharedManager] requestDetailsForItem:nextLibItem];
                    }
                    currentIndex = tempLibIndex;
                    [libItem release];
                    libItem = [nextLibItem retain];
                    displayImage = [libItem.formatDetail isEqualToString:@"Image"];
                    canShowMap = NO;
                    [thumbnail removeFromSuperview];
                    [self setupNavBar]; // reset segmented control for paging
                    [self setupTableHeader];
                }
                
                [locationsWithItem release];
                locationsWithItem = nil;
                
                if (!libItem.catalogLink) { // cataloglink is something itemdetail returns but search does not
                    [[LibraryDataManager sharedManager] requestDetailsForItem:libItem];
                } else {
                    [self detailsDidLoadForItem:libItem];
                }
                if (![[libItem.formatDetail lowercaseString] isEqualToString:@"image"]) {
                    [[LibraryDataManager sharedManager] requestAvailabilityForItem:libItem.itemId];
                }
                
                [self.tableView reloadData];
			}			
		}
	}	
	
}

-(void) mapButtonPressed: (id) sender {
	
	if ([displayLibraries count] > 0) {
		LibraryLocationsMapViewController * vc = [[LibraryLocationsMapViewController alloc] initWithMapViewFrame:self.view.frame];
	
        [vc setAllLibraryLocations:displayLibraries];
		vc.navController = self;
		
		vc.title = @"Locations with Item";
		
		[self.navigationController pushViewController:vc animated:YES];
		[vc release];
	 }
	
}


-(void) bookmarkButtonToggled: (id) sender {
    /*
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *bookmarkButton = (UIButton *)sender;

        BOOL newBookmarkButtonStatus = !bookmarkButton.selected;
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"itemId == %@",libItem.itemId];
        LibraryItem *alreadyInDB = (LibraryItem *)[[CoreDataManager objectsForEntity:LibraryItemEntityName matchingPredicate:pred] lastObject];
        
        if (nil == alreadyInDB){
            return;
        }
        
        bookmarkButton.selected = newBookmarkButtonStatus;
        alreadyInDB.isBookmarked = [NSNumber numberWithBool:newBookmarkButtonStatus];
        
        [CoreDataManager saveData];
    }
    */
    libItem.isBookmarked = [NSNumber numberWithBool:![libItem.isBookmarked boolValue]];
    [CoreDataManager saveData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	
    if (displayImage == YES){
		
		if (nil != libItem.catalogLink )
			return 1;
		
		return 0;
	}
	
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (displayImage == YES){
		
		if (nil != libItem.catalogLink )
			return 2;
			
		return 0;
	}
	
	if (section == 0) {
        if ([libItem.onlineLink length]) {
			return 1;
		}
        return 0;
	}
	
	else if (section == 1){
        if (locationsWithItem == nil)
            return 1;
        
		return [locationsWithItem count];
	}
	
	return 0;
		
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell"; // for single-row cells
    
    if (displayImage == YES){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if (indexPath.row == 0) {
            NSInteger numberOfImages = [libItem.numberOfImages integerValue];
            if (!numberOfImages) {
                cell.textLabel.text = @"No images available";
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else {
                cell.textLabel.text = [NSString stringWithString:@"View larger image"];
            }
        } else if (indexPath.row == 1) {
			cell.textLabel.text = @"View more details";
        }
        return cell;
	}
	
	if (indexPath.section == 0) {
		
		if ([libItem.onlineLink length]) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.textLabel.text = @"Available Online";
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
			//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
		}
		else {
            return nil;
		}
	}
	
	else if (indexPath.section == 1) {
        
        if (locationsWithItem == nil) {
            UITableViewCell *cell4 = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell4 == nil) {
                cell4 = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            
            // TODO: this is not aligned well.
            // also we should probably make this into a reusable cell type instead of an instance method.
            [self addLoadingIndicator:cell4];
            
            cell4.textLabel.text = nil;
            cell4.selectionStyle = UITableViewCellSelectionStyleNone;
            cell4.accessoryType = UITableViewCellAccessoryNone;
            
            return cell4;
            
        }
        
		// cell for availability listings
		
		static NSString *CellIdentifier1 = @"CellLib";
        
		NSDictionary * tempDict = [locationsWithItem objectAtIndex:indexPath.row];
        
        NSArray *categories = (NSArray *)[tempDict objectForKey:@"categories"];
		
		NSMutableDictionary * dictWithStatuses = [NSMutableDictionary dictionary];
        
        for (NSDictionary *statusDict in categories) {
            NSString *holdingStatus = [statusDict objectForKey:@"holdingStatus"];
            
            NSInteger availCount = [[statusDict objectForKey:@"available"] integerValue];
            NSInteger requestCount = [[statusDict objectForKey:@"requestable"] integerValue];
            //NSInteger unavailCount = [[statusDict objectForKey:@"unavailable"] integerValue];
            NSInteger collectCount = [[statusDict objectForKey:@"collection"] integerValue];
            NSInteger total = [[statusDict objectForKey:@"total"] integerValue];

            NSString *statusString = nil;
            NSString *status = nil;
            
            if (collectCount > 0) {
                statusString = [NSString stringWithFormat:@"%d may be available", collectCount];
            } else {
                statusString = [NSString stringWithFormat:@"%d of %d available - %@", availCount, total, holdingStatus];
            }
            
            if (availCount > 0) {
                status = @"available";
            } else if (requestCount > 0) {
                status = @"request";
            } else {
                status = @"unavailable";
            }
            
            [dictWithStatuses setObject:status forKey:statusString];
        }
        
        // TODO: this might not be needed anymore
        if (![dictWithStatuses count]) {
            [dictWithStatuses setObject:@"unavailable" forKey:@"none available"];
        }
		
		NSString * libName = [tempDict objectForKey:@"name"];
        
        //DLog(@"%@", libName);
        //DLog(@"%@", [[dictWithStatuses allKeys] description]);

        Library *theLibrary = nil;
        // TODO: we can already get the library from locationsWithItem
        // displayLibraries is mostly redundant and each use of it can be replaced
        for (LibraryAlias *alias in displayLibraries) {
            if ([alias.name isEqualToString:libName]) {
                theLibrary = alias.library;
                break;
            }
        }
        
        UITableViewCell *cell1 = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (cell1 == nil) {
            cell1 = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];
        }
        cell1.textLabel.text = nil;
        
        CGFloat accessoryAdjustment;
        CGFloat cellWidth = tableView.frame.size.width - 20; // assume 10px padding left and right
        
        // accessory view
        if (![categories count]) {
            cell1.accessoryType = UITableViewCellAccessoryNone;
            cell1.selectionStyle = UITableViewCellSelectionStyleNone;
            accessoryAdjustment = 0;
        } else {
            cell1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell1.selectionStyle = UITableViewCellSelectionStyleGray;
            accessoryAdjustment = 30;
        }
        
        // "text label"

        UIFont *textFont = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
        CGSize size = [libName sizeWithFont:textFont];
        CGRect frame = CGRectMake(8, 10, cellWidth, size.height);
        UILabel *textLabel = (UILabel *)[cell1.contentView viewWithTag:21];
        if (!textLabel) {
            textLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.font = textFont;
            textLabel.tag = 21;
            [cell1.contentView addSubview:textLabel];
        } else {
            textLabel.frame = frame;
        }
        textLabel.text = libName;
        
        // "detail text label"
        
        UIColor *detailTextColor = [UIColor colorWithHexString:@"#554C41"];
        UIFont *detailTextFont = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
        
        frame.origin.y += frame.size.height + 2;
        size = [libName sizeWithFont:detailTextFont]; // just want height of one line
        frame.size.width = cellWidth - accessoryAdjustment;
        NSInteger addedLocationLines = (theLibrary && nil != currentLocation && [theLibrary.lat doubleValue]) ? 1 : 0;
        frame.size.height = (size.height + 2) * ([dictWithStatuses count] + addedLocationLines);
        
        UIView *otherLabels = [cell1.contentView viewWithTag:22];
        [otherLabels removeFromSuperview];
        
        otherLabels = [[[UIView alloc] initWithFrame:frame] autorelease];
        otherLabels.tag = 22;
        [cell1.contentView addSubview:otherLabels];
        
        frame = CGRectMake(0, 0, otherLabels.frame.size.width, size.height + 3);
        
        if (theLibrary && nil != currentLocation) {
            CGFloat latitude = [theLibrary.lat doubleValue];
            CGFloat longitude = [theLibrary.lon doubleValue];
            
            if (latitude != 0) {
                CLLocation * libLoc = [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
                CLLocationDistance dist = [currentLocation distanceFromLocation:libLoc];
                if (dist >= 0) {
                    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
                    label.backgroundColor = [UIColor clearColor];
                    label.font = detailTextFont;
                    label.textColor = detailTextColor;
                    label.text = [NSString stringWithFormat:@"%@ away", [self textForDistance:dist]];
                    [otherLabels addSubview:label];
                    
                    frame.origin.y += frame.size.height;
                }
            }
		}
        
        for (NSString *statusString in [dictWithStatuses allKeys]) {
            NSString *itemStatus = [dictWithStatuses objectForKey:statusString];
            NSString * imageString;
            
            if ([itemStatus isEqualToString:@"available"]) {
                imageString = @"dining/dining-status-open@2x.png";
            }
            else if ([itemStatus isEqualToString:@"unavailable"]) {
                imageString = @"dining/dining-status-closed@2x.png";
            }
            else 
                imageString = @"dining/dining-status-open-w-restrictions@2x.png";
            
            UIImage *image = [UIImage imageNamed:imageString];
            UIImageView *imView = [[[UIImageView alloc] initWithImage:image] autorelease];
            imView.frame = CGRectMake(0, frame.origin.y, 20, frame.size.height);
            
            [otherLabels addSubview:imView];
            
            frame.origin.x = imView.frame.size.width + 5;
            frame.size.width = cellWidth - frame.origin.x - accessoryAdjustment;
            
            UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
            label.text = statusString;
            label.font = detailTextFont;
            label.textColor = detailTextColor;
            label.backgroundColor = [UIColor clearColor];
            [otherLabels addSubview:label];
            
            frame.origin.y += frame.size.height;
        }
		
		return cell1;
	}
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	if (displayImage == YES){
		
		if (nil != libItem.catalogLink )
			return 42;
		
		return 0;
	}
    
    static NSString *oneLine = @"oneLine";

    NSInteger height = 0;

    // one line for library name label
    UIFont *textFont = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
    CGSize size = [oneLine sizeWithFont:textFont];
    height += size.height;
    
    // detail labels...
    UIFont *detailTextFont = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
    size = [oneLine sizeWithFont:detailTextFont];
    
    if (indexPath.section == 0 || ![locationsWithItem count]) {
        return tableView.rowHeight;
        
    } else { // section 1
        
        NSDictionary * tempDict = [locationsWithItem objectAtIndex:indexPath.row];
        NSArray *categories = [tempDict objectForKey:@"categories"];
        NSInteger numberOfStatusLines = [categories count] ? [categories count] : 1;

        NSString * libName = [tempDict objectForKey:@"name"];
        Library *theLibrary = nil;
        for (LibraryAlias *alias in displayLibraries) {
            if ([alias.name isEqualToString:libName]) {
                theLibrary = alias.library;
                break;
            }
        }
        NSInteger numberOfDistanceLines = (theLibrary && nil != currentLocation && [theLibrary.lat doubleValue]) ? 1 : 0;
        
        DLog(@"%@ %d %d", libName, numberOfStatusLines, numberOfDistanceLines);
        
        height += (size.height + 2) * (numberOfStatusLines + numberOfDistanceLines);
        
        return height + 22; // for top and bottom padding
    }
}



#pragma mark -
#pragma mark Table view delegate
- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
    if (displayImage == YES){
        NSString *libURL = nil;
        NSString *title = nil;
		if (indexPath.row == 0) {
            libURL = libItem.fullImageLink;
            title = @"Larger Image";
        } else if (indexPath.row == 1) {
            libURL = libItem.catalogLink;
            title = @"More Details";
        }
        
        if ([libURL length]) {
            MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
            RequestWebViewModalViewController *modalVC = [[[RequestWebViewModalViewController alloc] initWithRequestUrl:libURL title:title] autorelease];
            
            NSString *pageName = [NSString stringWithFormat:
                                  @"/libraries/request?itemId=%@",
                                  libItem.itemId];
            [[AnalyticsWrapper sharedWrapper] trackPageview:pageName];

            [appDelegate presentAppModalViewController:modalVC animated:YES];
        }
	}
	
	else if (indexPath.section == 0){
        if ([libItem.onlineLink length]) {
			NSURL *libURL = [NSURL URLWithString:libItem.onlineLink];
			if (libURL && [[UIApplication sharedApplication] canOpenURL:libURL]) {
				[[UIApplication sharedApplication] openURL:libURL];
			}
		}
	}
	
	
	else if ([locationsWithItem count]) {
		NSDictionary * libDict = [locationsWithItem objectAtIndex:indexPath.row];

        NSArray *collections = (NSArray *)[libDict objectForKey:@"categories"];
		if (([collections count] > 0) && (indexPath.section == 1)) {

            NSString * libName = [libDict objectForKey:@"name"];
            NSString * libId = [libDict objectForKey:@"id"];
            NSString * type = [libDict objectForKey:@"type"];
            
            LibraryAlias *alias = [[LibraryDataManager sharedManager] libraryAliasWithID:libId type:type name:libName];
            [CoreDataManager saveData];
            
            ItemAvailabilityDetailViewController *vc = [[ItemAvailabilityDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
			vc.title = @"Availability";
            vc.libraryItem = libItem;
            vc.libraryAlias = alias;
            vc.arrayWithAllLibraries = locationsWithItem;
            vc.currentIndex = indexPath.row;
            
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
		}
    }
		
}	

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	locationManager.delegate = nil;
	[locationManager release];
}


- (void)dealloc {
    
    if ([[LibraryDataManager sharedManager] libDelegate] == self) {
        [[LibraryDataManager sharedManager] setLibDelegate:nil];
    }
    
    if ([[LibraryDataManager sharedManager] itemDelegate] == self) {
        [[LibraryDataManager sharedManager] setItemDelegate:nil];
    }

	locationManager.delegate = nil;
	[locationManager release];
    [currentLocation release];
    
    [locationsWithItem release];
    [libItemDictionary release];
    [thumbnail release];
    [displayLibraries release];
    
    [headerWebView release];
    [headerView release];
	
    [super dealloc];
}


#pragma mark -

- (void)availabilityDidLoadForItemID:(NSString *)itemID result:(NSArray *)availabilityData {
    [locationsWithItem release];
    locationsWithItem = [availabilityData retain];
    
    [displayLibraries removeAllObjects];
    for (NSDictionary * tempDict in availabilityData) {
        NSString * displayName = [tempDict objectForKey:@"name"];
        NSString * identityTag = [tempDict objectForKey:@"id"];
        NSString * type = [tempDict objectForKey:@"type"];
    
        LibraryAlias *alias = [[LibraryDataManager sharedManager] libraryAliasWithID:identityTag type:type name:displayName];
        [CoreDataManager saveData];
        
        [displayLibraries addObject:alias];
        
        if ([alias.library.lat doubleValue] && !canShowMap) {
            canShowMap = YES;
            [headerWebView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"mapButton\").style.display = \"inline-block\";"];
        }
    }
    
    [self.tableView reloadData];
    
    if (canShowMap && !locationManager) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
    }
    
    [locationManager startUpdatingLocation];
    
    [self removeLoadingIndicator];
}

- (void)availabilityFailedToLoadForItemID:(NSString *)itemID {
    [locationsWithItem release];
    locationsWithItem = [[NSArray alloc] init];
    
    [self removeLoadingIndicator];
}

- (void)detailsDidLoadForItem:(LibraryItem *)aLibItem {

    if (![libItem.itemId isEqualToString:aLibItem.itemId]) {
        return;
    }

    if (libItem != aLibItem) {
        [libItem release];
        libItem = [aLibItem retain];
    }
    
    if (libItem.formatDetail && [[libItem.formatDetail lowercaseString] isEqualToString:@"image"]) {
        UIImage *image = [UIImage imageWithData:[aLibItem thumbnailImage]];
        if (image) {
            
            UIImageView *imageView = [[[UIImageView alloc] initWithImage:nil] autorelease];
            if (image.size.width > 150 || image.size.height > 150) {
                imageView.contentMode = UIViewContentModeScaleAspectFit;
            } else {
                imageView.contentMode = UIViewContentModeCenter;
            }
            CGFloat scaledImageHeight = (image.size.width > image.size.height) ? floor(150.0 * image.size.height / image.size.width) : 150.0;

            imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
            imageView.frame = CGRectMake(0, 0, 150, scaledImageHeight);
            imageView.backgroundColor = [UIColor clearColor];
            imageView.image = image;
            
            CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
            
            CGFloat imageX = (screenRect.size.width - imageView.frame.size.width) / 2;
            CGFloat imageY = thumbnail.frame.origin.y;
            thumbnail.frame = CGRectMake(imageX, imageY, imageView.frame.size.width, imageView.frame.size.height + 10);
            [thumbnail addSubview:imageView];
            
            if (![thumbnail isDescendantOfView:self.tableView.tableHeaderView]) {
                [headerView addSubview:thumbnail];
            }
            headerView.frame = CGRectMake(0, 0, headerWebView.frame.size.width, thumbnail.frame.size.height + headerWebView.frame.size.height);
            
        } else {
            [thumbnail removeFromSuperview];
            headerView.frame = headerWebView.frame;
        }
        
        self.tableView.tableHeaderView = headerView;

        //[self.tableView setTableHeaderView:self.tableView.tableHeaderView]; // force resize of header
    
        [self removeLoadingIndicator];
        [self.tableView reloadData];

    } else {
        [self setupTableHeader];
        [[LibraryDataManager sharedManager] requestAvailabilityForItem:libItem.itemId];
    }
}

- (void)detailsFailedToLoadForItemID:(NSString *)itemID {
    if (![libItem.itemId isEqualToString:itemID]) {
        return;
    }
    if (libItem.formatDetail && [[libItem.formatDetail lowercaseString] isEqualToString:@"image"]) {
        [self removeLoadingIndicator];
    }
}

// only called for non-image types
//- (void)libraryDetailsDidLoad:(NSNotification *)aNotification {


- (void)detailsDidLoadForLibrary:(NSString *)libID type:(NSString *)libType {
    BOOL couldShowMap = canShowMap;
    for (LibraryAlias *anAlias in displayLibraries) {
        if ([anAlias.library.lat doubleValue]) {
            canShowMap = YES;
        }
    }
    
    if (couldShowMap != canShowMap) {
        // make sure map pin shows up in header
        [headerWebView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"mapButton\").style.display = \"inline-block\";"]; // canShowMap will only be YES at this point
        [self.tableView reloadData]; // make sure distances show up if location is present
    }
}

- (void)detailsDidFailToLoadForLibrary:(NSString *)libID type:(NSString *)libType {
    ;
}


#pragma mark loading-indicator
- (void)addLoadingIndicator:(UIView *)view
{
	if (loadingIndicator == nil) {
		static NSString *loadingString = @"Checking availability...";
		UIFont *loadingFont = [UIFont fontWithName:STANDARD_FONT size:17.0];
		CGSize stringSize = [loadingString sizeWithFont:loadingFont];
		
        CGFloat verticalPadding = view.frame.size.height/2 - 5;
        CGFloat horizontalPadding = 5.0; //view.frame.size.width/2 - 50;
        CGFloat horizontalSpacing = 15.0;
		// CGFloat cornerRadius = 8.0;
        
        UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray;
		UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
		// spinny.center = CGPointMake(spinny.center.x + horizontalPadding, spinny.center.y + verticalPadding);
		spinny.center = CGPointMake(horizontalPadding, verticalPadding);
		[spinny startAnimating];
        
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(horizontalPadding + horizontalSpacing, verticalPadding -10, stringSize.width, stringSize.height + 2.0)];
		label.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
		label.text = loadingString;
		label.font = loadingFont;
		label.backgroundColor = [UIColor clearColor];
        
		loadingIndicator = [[UIView alloc] initWithFrame:CGRectMake(20.0, 5.0, view.frame.size.width/2 - 20, 0.8*view.frame.size.height - 5)];
		
		if (displayImage == YES) {
			loadingIndicator.frame = CGRectMake(20.0, 5.0, view.frame.size.width/3, 0.8*view.frame.size.height - 5);
			label.frame = CGRectMake(horizontalPadding + horizontalSpacing - 30, verticalPadding -10, stringSize.width, stringSize.height + 2.0);
			spinny.center = CGPointMake(horizontalPadding - 30, verticalPadding);
			[loadingIndicator setBackgroundColor:[UIColor clearColor]];
		}
		
		else
			[loadingIndicator setBackgroundColor:[UIColor whiteColor]];
		
		[loadingIndicator addSubview:spinny];
		[spinny release];
		[loadingIndicator addSubview:label];
		[label release];
		
	}
	
	
	[view addSubview:loadingIndicator];
}

- (void)removeLoadingIndicator
{
	[loadingIndicator removeFromSuperview];
	[loadingIndicator release];
	loadingIndicator = nil;
	
}


#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
	
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 120.0) return;
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
  
    [currentLocation release];
	currentLocation = [newLocation retain];
    
    DLog(@"current location is %@", [currentLocation description]);
    
	[locationManager stopUpdatingLocation];
    
    if ([locationsWithItem count]) {
        [self.tableView reloadData];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error{
    [currentLocation release];
	currentLocation = nil;
	[locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"could not update location");
    
    [currentLocation release];
	currentLocation = nil;
	[locationManager stopUpdatingLocation];

#if TARGET_IPHONE_SIMULATOR
    CLLocationCoordinate2D coord;
    switch (arc4random() % 3) {
        case 0:
            NSLog(@"we are in kendall square");
            coord.latitude = 42.3629;
            coord.longitude = -71.0862;
            break;
        case 1:
            NSLog(@"we are in alewife");
            coord.latitude = 42.3948;
            coord.longitude = -71.1446;
            break;
        default:
            NSLog(@"we are nowhere");
            break;
    }
    
    if (coord.latitude) {
        currentLocation = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
        if ([locationsWithItem count]) {
            [self.tableView reloadData];
        }
    }
#endif
}

- (NSString *)textForDistance:(CLLocationDistance)meters {
    NSString *measureSystem = [[NSLocale currentLocale] objectForKey:NSLocaleMeasurementSystem];
    BOOL isMetric = ![measureSystem isEqualToString:@"U.S."];
    
    NSString *distanceString;

    if (!isMetric) {
        CGFloat feet = meters / METERS_PER_FOOT;
        if (feet * 2 > FEET_PER_MILE) {
            distanceString = [NSString stringWithFormat:@"%.1f miles", (feet / FEET_PER_MILE)];
        } else {
            distanceString = [NSString stringWithFormat:@"%.0f feet",feet];
        }
    } else {
        if (meters > 1000) {
            distanceString = [NSString stringWithFormat:@"%.1f km", (meters / 1000)];
        } else {
            distanceString = [NSString stringWithFormat:@"%.0f meters", meters];
        }
    }
    
    return distanceString;
}

@end

