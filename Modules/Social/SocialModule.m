#import "SocialModule.h"
#import "SocialHomeViewController.h"

@implementation SocialModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = SocialTag;
        self.shortName = @"Social";
        self.longName = @"Social";
        self.iconName = @"social";
        SocialHomeViewController *homeVC = [[[SocialHomeViewController alloc] init] autorelease];
        self.viewControllers = [NSArray arrayWithObject:homeVC];
    }
    return self;
}

@end