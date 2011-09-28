#import "MITMapDetailViewController.h"
#import "TabViewControl.h"
#import "MapSearchResultAnnotation.h"
#import "CampusMapViewController.h"
#import "NSString+SBJSON.h"
#import "MITUIConstants.h"
#import "MIT_MobileAppDelegate.h"
#import "MapBookmarkManager.h"
#import "AnalyticsWrapper.h"

@interface MITMapDetailViewController(Private)

// load the content of the current annotation into the view.
-(void) loadAnnotationContent;

@end


@implementation MITMapDetailViewController
@synthesize annotation = _annotation;
@synthesize campusMapVC = _campusMapVC;
@synthesize queryText = _queryText;
@synthesize imageConnectionWrapper;
@synthesize startingTab = _startingTab;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		networkActivity = NO;
	}
	return self;
}

- (void)dealloc 
{	
	self.annotation = nil;
	if (networkActivity) {
		[self.imageConnectionWrapper cancel];
	}
	self.imageConnectionWrapper.delegate = nil;
	self.imageConnectionWrapper = nil;
	
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_tabViews = [[NSMutableArray alloc] initWithCapacity:2];
    _whatsHereView.delegate = self;
	
	// check if this item is already bookmarked
	MapBookmarkManager* bookmarkManager = [MapBookmarkManager defaultManager];
	if ([bookmarkManager isBookmarked:self.annotation.uniqueID]) {
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on.png"] forState:UIControlStateNormal];
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed.png"] forState:UIControlStateHighlighted];
	}
	
	[_mapView addAnnotation:self.annotation];
    // TODO: use something else for this map span
    MKCoordinateSpan span = MKCoordinateSpanMake(0.001, 0.001);
    CLLocationCoordinate2D center = self.annotation.coordinate;
    // move the region up a bit so the pin shows up fully
    center.latitude += 0.0001;
    _mapView.region = MKCoordinateRegionMake(center, span);

    // TODO: find a way to add rounded corner to this
	//_mapView.layer.cornerRadius = 6.0;
	//_mapViewContainer.layer.cornerRadius = 8.0;
	
	// buffer the annotation by 5px so it fits in the map thumbnail window.
	//CGPoint screenPoint = [_mapView unscaledScreenPointForCoordinate:self.annotation.coordinate];
	//screenPoint.y -= 5;
	//CLLocationCoordinate2D coordinate = [_mapView coordinateForScreenPoint:screenPoint];
	//_mapView.centerCoordinate = coordinate;
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Google Map"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																			  action:@selector(externalMapButtonPressed:)] autorelease];
	
	// never resize the tab view container below this height. 
	_tabViewContainerMinHeight = _tabViewContainer.frame.size.height;
	
	// if the annotation was not fully loaded, go get the rest of the data. 
	if (!self.annotation.dataPopulated) {
		// show the loading result view and hide the rest
		_nameLabel.hidden = YES;
		_locationLabel.hidden = YES;
		_tabViewControl.hidden = YES;
		_tabViewContainer.hidden = YES;
		
		[_scrollView addSubview:_loadingResultView];	
	} else {
		[self loadAnnotationContent];
	}

	if (_startingTab) {
		_tabViewControl.selectedTab = _startingTab;
	}
    
    NSString *detailString = [NSString stringWithFormat:@"/maps/detail?selectvalues=%@", self.annotation.name];
    [[AnalyticsWrapper sharedWrapper] trackPageview:detailString];
}

