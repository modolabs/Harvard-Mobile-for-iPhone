#import "AboutModule.h"
#import "MITModule.h"
#import "AboutTableViewController.h"

@implementation AboutModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = AboutTag;
        self.shortName = @"About";
        self.longName = @"About";
        self.iconName = @"about";
        self.canBecomeDefault = FALSE;
        
        AboutTableViewController *aboutVC = [[[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        aboutVC.title = self.longName;
        
        self.viewControllers = [NSArray arrayWithObject:aboutVC];
    }
    return self;
}

@end
