#import "Foundation+MITAdditions.h"
#import "MITLoadingActivityView.h"
#import "MITSearchDisplayController.h"
#import "VideoHomeViewController.h"
#import "VideoDataManager.h"
#import "Video.h"
#import "VideoButton.h"
#import "VideoTableViewCell.h"

#define FEATURED_VIDEO_COUNT 5


@interface VideoHomeViewController (Private)

- (void)deallocViews;
- (void)showVideo:(Video *)video;
- (void)videoButtonTapped:(id)sender;

@end

@implementation VideoHomeViewController
@synthesize featuredVideoWebview;
@synthesize searchBar;
@synthesize searchResults;
@synthesize searchController;
@synthesize searchDisplayContent;
@synthesize videoCell;
@synthesize thumbnailsContainer;
@synthesize loadingView;
@synthesize selectedVideo;
@synthesize selectedButton;
@synthesize videos;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)deallocViews 
{
    self.featuredVideoWebview = nil;
    self.loadingView = nil;
    self.selectedButton = nil;
    self.searchBar = nil;
    self.searchController = nil;
    self.searchDisplayContent = nil;
}

- (void)dealloc
{
    [self deallocViews];
    self.selectedVideo = nil;
    self.thumbnailsContainer = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:self.view.frame xDimensionScaling:2 yDimensionScaling:2] autorelease];
    [self.view addSubview:self.loadingView];
    VideoDataManager *dataManager = [VideoDataManager sharedManager];
    
    self.searchBar.delegate = self;
    
    self.searchController = [[[MITSearchDisplayController alloc] initWithFrame:self.searchDisplayContent.frame searchBar:self.searchBar contentsController:self] autorelease];
    self.searchController.delegate = self;
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;
    
    [dataManager requestVideosWithHandler:^(NSArray *featuredVideos) {
        self.videos = featuredVideos;
        self.selectedVideo = [featuredVideos objectAtIndex:0];
        [self showVideo:self.selectedVideo];
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
        
        // load thumbnail buttons
        CGFloat buttonWidth = self.thumbnailsContainer.frame.size.width / FEATURED_VIDEO_COUNT;
        for (int i=0; i < FEATURED_VIDEO_COUNT; i++) {
            Video *aVideo = [self.videos objectAtIndex:i];
            
            VideoButton *button = [[[VideoButton alloc] 
                                    initWithFrame:CGRectMake(buttonWidth*i, 0, buttonWidth, 
                                                             self.thumbnailsContainer.frame.size.height)] autorelease];
            if(i == 0) {
                self.selectedButton = button;
                button.selected = YES;
            }
            
            button.userData = aVideo;
            button.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin);
            [button addTarget:self action:@selector(videoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self.thumbnailsContainer addSubview:button];
            [button setImageURL:aVideo.thumbnailURL]; 
        }
    }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self deallocViews];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)showVideo:(Video *)video {        
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
        NSURL *featureTemplateURL = [NSURL URLWithString:@"video/featured_video_template.html" relativeToURL:baseURL];
        
        NSError *error = nil;
        NSMutableString *featuredHTMLString = [NSMutableString stringWithContentsOfURL:featureTemplateURL encoding:NSUTF8StringEncoding error:&error];
        if (!featuredHTMLString) {
            NSLog(@"%@", error);
            return;
        }
    
        NSURL *playerTemplateURL = [NSURL URLWithString:[NSString stringWithFormat:@"video/%@_video_player.html", video.mediaSource] relativeToURL:baseURL];    
        NSMutableString *playerHTMLString = [NSMutableString stringWithContentsOfURL:playerTemplateURL encoding:NSUTF8StringEncoding error:&error];
        if (!playerHTMLString) {
            NSLog(@"%@", error);
            return;
        }
    
        NSInteger minutes = [video.duration intValue] / 60;
        NSInteger seconds = [video.duration intValue] % 60;
        NSString *durationString = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMMM F, yyyy"];
        NSString *date = [dateFormatter stringFromDate:video.published];
        [dateFormatter release];

        
        //NSString *isBookmarked = ([self.story.bookmarked boolValue]) ? @"on" : @"";
        
        NSArray *playerKeys = [NSArray arrayWithObjects:@"__VIDEO_ID__", nil];
        NSArray *playerValues = [NSArray arrayWithObjects:video.videoID, nil]; 
        [playerHTMLString replaceOccurrencesOfStrings:playerKeys withStrings:playerValues options:NSLiteralSearch];

        NSArray *keys = [NSArray arrayWithObjects:@"__BOOKMARKED__", @"__VIDEO_PLAYER__", 
                         @"__TITLE__", @"__TIME__", @"__DATE__", @"__SUMMARY__", nil];
        NSArray *values = [NSArray arrayWithObjects:@"", playerHTMLString, video.title, durationString, date, video.summary, nil];
        [featuredHTMLString replaceOccurrencesOfStrings:keys withStrings:values options:NSLiteralSearch];
        
        [self.featuredVideoWebview loadHTMLString:featuredHTMLString baseURL:baseURL];
}

- (void)videoButtonTapped:(id)sender {
    VideoButton *button = sender;
    if (![self.selectedVideo isEqual:button.userData]) {
        self.selectedButton.selected = NO;
        self.selectedButton = button;
        self.selectedButton.selected = YES;
        self.selectedVideo = button.userData;
        [self showVideo:self.selectedVideo];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar {
    [[VideoDataManager sharedManager] searchWithQuery:aSearchBar.text withHandler:^(NSArray *theVideos) {
        self.searchResults = theVideos;
        self.searchController.searchResultsTableView.rowHeight = 50;
        [self.searchController.searchResultsTableView reloadData];
        [self.view addSubview:self.searchController.searchResultsTableView];
    }];
}

#pragma mark - UITableView delegate methods for search results
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.count; 
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tourStopCellIdentifier = @"TourStepCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tourStopCellIdentifier];
    if(cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"VideoTableViewCell" owner:self options:nil];
        cell = self.videoCell;
        self.videoCell = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    populateCell(cell, [self.searchResults objectAtIndex:indexPath.row]);
    return cell;
}

@end
