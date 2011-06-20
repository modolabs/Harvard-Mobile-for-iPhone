#import "CalendarDetailViewController.h"
#import "MITCalendarEvent.h"
#import "EventCategory.h"
#import "MITUIConstants.h"
#import "MultiLineTableViewCell.h"
#import "Foundation+MITAdditions.h"
#import "MapBookmarkManager.h"
#import "MapSearchResultAnnotation.h"
#import "AnalyticsWrapper.h"
#import "MITMailComposeController.h"

#define WEB_VIEW_PADDING 10.0
#define BUTTON_PADDING 10.0
#define kCategoriesWebViewTag 521
#define kDescriptionWebViewTag 516

enum CalendarDetailRowTypes {
	CalendarDetailRowTypeTime,
	CalendarDetailRowTypeLocation,
	CalendarDetailRowTypePhone,
	CalendarDetailRowTypeURL,
	CalendarDetailRowTypeTicketURL,
	CalendarDetailRowTypeEmail,
	CalendarDetailRowTypeDescription,
	CalendarDetailRowTypeCategories
};

@implementation CalendarDetailViewController

@synthesize event, events, tableView = _tableView;

- (void)loadView {
    [super loadView];
	
	self.shareDelegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Detail";
	
	// setup table view
	self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)
												  style:UITableViewStylePlain];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	[self.view addSubview:_tableView];
    
    if (isRegularEvent) {
        [self setupShareButton];
    }
	
	// set up table rows
	[self reloadEvent];
	
	descriptionString = nil;
    categoriesString = nil;
	
	// setup nav bar
	if (self.events.count > 1) {
		UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
																						[UIImage imageNamed:MITImageNameUpArrow],
																						[UIImage imageNamed:MITImageNameDownArrow], nil]];
		[segmentControl setMomentary:YES];
		[segmentControl addTarget:self action:@selector(showNextEvent:) forControlEvents:UIControlEventValueChanged];
		segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
		segmentControl.frame = CGRectMake(0, 0, 80.0, segmentControl.frame.size.height);
		UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentControl];
		self.navigationItem.rightBarButtonItem = segmentBarItem;
		[segmentControl release];
		[segmentBarItem release];
	}
	
	descriptionHeight = 0;
    
    NSString *detailString = [NSString stringWithFormat:@"/calendar/detail?id=%@", self.event.eventID];
    [[AnalyticsWrapper sharedWrapper] trackPageview:detailString];
}

- (void)showNextEvent:(id)sender
{
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger i = theControl.selectedSegmentIndex;
		NSInteger currentEventIndex = [self.events indexOfObject:self.event];
		if (i == 0) { // previous
			currentEventIndex--;
			if (currentEventIndex == -1) {
				currentEventIndex = [self.events count] - 1;
			}
		} else {
			currentEventIndex++;
			if (currentEventIndex == [self.events count]) {
				currentEventIndex = 0;
			}
		}
		self.event = [self.events objectAtIndex:currentEventIndex];
		[self reloadEvent];
    }
}

// helper function that maintains consistency of descriptionString and descriptionHeight
-(void)setDescriptionString:(NSString *)description
{
	descriptionString = [[self htmlStringFromString:description] retain];
	
	return;
}

