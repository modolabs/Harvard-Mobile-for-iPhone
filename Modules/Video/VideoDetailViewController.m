#import "VideoDetailViewController.h"
#import "Foundation+MITAdditions.h"

@interface VideoDetailViewController (Private)

- (void)showVideo;

@end

@implementation VideoDetailViewController
@synthesize titleLabel;
@synthesize durationLabel;
@synthesize uploadedLabel;
@synthesize summaryLabel;
@synthesize playerWebview;
@synthesize videos;
@synthesize currentVideo;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)deallocViews {
    self.titleLabel = nil;
    self.durationLabel = nil;
    self.uploadedLabel = nil;
    self.playerWebview = nil;
}

- (void)dealloc
{
    self.videos = nil;
    self.currentVideo = nil;
    [self deallocViews];
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
    
    // sad hack to prevent player from bouncing
    // http://stackoverflow.com/questions/500761/stop-uiwebview-from-bouncing-vertically
    for (id subview in self.playerWebview.subviews) {
        if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
            ((UIScrollView *)subview).bounces = NO;
        }
    }
    
    [self showVideo];
    // Do any additional setup after loading the view from its nib.
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

- (void)showVideo {
    self.titleLabel.text = self.currentVideo.title;
    self.durationLabel.text = [self.currentVideo durationString];
    self.uploadedLabel.text = [self.currentVideo uploadedString];
    
    // borrowed from VideoHomeViewController
    NSError *error = nil;
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *playerTemplateURL = [NSURL URLWithString:[NSString stringWithFormat:@"video/%@_video_player.html", self.currentVideo.mediaSource] relativeToURL:baseURL];    
    NSMutableString *playerHTMLString = [NSMutableString stringWithContentsOfURL:playerTemplateURL encoding:NSUTF8StringEncoding error:&error];
    if (!playerHTMLString) {
        NSLog(@"%@", error);
        return;
    }
    
    NSString *widthString = [NSString stringWithFormat:@"%i", (int)roundf(self.playerWebview.frame.size.width)];
    NSString *heightString = [NSString stringWithFormat:@"%i", (int)roundf(self.playerWebview.frame.size.height)];
    NSArray *playerKeys = [NSArray arrayWithObjects:@"__VIDEO_ID__", @"__WIDTH__", @"__HEIGHT__", nil];
    NSArray *playerValues = [NSArray arrayWithObjects:self.currentVideo.videoID, widthString, heightString, nil]; 
    [playerHTMLString replaceOccurrencesOfStrings:playerKeys withStrings:playerValues options:NSLiteralSearch];
    
    NSURL *playerFrameTemplateURL = [NSURL URLWithString:@"video/player_frame_video_template.html" relativeToURL:baseURL];
    
    NSMutableString *playerFrameHTMLString = [NSMutableString stringWithContentsOfURL:playerFrameTemplateURL encoding:NSUTF8StringEncoding error:&error];
    if (!playerFrameTemplateURL) {
        NSLog(@"%@", error);
        return;
    }
    
    [playerFrameHTMLString replaceOccurrencesOfString:@"__VIDEO_PLAYER__" withString:playerHTMLString
                                              options:NSLiteralSearch range:NSMakeRange(0, [playerFrameHTMLString length])];
    
    [self.playerWebview loadHTMLString:playerFrameHTMLString baseURL:baseURL];

    
    CGSize summarySize =[self.currentVideo.summary sizeWithFont:self.summaryLabel.font constrainedToSize:CGSizeMake(self.summaryLabel.frame.size.width, 1000) lineBreakMode:self.summaryLabel.lineBreakMode];
    CGRect summaryFrame = self.summaryLabel.frame;
    summaryFrame.size = summarySize;
    self.summaryLabel.frame = summaryFrame;
    self.summaryLabel.text = self.currentVideo.summary;
}

@end
