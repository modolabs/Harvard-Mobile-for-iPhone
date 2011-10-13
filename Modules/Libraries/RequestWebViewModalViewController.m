    //
//  RequestWebViewModalViewController.m
//  Harvard Mobile
//
//  Created by Muhammad J Amjad on 12/9/10.
//  Copyright 2010 ModoLabs Inc. All rights reserved.
//

#import "RequestWebViewModalViewController.h"
#import "MITUIConstants.h"
#import "ModoNavigationController.h"
#import "MIT_MobileAppDelegate.h"

#define NAV_BAR_HEIGHT_WEBVIEW 44.0f

@implementation RequestWebViewModalViewController
@synthesize av;


-(id) initWithRequestUrl: (NSString *) url title:(NSString *)titleString{
	
	self = [super init];
	
	if (self) {
	
		requestUrl = url;
		titleStr = titleString;
	}
	
	return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);

	
	if (nil == customNavBar){
		
		customNavBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, NAV_BAR_HEIGHT_WEBVIEW)] retain];
		customNavBar.tintColor = [UIColor blackColor];
		UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" 
																		style:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
		
		UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:titleStr];
		item.rightBarButtonItem = rightButton;
		item.hidesBackButton = YES;

		[customNavBar pushNavigationItem:item animated:NO];
	}
	
	[self.view addSubview:customNavBar];
	
	CGRect frame = CGRectMake(0, NAV_BAR_HEIGHT_WEBVIEW, self.view.frame.size.width, self.view.frame.size.height);
	if (nil == urlWebView)
		urlWebView = [[[UIWebView alloc] initWithFrame:frame] retain];
	
	//Create a URL object.
	NSURL *url = [NSURL URLWithString:requestUrl];
	
	//URL Requst Object
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	
	//Load the request in the UIWebView.
	[urlWebView loadRequest:requestObj];
	urlWebView.delegate = self;
    urlWebView.scalesPageToFit = YES;
	
	self.view.backgroundColor =  [UIColor colorWithWhite:0.0 alpha:1];
	urlWebView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
	[self.view addSubview:urlWebView];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
	urlWebView.delegate = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	urlWebView.delegate = nil;
    [super dealloc];
}


#pragma mark User interaction

-(void) doneButtonPressed: (id) sender {
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}


#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	av = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle
		  :UIActivityIndicatorViewStyleWhiteLarge];
	av.frame=CGRectMake(130, 180, 50, 50);
	av.tag  = 12345;
	[webView addSubview:av];
	[av startAnimating];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	UIActivityIndicatorView *tmpimg = (UIActivityIndicatorView *
									   )[webView viewWithTag:12345];
	[tmpimg removeFromSuperview];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
}

@end