- (void)reloadEvent
{
	[self setupHeader];
	
	if (numRows > 0) {
		free(rowTypes);
	}
	
	rowTypes = malloc(sizeof(CalendarEventListType) * 6);
	numRows = 0;
	if (self.event.start) {
		rowTypes[numRows] = CalendarDetailRowTypeTime;
		numRows++;
	}
	if (self.event.shortloc || self.event.location) {
		rowTypes[numRows] = CalendarDetailRowTypeLocation;
		numRows++;
	}
	if (self.event.phone) {
		rowTypes[numRows] = CalendarDetailRowTypePhone;
		numRows++;
	}
	if (self.event.url) {
		rowTypes[numRows] = CalendarDetailRowTypeURL;
		numRows++;
	}
	if (self.event.ticketUrl) {
		rowTypes[numRows] = CalendarDetailRowTypeTicketURL;
		numRows++;
	}
	if (self.event.email) {
		rowTypes[numRows] = CalendarDetailRowTypeEmail;
		numRows++;
	}
	if (self.event.summary) {
		rowTypes[numRows] = CalendarDetailRowTypeDescription;
        [descriptionString release];

		//sets the description string and height of the views
		[self setDescriptionString:self.event.summary];
		
		numRows++;
	}
	if ([self.event.categories count] > 0 && isRegularEvent) {
        rowTypes[numRows] = CalendarDetailRowTypeCategories;
        
        [categoriesString release];
        
        UIFont *cellFont = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
        CGSize textSize = [CalendarTag sizeWithFont:cellFont];
        // one line height per category, +1 each for "Categorized as" and <ul> spacing, 5px between lines
        categoriesHeight = (textSize.height + 5.0) * ([event.categories count] + 2);
		
        numRows++;
	}
	
	[self.tableView reloadData];
}

