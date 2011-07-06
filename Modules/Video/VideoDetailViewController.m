#import "VideoDetailViewController.h"
#import "VideoRelatedPost.h"
#import "Foundation+MITAdditions.h"
#import "StoryDetailViewController.h"
#import "VideoDataManager.h"

@interface VideoDetailViewController (Private)

- (void)showVideo;
- (void)updateBookmarkButton;

@end

@implementation VideoDetailViewController
@synthesize titleLabel;
@synthesize durationLabel;
@synthesize uploadedLabel;
@synthesize summaryLabel;
@synthesize bookmarkButton;
@synthesize playerWebview;
@synthesize relatedNewsTableView;

@synthesize videos;
@synthesize currentVideo;
@synthesize relatedPosts;


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
    self.bookmarkButton = nil;
    self.playerWebview = nil;
    self.relatedNewsTableView.delegate = nil;
    self.relatedNewsTableView.dataSource = nil;
    self.relatedNewsTableView = nil;
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
    self.title = @"Video";
    
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
    CGFloat initialHeight = summaryFrame.size.height;
    summaryFrame.size = summarySize;
    CGFloat finalHeight = summaryFrame.size.height;
    self.summaryLabel.frame = summaryFrame;
    self.summaryLabel.text = self.currentVideo.summary;
    
    CGFloat deltaHeight = finalHeight - initialHeight;
    
    CGRect tableViewFrame = self.relatedNewsTableView.tableHeaderView.frame;
    tableViewFrame.size.height = tableViewFrame.size.height + deltaHeight;
    self.relatedNewsTableView.tableHeaderView.frame = tableViewFrame;
    // the lovely tableHeaderView hack
    self.relatedNewsTableView.tableHeaderView = self.relatedNewsTableView.tableHeaderView;
    
    self.relatedPosts = [self.currentVideo.relatedPosts sortedArrayUsingDescriptors:
                         [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES]]];
    [self.relatedNewsTableView reloadData];
    [self updateBookmarkButton];
}

- (void)updateBookmarkButton {
    if([self.currentVideo.bookmarked boolValue]) {
        [self.bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on"] forState:UIControlStateNormal];
        [self.bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed"] forState:UIControlStateHighlighted];
        bookmarkButtonState = YES;
    } else {
        [self.bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off"] forState:UIControlStateNormal];
        [self.bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off_pressed"] forState:UIControlStateHighlighted]; 
        bookmarkButtonState = NO;
    }
}

- (IBAction)bookmarkButtonTapped:(id)sender {
    [[VideoDataManager sharedManager] bookmarkVideo:self.currentVideo bookmarked:!bookmarkButtonState];
    [self updateBookmarkButton];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.relatedPosts.count > 0) {
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.relatedPosts.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Related News";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"relatedStory";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/action-news"]] autorelease];
    }
    VideoRelatedPost *post = [self.relatedPosts objectAtIndex:indexPath.row];
    cell.textLabel.text = post.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoRelatedPost *post = [self.relatedPosts objectAtIndex:indexPath.row]; 
    StoryDetailViewController *storyVC = [[[StoryDetailViewController alloc] init] autorelease];
    storyVC.storyGUID = post.guid;
    storyVC.storyCategories = [post categoryTitles];
    [self.navigationController pushViewController:storyVC animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
