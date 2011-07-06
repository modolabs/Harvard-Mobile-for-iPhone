#import "VideoModule.h"
#import "VideoHomeViewController.h"
#import "VideoDetailViewController.h"
#import "VideoListViewController.h"
#import "Video.h"

@implementation VideoModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = VideoTag;
        self.shortName = @"Multimedia";
        self.longName = @"Multimedia";
        self.iconName = @"multimedia";
        self.supportsFederatedSearch = YES;
        mainViewController = [[VideoHomeViewController alloc] initWithNibName:@"VideoHomeViewController" bundle:nil];
        self.viewControllers = [NSArray arrayWithObject:mainViewController];
    }
    return self;
}

- (void)dealloc {
    [mainViewController release];
    [super dealloc];
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    
    [self resetNavStack];
    
    if ([localPath isEqualToString:LocalPathFederatedSearchResult]) {
        NSInteger row = [query integerValue];
        VideoDetailViewController *vc = [[[VideoDetailViewController alloc] initWithNibName:@"VideoDetailViewController" bundle:nil] autorelease];
        vc.videos = self.searchResults;
        vc.currentVideo = [self.searchResults objectAtIndex:row];
        self.viewControllers = [NSArray arrayWithObject:vc];
    } else if([localPath isEqualToString:LocalPathFederatedSearch]) {
        VideoListViewController *vc = [[[VideoListViewController alloc] init] autorelease];
        vc.videos = self.searchResults;
        vc.title = @"Search Results";
        self.viewControllers = [NSArray arrayWithObject:vc];
    }
    return NO;
}

#pragma mark - Search related
- (void)performSearchForString:(NSString *)searchText {
    VideoDataManager *dataManager  = [VideoDataManager sharedManager];
    [dataManager searchWithQuery:searchText withDelegate:self];
}

- (void)videosReceived:(NSArray *)videos forRequestType:(VideoRequestType)requestType {
    self.searchProgress = 1.0;
    self.searchResults = videos;
}

- (NSString *)titleForSearchResult:(id)result {
    Video *video = result;
    return video.title;
}

- (NSString *)subtitleForSearchResult:(id)result {
    Video *video = result;
    return [video uploadedString];
}


#pragma mark State and url

- (void)resetNavStack {
    self.viewControllers = [NSArray arrayWithObject:mainViewController];
}

@end