- (void)setupShareButton {
    if (!shareButton) {
        CGRect tableFrame = self.tableView.frame;
        shareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        UIImage *buttonImage = [UIImage imageNamed:@"global/share.png"];
        shareButton.frame = CGRectMake(tableFrame.size.width - buttonImage.size.width - BUTTON_PADDING,
                                       BUTTON_PADDING,
                                       buttonImage.size.width,
                                       buttonImage.size.height);
        [shareButton setImage:buttonImage forState:UIControlStateNormal];
        [shareButton setImage:[UIImage imageNamed:@"global/share_pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
        [shareButton addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupHeader {	
	CGRect tableFrame = self.tableView.frame;
	
	CGFloat titlePadding = 10.0;
    CGFloat titleWidth;
    if (isRegularEvent) {
        titleWidth = tableFrame.size.width - shareButton.frame.size.width - BUTTON_PADDING * 2 - titlePadding;
        self.tableView.separatorColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    } else {
        titleWidth = tableFrame.size.width - titlePadding * 2;
        self.tableView.separatorColor = [UIColor whiteColor];
    }
	UIFont *titleFont = [UIFont fontWithName:CONTENT_TITLE_FONT size:22.0];
	CGSize titleSize = [self.event.title sizeWithFont:titleFont
									constrainedToSize:CGSizeMake(titleWidth, 2010.0)];
	UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(titlePadding, titlePadding, titleSize.width, titleSize.height)];
	titleView.lineBreakMode = UILineBreakModeWordWrap;
	titleView.numberOfLines = 0;
	titleView.font = titleFont;
	titleView.text = self.event.title;
    titleView.textColor = CELL_STANDARD_FONT_COLOR;
	
	// if title is very short, add extra padding so button won't be too close to first cell
	if (titleSize.height < shareButton.frame.size.height) {
		titleSize.height += BUTTON_PADDING;
	}
	
	CGRect titleFrame = CGRectMake(0.0, 0.0, tableFrame.size.width, titleSize.height + titlePadding * 2);
	self.tableView.tableHeaderView = [[[UIView alloc] initWithFrame:titleFrame] autorelease];
	[self.tableView.tableHeaderView addSubview:titleView];
    if (isRegularEvent) {
        [self.tableView.tableHeaderView addSubview:shareButton];
    }
	[titleView release];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)setEvent:(MITCalendarEvent *)anEvent {
    event = anEvent;
    
    [descriptionString release];
    [categoriesString release];
	
    descriptionString = nil;
    categoriesString = nil;
	
    isRegularEvent = [self.event.isRegular boolValue];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return numRows;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSInteger rowType = rowTypes[indexPath.row];
	NSString *CellIdentifier = [NSString stringWithFormat:@"%d", rowType];
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        if (rowType == CalendarDetailRowTypeCategories || rowType == CalendarDetailRowTypeDescription) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
    }
    
	[cell applyStandardFonts];
	
	switch (rowType) {
		case CalendarDetailRowTypeTime:
			cell.textLabel.text = [event dateStringWithDateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterShortStyle separator:@"\n"];
			break;
		case CalendarDetailRowTypeLocation:
			cell.textLabel.text = (event.location != nil) ? event.location : event.shortloc;
			if ([event hasCoords]) {
				cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
			} else {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewBlank];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
			break;
		case CalendarDetailRowTypePhone:
			cell.textLabel.text = event.phone;
			cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];			
			break;
		case CalendarDetailRowTypeURL:
			cell.textLabel.text = @"Visit Website";
			cell.textLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
			cell.textLabel.textColor = EMBEDDED_LINK_FONT_COLOR;
			cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
			break;
			
		case CalendarDetailRowTypeTicketURL:
			cell.textLabel.text = @"Link to Tickets";
			cell.textLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
			cell.textLabel.textColor = EMBEDDED_LINK_FONT_COLOR;
			cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
			break;
			
		case CalendarDetailRowTypeEmail:
			cell.textLabel.text = event.email;
			cell.textLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
			cell.textLabel.textColor = EMBEDDED_LINK_FONT_COLOR;
			cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
			break;
			
		case CalendarDetailRowTypeDescription:
        {		
			//sets the description string and height of the views
			[self setDescriptionString:self.event.summary];
			
            UIWebView *webView = (UIWebView *)[cell viewWithTag:kDescriptionWebViewTag];
			webView.delegate = self;
			CGFloat webViewHeight;
			
			if (descriptionHeight > 0) {
				webViewHeight = descriptionHeight;
			} else {
				webViewHeight =50;
			}
			
			CGRect frame = CGRectMake(WEB_VIEW_PADDING, WEB_VIEW_PADDING, self.tableView.frame.size.width - 2 * WEB_VIEW_PADDING, webViewHeight);
            if (!webView) {
                webView = [[UIWebView alloc] initWithFrame:frame];
				//webview.frame.size.width
				[webView loadHTMLString:descriptionString baseURL:nil];
                webView.tag = kDescriptionWebViewTag;
                webView.delegate = self;
                [cell.contentView addSubview:webView];
				[(UIScrollView*)[webView.subviews objectAtIndex:0] setAlwaysBounceVertical:NO];
				[(UIScrollView*)[webView.subviews objectAtIndex:0] setAlwaysBounceHorizontal:NO];
                [webView release];
            } else {
                webView.frame = frame;
                [webView loadHTMLString:descriptionString baseURL:nil];
				[(UIScrollView*)[webView.subviews objectAtIndex:0] setAlwaysBounceVertical:NO];
				[(UIScrollView*)[webView.subviews objectAtIndex:0] setAlwaysBounceHorizontal:NO];
			}
			
			break;
        }
		case CalendarDetailRowTypeCategories:
        {
			NSMutableString *categoriesBody = [NSMutableString stringWithString:@"Gazette Classification: <ul>"];
			
			NSMutableArray *tempCats = [NSMutableArray array];
			
			for (EventCategory *category in event.categories) {
				[tempCats addObject:category];
			}
			
			NSArray *tempA = [tempCats sortedArrayUsingSelector:@selector(compare:)];
			
			for (EventCategory *category in tempA) {
				NSString *catIDString = [NSString stringWithFormat:@"catID=%d", [category.catID intValue]];
				NSURL *categoryURL = [NSURL internalURLWithModuleTag:CalendarTag path:CalendarStateCategoryEventList query:catIDString];
				//NSURL *categoryURL = [NSURL internalURLWithModuleTag:CalendarTag path:CalendarStateCategoryEventList query:nil];
				[categoriesBody appendString:[NSString stringWithFormat:
											  @"<li><a href=\"%@\">%@</a></li>", [categoryURL absoluteString], category.title]];
			}
			
			[categoriesBody appendString:@"</ul>"];
			categoriesString = [[self htmlStringFromString:categoriesBody] retain];
		
			UIFont *cellFont = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
			cell.textLabel.textColor = EMBEDDED_LINK_FONT_COLOR;
			CGSize textSize = [CalendarTag sizeWithFont:cellFont];
			// one line height per category, +1 each for "Categorized as" and <ul> spacing, 5px between lines
			categoriesHeight = (textSize.height + 5.0) * ([event.categories count] + 2);
			
            UIWebView *webView = (UIWebView *)[cell viewWithTag:kCategoriesWebViewTag];
            CGRect frame = CGRectMake(WEB_VIEW_PADDING, WEB_VIEW_PADDING, self.tableView.frame.size.width - 2 * WEB_VIEW_PADDING, categoriesHeight);
            if (!webView) {
                webView = [[UIWebView alloc] initWithFrame:frame];
                webView.delegate = self;
                [webView loadHTMLString:categoriesString baseURL:nil];
                webView.tag = kCategoriesWebViewTag;
                [cell.contentView addSubview:webView];
                [webView release];
            } else {
                webView.frame = frame;
                [webView loadHTMLString:categoriesString baseURL:nil];
            }
			
			break;
        }
	}
	
    return cell;
}

- (NSString *)htmlStringFromString:(NSString *)source {
	NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
	NSURL *fileURL = [NSURL URLWithString:@"events/events_template.html" relativeToURL:baseURL];
	NSError *error;
	NSMutableString *target = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
	if (!target) {
		DLog(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
	}
	[target replaceOccurrencesOfStrings:[NSArray arrayWithObject:@"__BODY__"] 
							withStrings:[NSArray arrayWithObject:source] 
								options:NSLiteralSearch];
	return target;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger rowType = rowTypes[indexPath.row];
	
	NSString *cellText = nil;
	UIFont *cellFont = nil;
    UITableViewCellAccessoryType accessoryType;
	
	switch (rowType) {
		case CalendarDetailRowTypeCategories:
			return categoriesHeight;
			
		case CalendarDetailRowTypeTime:
			cellText = [event dateStringWithDateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterShortStyle separator:@"\n"];
			cellFont = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
            accessoryType = UITableViewCellAccessoryNone;
			break;
		case CalendarDetailRowTypeDescription:
			// this is the same font defined in the html template
			if(descriptionHeight > 0) {
				return (CGFloat) descriptionHeight;
			} else {
				return 50;
			}			
			break;
		case CalendarDetailRowTypeLocation:
			cellText = (event.location != nil) ? event.location : event.shortloc;
			cellFont = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
			// 33 and 21 are from MultiLineTableViewCell.m
            accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			//constraintWidth = tableView.frame.size.width - 33.0 - 21.0;
			break;
		default:
			return 44.0;
	}
    
    return [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleDefault
                                                tableView:tableView 
                                                     text:cellText
                                             maxTextLines:0
                                               detailText:nil
                                           maxDetailLines:0
                                                     font:cellFont 
                                               detailFont:nil 
                                            accessoryType:accessoryType
                                                cellImage:NO];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSInteger rowType = rowTypes[indexPath.row];
	
	switch (rowType) {
		case CalendarDetailRowTypeLocation:
            if ([event hasCoords]) {
                [[MapBookmarkManager defaultManager] pruneNonBookmarks];
                
                CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([event.latitude floatValue], [event.longitude floatValue]);
                ArcGISMapAnnotation *annotation = [[[ArcGISMapAnnotation alloc] initWithCoordinate:coord] autorelease];
                annotation.name = event.location;
                annotation.uniqueID = [NSString stringWithFormat:@"%@@%.4f,%.4f", event.location, coord.latitude, coord.longitude];
                [[MapBookmarkManager defaultManager] saveAnnotationWithoutBookmarking:annotation];
                
                NSURL *internalURL = [NSURL internalURLWithModuleTag:CampusMapTag
                                                                path:LocalPathMapsSelectedAnnotation
                                                               query:annotation.uniqueID];
                
                [[UIApplication sharedApplication] openURL:internalURL];
            }
			break;
		case CalendarDetailRowTypePhone:
		{
			NSString *phoneString = [event.phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
			NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneString]];
			if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
				[[UIApplication sharedApplication] openURL:phoneURL];
			}
			break;
		}
		case CalendarDetailRowTypeURL:
		{
			NSURL *eventURL = [NSURL URLWithString:event.url];
			if (event.url && [[UIApplication sharedApplication] canOpenURL:eventURL]) {
				[[UIApplication sharedApplication] openURL:eventURL];
			}
			break;
		}
			
		case CalendarDetailRowTypeTicketURL:
		{
			NSURL *eventURL = [NSURL URLWithString:event.ticketUrl];
			if (event.ticketUrl && [[UIApplication sharedApplication] canOpenURL:eventURL]) {
				[[UIApplication sharedApplication] openURL:eventURL];
			}
			break;
		}
			
		case CalendarDetailRowTypeEmail:
		{
			NSString *subject = [self emailSubject];
			[MITMailComposeController presentMailControllerWithEmail:event.email subject:subject body:nil];
			break;
		}
		default:
			break;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark ShareItemDelegate

- (NSString *)actionSheetTitle {
	return [NSString stringWithString:@"Share this event"];
}

- (NSString *)emailSubject {
	return [NSString stringWithFormat:@"Harvard Event: %@", event.title];
}

- (NSString *)emailBody {
	
	NSString *summary = event.summary;
	NSArray *summaryArray = [summary componentsSeparatedByString:@"<"];
	
	if ([summaryArray count] > 0)
		summary = [summaryArray objectAtIndex:0];


	return [NSString stringWithFormat:@"I thought you might be interested in this event...\n%@\n%@\n%@", event.title, [self twitterUrl], summary];
}

- (NSString *)fbDialogPrompt {
	return nil;
}

- (NSString *)fbDialogAttachment {
    
    NSString *escapedTitle = [event.title stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    NSString *attachment = [NSString stringWithFormat:
                            @"{\"name\":\"%@\","
                            "\"href\":\"%@\","
                            "\"description\":\"%@\"}",
                            escapedTitle,
                            [self twitterUrl],
                            [event.summary stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    return attachment;
}

- (NSString *)twitterUrl {
    if ([event.url length])
        return event.url;
	return [NSString stringWithFormat:@"http://%@/calendar/detail.php?id=%d", MITMobileWebDomainString, [event.eventID integerValue]];
}

- (NSString *)twitterTitle {
	return event.title;
}

#pragma mark JSONAPIDelegate for background refreshing of events

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
	if (result && [result isKindOfClass:[NSDictionary class]]) {
		[self.event updateWithDict:result];
		[self reloadEvent];
	}
}


- (void)dealloc {
	self.event = nil;
	free(rowTypes);
	
	[shareButton release];
    [categoriesString release];
    [descriptionString release];
    [super dealloc];
}


#pragma mark -
#pragma mark UIWebView delegation

-(void)webViewDidFinishLoad:(UIWebView *)webView {
	CGSize size = [webView sizeThatFits:CGSizeZero];
    
    if (webView.tag == kDescriptionWebViewTag) {
        NSInteger newDescriptionHeight = size.height;
        if(newDescriptionHeight != descriptionHeight) {
            descriptionHeight = newDescriptionHeight;
            [self.tableView reloadData];
        }	
    } else if (webView.tag == kCategoriesWebViewTag) {
        NSInteger newCategoriesHeight = size.height + 10;
        if(newCategoriesHeight != categoriesHeight) {
            categoriesHeight = newCategoriesHeight;
            [self.tableView reloadData];
        }
    }
	return;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}
	
	return YES;
}


@end
