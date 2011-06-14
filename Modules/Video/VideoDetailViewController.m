#import "VideoDetailViewController.h"

@interface VideoDetailViewController (Private)

- (void)showVideo;

@end

@implementation VideoDetailViewController
@synthesize titleLabel;
@synthesize durationLabel;
@synthesize uploadedLabel;
@synthesize summaryLabel;
@synthesize videoPlayControl;
@synthesize previewImage;
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
    self.videoPlayControl = nil;
    self.previewImage = nil;
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
    self.previewImage.imageURL = self.currentVideo.largeImageURL;
    [self.previewImage loadImage];
    CGSize summarySize =[self.currentVideo.summary sizeWithFont:self.summaryLabel.font constrainedToSize:CGSizeMake(self.summaryLabel.frame.size.width, 1000) lineBreakMode:self.summaryLabel.lineBreakMode];
    CGRect summaryFrame = self.summaryLabel.frame;
    summaryFrame.size = summarySize;
    self.summaryLabel.frame = summaryFrame;
    self.summaryLabel.text = self.currentVideo.summary;
}

@end