-(void) externalMapButtonPressed:(id) sender
{
	NSString *search = nil;
	
	if (nil == self.annotation.street) {
		NSString* desc = self.annotation.name;
		
		if (nil != self.annotation.name) {
			desc = [desc stringByAppendingFormat:@" - Building %@", self.annotation.name];
		}

		search = [NSString stringWithFormat:@"%lf,%lf(%@)", self.annotation.coordinate.latitude, self.annotation.coordinate.longitude, desc];

	} else {
		search = self.annotation.street;
        
        NSString *city = [self.annotation.attributes objectForKey:@"City"];
        NSString *state = [self.annotation.attributes objectForKey:@"State"];
        search = [search stringByAppendingFormat:@",%@+%@", city, state];
	}
	
	NSString *url = [NSString stringWithFormat: @"http://maps.google.com/maps?q=%@", [search stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)loadAnnotationContent
{
    NSArray *fieldBlackList = [NSArray arrayWithObjects:@"Root", @"Shape", @"PHOTO_FILE", @"Photo", @"OBJECTID", @"FID", @"BL_ID", @"Building_HU.Building_Label", nil];
    
	[_loadingResultView removeFromSuperview];
	_nameLabel.hidden = NO;
	_locationLabel.hidden = NO;
    
    // photo tab
    NSString *photofile = [self.annotation.attributes objectForKey:@"PHOTO_FILE"];
    if (photofile == nil) {
        photofile = [self.annotation.attributes objectForKey:@"Photo"];
    }
    
    if (photofile != nil && ![photofile isEqualToString:@"Null"]) {
		self.imageConnectionWrapper = [[ConnectionWrapper new] autorelease];
		self.imageConnectionWrapper.delegate = self;
        NSString *urlString = [[NSString stringWithFormat:@"http://map.harvard.edu/mapserver/images/bldg_photos/%@", photofile]
                               stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		[imageConnectionWrapper requestDataFromURL:[NSURL URLWithString:urlString] allowCachedResponse:YES];
		
		[_tabViewControl addTab:@"Photo"];	
		[_tabViews addObject:_buildingView];
    }

    // details tab
	NSMutableString *bldgDetails = [NSMutableString stringWithString:@"<style type=\"text/css\" media=\"screen\">"
                                    "li {font-family:Helvetica;margin-left: -18px;}"
                                    "a {color: #8C000B;text-decoration:none}"
                                    "</style>"
                                    "<ul>"];
	for (NSString *field in [self.annotation.attributes allKeys]) {
        BOOL isBadField = NO;
        for (NSString *badField in fieldBlackList) {
            if ([field isEqualToString:badField]) {
                isBadField = YES;
                break;
            }
        }
        if (isBadField) continue;

        NSString *value = [self.annotation.attributes objectForKey:field];
        if (![value isKindOfClass:[NSString class]]) {
            value = [value description];
        }
        // hack to prevent urls from making the webview too wide
        if ([value length] > 40 && [[value substringToIndex:7] isEqualToString:@"http://"]) {
            value = [NSString stringWithFormat:@"<a href=\"%@\">Visit Website</a>", value];
        }
        [bldgDetails appendString:[NSString stringWithFormat:@"<li><b>%@</b>: %@</li>", field, value]];
    }
    [bldgDetails appendString:@"</ul>"];
    [_whatsHereView loadHTMLString:bldgDetails baseURL:nil];
	[_tabViewControl addTab:@"Details"];
	[_tabViews addObject:_whatsHereView];

	// if no tabs have been added, remove the tab view control and its container view. 
	if (_tabViewControl.tabs.count <= 0) {
		_tabViewControl.hidden = YES;
		_tabViewContainer.hidden = YES;
	} else {
		_tabViewControl.hidden = NO;
		_tabViewContainer.hidden = NO;
	}
	
	[_tabViewControl setNeedsDisplay];
	[_tabViewControl setDelegate:self];
	
	
	// set the labels
	_nameLabel.text = self.annotation.title;
	_nameLabel.numberOfLines = 0;
	_nameLabel.textColor = [UIColor colorWithHexString:@"1A1611"];
	CGSize stringSize = [self.annotation.title sizeWithFont:_nameLabel.font 
							   constrainedToSize:CGSizeMake(_nameLabel.frame.size.width, 200.0)
								   lineBreakMode:UILineBreakModeWordWrap];
	_nameLabel.frame = CGRectMake(_nameLabel.frame.origin.x, 
								  _nameLabel.frame.origin.y,
								  _nameLabel.frame.size.width, stringSize.height);
	
	_locationLabel.text = self.annotation.street;
    CGSize textSize = [_locationLabel.text sizeWithFont:_locationLabel.font constrainedToSize:CGSizeMake(_locationLabel.frame.size.width, 200.0)];
	
	_locationLabel.frame = CGRectMake(_locationLabel.frame.origin.x, 
									  _nameLabel.frame.size.height + _nameLabel.frame.origin.y + 1,
									  _locationLabel.frame.size.width, textSize.height);
	
	if (_locationLabel.frame.origin.y + _locationLabel.frame.size.height + 15 > _tabViewControl.frame.origin.y) {
		_tabViewControl.frame = CGRectMake(_tabViewControl.frame.origin.x, _locationLabel.frame.origin.y + _locationLabel.frame.size.height + 15, 
										   _tabViewControl.frame.size.width, 
										   _tabViewControl.frame.size.height);
		_tabViewContainer.frame = CGRectMake(_tabViewContainer.frame.origin.x,
											 _tabViewControl.frame.origin.y + _tabViewControl.frame.size.height,
											 _tabViewContainer.frame.size.width,
											 (_tabViewContainer.frame.size.height > _tabViewContainerMinHeight) ? _tabViewContainer.frame.size.height : _tabViewContainerMinHeight);
		
	}
	
	// force the correct tab to load
	if(_tabViews.count > 0) {
        _tabViewControl.selectedTab = 0;
        [self tabControl:_tabViewControl changedToIndex:0 tabText:nil];
	}
	
}
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	
	[_tabViewControl release];
	[_nameLabel release];
	[_locationLabel release];
	[_tabViewContainer release];
	[_buildingView release];
	[_buildingImageView release];
	[_whatsHereView release];
	[_tabViews release];
	[_loadingImageView release];
	[_loadingResultView release];
	
}

#pragma mark UIWebView delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	CGSize size = [webView sizeThatFits:CGSizeZero];
    CGRect frame = _whatsHereView.frame;
    frame.size.height = size.height;
    _whatsHereView.frame = frame;

    // prevent short webview from scrolling
    // http://stackoverflow.com/questions/500761/stop-uiwebview-from-bouncing-vertically
    if (size.height <= _tabViewContainer.frame.size.height) {
        [_whatsHereView stringByEvaluatingJavaScriptFromString:@"document.ontouchmove = function(event){ event.preventDefault();}"];     
    }
    
    frame = _tabViewContainer.frame;
    if (size.height > _tabViewContainerMinHeight) {
        frame.size.height = size.height;
        _tabViewContainer.frame = frame;
    }
    
    size = _scrollView.frame.size;
    size.height = _tabViewContainer.frame.size.height + _tabViewContainer.frame.origin.y;
    if (size.height > _scrollView.frame.size.height) {
        [_scrollView setContentSize:size];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}
	
	return YES;
}

#pragma mark User Actions
-(IBAction) mapThumbnailPressed:(id)sender
{
    if (self.campusMapVC) {
        // on the map, select the current annotation
        [_campusMapVC.mapView selectAnnotation:self.annotation animated:NO];
	
        // make sure the map is showing. 
        [_campusMapVC showListView:NO];
	
        [self.navigationController popToViewController:self.campusMapVC animated:YES];
    } else {
        // if we're coming from federated search, the navStack won't be populated
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        CMModule *mapModule = (CMModule *)[appDelegate moduleForTag:CampusMapTag];
        
        [mapModule resetNavStack];
        mapModule.campusMapVC.view;
        [mapModule.campusMapVC setSearchResults:[NSArray arrayWithObject:self.annotation]];
        [mapModule.campusMapVC showListView:NO];
        [appDelegate showModuleForTag:CampusMapTag];
    }
}

-(IBAction) bookmarkButtonTapped
{
	MapBookmarkManager *bookmarkManager = [MapBookmarkManager defaultManager];
	if ([bookmarkManager isBookmarked:self.annotation.uniqueID]) {
		// remove the bookmark and set the images
        MapSavedAnnotation *saved = [bookmarkManager savedAnnotationForID:self.annotation.uniqueID];
		[bookmarkManager removeBookmark:saved];
		
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off.png"] forState:UIControlStateNormal];
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off_pressed.png"] forState:UIControlStateHighlighted];

	} else {
        [bookmarkManager bookmarkAnnotation:self.annotation];
        
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on.png"] forState:UIControlStateNormal];
		[_bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed.png"] forState:UIControlStateHighlighted];
	}
	
}

#pragma mark TabViewControlDelegate
-(void) tabControl:(TabViewControl*)control changedToIndex:(int)tabIndex tabText:(NSString*)tabText
{
	// change the content based on the tab that was selected
	for(UIView* subview in [_tabViewContainer subviews])
	{
		[subview removeFromSuperview];
	}

	// set the size of the scroll view based on the size of the view being added and its parent's offset
	UIView* viewToAdd = [_tabViews objectAtIndex:tabIndex];
	_scrollView.contentSize = CGSizeMake(_scrollView.contentSize.width,
										 _tabViewContainer.frame.origin.y + viewToAdd.frame.size.height);
	
	[_tabViewContainer addSubview:viewToAdd];
}


// data was received from the MITMobileWeb request. 
- (void)request:request jsonLoaded:(id)results {
    if (results && [results isKindOfClass:[NSDictionary class]]) {
        NSArray *resultList = [results objectForKey:@"results"];

    	if ([resultList count] > 0) {
            NSDictionary *firstResult = [resultList objectAtIndex:0];
            [self.annotation updateWithInfo:firstResult];
            
            // load the new contents. 
            [self loadAnnotationContent];
        }
    }
}
	
-(void) connectionDidReceiveResponse: (ConnectionWrapper *)connectionWrapper {
	[(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
	networkActivity = YES;
}

-(void) connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
	[(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
	networkActivity = NO;
	
	_loadingImageView.hidden = YES;
	
	// create an image from the data and set it on the view
	UIImage* image = [UIImage imageWithData:data];
	_buildingImageView.image = image;
	self.imageConnectionWrapper = nil;
}
	
-(void) connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
	[(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
	networkActivity = NO;
	
	self.imageConnectionWrapper = nil;
	_loadingImageView.hidden = YES;
}

- (BOOL)connection:(ConnectionWrapper *)wrapper shouldDisplayAlertForError:(NSError *)error {
    return NO;
}

@end
