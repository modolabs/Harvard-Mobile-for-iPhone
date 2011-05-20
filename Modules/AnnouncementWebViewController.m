    //
//  AnnouncementWebViewController.m
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/22/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "AnnouncementWebViewController.h"
#import "AnalyticsWrapper.h"

@implementation AnnouncementWebViewController

@synthesize htmlStringToDisplay;
@synthesize titleString;
@synthesize dateString;

- (NSString *)htmlStringFromString:(NSString *)source {
	NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
	NSURL *fileURL = [NSURL URLWithString:@"events/events_template.html" relativeToURL:baseURL];
	NSError *error;
	NSMutableString *target = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
	if (!target) {
		DLog(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
	}
	[target replaceOccurrencesOfString:@"__BODY__"
                            withString:source 
                               options:NSLiteralSearch
                                 range:NSMakeRange(0, [target length])];
	return target;
}




// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Shuttles News";
	
	CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	CGRect webViewFrame = CGRectMake(5, 0, self.view.frame.size.width - 10, self.view.frame.size.height - 10);
	
	UIView *webViewContainer = [[[UIView alloc] initWithFrame:frame] autorelease];
	webView = [[UIWebView alloc] initWithFrame:webViewFrame];
	
	NSString *descriptionString = [NSString stringWithFormat:
                                   @"<p><font face=\"Georgia\" size=5>%@ </font></p>"
                                   "<font face=\"Georgia\" size=3 color=\"gray\">%@</font>"
                                   "<font face=\"dimgray\">%@</font>",
                                   self.titleString, self.dateString, self.htmlStringToDisplay];
		 
	[webView loadHTMLString:[self htmlStringFromString:descriptionString] baseURL:nil];
	[webViewContainer addSubview: webView];
	webViewContainer.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:webViewContainer];
	
    [[AnalyticsWrapper sharedWrapper] trackPageview:@"/shuttleschedule/announcement"];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
