#import "VideoModule.h"
#import "VideoHomeViewController.h"

@implementation VideoModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = VideoTag;
        self.shortName = @"Multimedia";
        self.longName = @"Multimedia";
        self.iconName = @"multimedia";
        self.supportsFederatedSearch = NO;
        mainViewController = [[VideoHomeViewController alloc] initWithNibName:@"VideoHomeViewController" bundle:nil];
        self.viewControllers = [NSArray arrayWithObject:mainViewController];
    }
    return self;
}

- (void)dealloc {
    [mainViewController release];
    [super dealloc];
}

#pragma mark State and url

- (void)resetNavStack {
    self.viewControllers = [NSArray arrayWithObject:mainViewController];
}

@end
