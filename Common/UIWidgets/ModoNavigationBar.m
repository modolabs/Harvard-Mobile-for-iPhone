/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "ModoNavigationBar.h"
#import "UIKit+MITAdditions.h"
#import "ModoNavigationController.h"

@implementation ModoNavigationBar

@synthesize navigationBar = _navigationBar;

- (id)initWithNavigationBar:(UINavigationBar *)navigationBar {
    //navigationBar.frame = CGRectMake(0, 0, 320, 44);
    if (self = [super initWithFrame:navigationBar.frame]) {
        self.navigationBar = navigationBar;
        //[self.navigationBar addSubview:self];
        //self.delegate = self.navigationBar.delegate;
    }
    return self;
}

/*
- (NSArray *)items {
    return _navigationBar.items;
} 
*/

- (id<UINavigationBarDelegate>)delegate {
    return self.navigationBar.delegate;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.navigationBar = self;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    self.tintColor = [UIColor colorWithHexString:@"#870E16"]; // this is for color of buttons  
    self.navigationBar.tintColor = [UIColor colorWithHexString:@"#870E16"]; // since the background shows through when we click the buttons
    UIImage *image = [[UIImage imageNamed:@"global/navbar-background.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0];
    [image drawInRect:rect];
    
    [self update];
}

- (void)update {
    self.frame = CGRectMake(0, 0, self.navigationBar.frame.size.width, self.navigationBar.frame.size.height);
    self.items = self.navigationBar.items;
}


- (UINavigationItem *)popNavigationItemAnimated:(BOOL)animated {
    // part of a workaround to make sure old back buttons disappear; see ModoNavigationController.m
    if ([self.delegate isKindOfClass:[ModoNavigationController class]]) {
        [(ModoNavigationController *)self.delegate navigationBar:self willHideSubviews:self.subviews];
    }

    UINavigationItem *item = [super popNavigationItemAnimated:animated];
    if (item == nil) {
        item = [self popNavigationItemAnimated:animated];
        DLog(@"popped nil item off navigation bar");
    }
    if (self.items.count > 1) {
        //NSLog(@"after popping %@", [self.subviews description]);
    }
    DLog(@"popped %@ off nav bar", item.title);
    return item;
}

/*
- (void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated {
    [super pushNavigationItem:item animated:animated];
}

- (void)didAddSubview:(UIView *)subview {
    [super didAddSubview:subview];
}

- (void)willRemoveSubview:(UIView *)subview {
    [super willRemoveSubview:subview];
}
*/

- (void)dealloc {
    if (self.navigationBar.delegate != nil) { // someone else owns the nav bar
        self.navigationBar = nil;
    } else {
        [self.navigationBar release];
    }
    [super dealloc];
}

@end
