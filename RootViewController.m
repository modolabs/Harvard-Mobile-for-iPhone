#import "RootViewController.h"

@implementation RootView
@synthesize delegate;

- (void)didAddSubview:(UIView *)subview {
    [self.delegate rootView:self didAddSubview:subview];
}

- (void)willRemoveSubview:(UIView *)subview {
    [self.delegate rootView:self willRemoveSubview:subview];
}


@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.view = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    self.view = [[[RootView alloc] initWithFrame:CGRectZero] autorelease];
    self.view.transform = CGAffineTransformMakeRotation(-M_PI_2);
    [(RootView *)self.view setDelegate:self];
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.view = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

/*
 *  This method assumes that the only place we support rotations
 *  is when this view controller is on top (i.e. full screen video mode)
 *  if we start supporting rotation in other places, we will need
 *  to delegate this call (or refactor some code slightly)
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    int viewIndex = [self.view.superview.subviews indexOfObject:self.view];
    if(viewIndex > 0 && viewIndex == self.view.superview.subviews.count - 1) {
        return UIInterfaceOrientationIsLandscape(interfaceOrientation);
    }
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)rootView:(RootView *)view didAddSubview:(UIView *)subview {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [[UIApplication sharedApplication] setStatusBarOrientation:self.interfaceOrientation animated:YES];
    [window bringSubviewToFront:view];
}

- (void)rootView:(RootView *)view willRemoveSubview:(UIView *)subview {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window sendSubviewToBack:view];
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
}

@end
