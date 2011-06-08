#import "Foundation+MITAdditions.h"
#import "MITLoadingActivityView.h"
#import "VideoHomeViewController.h"
#import "VideoDataManager.h"
#import "Video.h"


@interface VideoHomeViewController (Private)

- (void)deallocViews;
- (void)showVideo:(Video *)video;

@end

@implementation VideoHomeViewController
@synthesize featuredVideoWebview;
@synthesize loadingView;
@synthesize selectedVideo;
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
}

- (void)dealloc
{
    [self deallocViews];
    self.selectedVideo = nil;
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
    [dataManager requestVideosWithHandler:^(NSArray *featuredVideos) {
        self.videos = featuredVideos;
        self.selectedVideo = [featuredVideos objectAtIndex:0];
        [self showVideo:self.selectedVideo];
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
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
        
        
        NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setDateFormat:@"hh:mm"];
        NSString *time = [timeFormatter stringFromDate:video.published];
        [timeFormatter release];
    
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
        NSArray *values = [NSArray arrayWithObjects:@"", playerHTMLString, video.title, time, date, video.summary, nil];
        [featuredHTMLString replaceOccurrencesOfStrings:keys withStrings:values options:NSLiteralSearch];
        
        [self.featuredVideoWebview loadHTMLString:featuredHTMLString baseURL:baseURL];
}

@end
