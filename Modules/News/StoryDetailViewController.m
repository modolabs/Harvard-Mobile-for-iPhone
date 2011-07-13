#import "StoryDetailViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITLoadingActivityView.h"
#import <QuartzCore/QuartzCore.h>
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"
#import "StoryListViewController.h"
#import "StoryGalleryViewController.h"
#import "ConnectionDetector.h"
#import "NewsImage.h"
#import "NewsCategory.h"
#import "AnalyticsWrapper.h"
#import "JSONAPIRequest.h"

@interface StoryDetailViewController (Private)
- (void)loadSingleStoryFromServer;
- (void)showStoryLoadingErrorWithMessage:(NSString *)message;
@end

@implementation StoryDetailViewController

@synthesize newsController, story, storyView;
@synthesize loadingView;
@synthesize storyGUID;
@synthesize storyCategories;
@synthesize storySearchTitle;

- (void)loadView {
    [super loadView]; // surprisingly necessary empty call to super due to the way memory warnings work
	
	self.shareDelegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	storyPager = [[UISegmentedControl alloc] initWithItems:
											[NSArray arrayWithObjects:
											 [UIImage imageNamed:MITImageNameUpArrow], 
											 [UIImage imageNamed:MITImageNameDownArrow], 
											 nil]];
	[storyPager setMomentary:YES];
	[storyPager setEnabled:NO forSegmentAtIndex:0];
	[storyPager setEnabled:NO forSegmentAtIndex:1];
	storyPager.segmentedControlStyle = UISegmentedControlStyleBar;
	storyPager.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	storyPager.frame = CGRectMake(0, 0, 80.0, storyPager.frame.size.height);
	[storyPager addTarget:self action:@selector(didPressNavButton:) forControlEvents:UIControlEventValueChanged];
	
	UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: storyPager];
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	[segmentBarItem release];
	
    self.view.opaque = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	storyView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    storyView.dataDetectorTypes = UIDataDetectorTypeLink;
    storyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    storyView.scalesPageToFit = NO;
	[self.view addSubview: storyView];
	storyView.delegate = self;
	
	if (self.story) {
		[self displayStory:self.story];
	}
    
    // this is a bit of hack to load
    // an individual story if called
    // from another module
    if(self.storyGUID && self.storyCategories) {
        self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:self.view.bounds xDimensionScaling:2 yDimensionScaling:2] autorelease];
        self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:self.loadingView];
        [self loadSingleStoryFromServer];
    }
}

- (void)displayStory:(NewsStory *)aStory {
	[storyPager setEnabled:[self.newsController canSelectPreviousStory] forSegmentAtIndex:0];
	[storyPager setEnabled:[self.newsController canSelectNextStory] forSegmentAtIndex:1];

	NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"news/news_story_template.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
        return;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, y"];
    NSString *postDate = [dateFormatter stringFromDate:story.postDate];
	[dateFormatter release];
    
    NSString *thumbnailURL = story.featuredImage.url;
    NSString *thumbnailWidth = @"140";
    NSString *thumbnailHeight = @"96";
    
    if (!thumbnailURL) {
        thumbnailURL = @"";
    }
    if (!thumbnailWidth) {
        thumbnailWidth = @"";
    }
    if (!thumbnailHeight) {
        thumbnailHeight = @"";
    }
    
    NSArray *keys = [NSArray arrayWithObjects:
                     @"__TITLE__", @"__AUTHOR__", @"__DATE__", @"__BOOKMARKED__",
                     @"__THUMBNAIL_URL__", @"__THUMBNAIL_WIDTH__", @"__THUMBNAIL_HEIGHT__", 
                     @"__DEK__", @"__BODY__", nil];
    
	NSString *isBookmarked = ([self.story.bookmarked boolValue]) ? @"on" : @"";
	
    NSArray *values = [NSArray arrayWithObjects:
                       story.title, story.author, postDate, isBookmarked, 
					   thumbnailURL, thumbnailWidth, thumbnailHeight, 
					   story.summary, story.body, nil];
    
    [htmlString replaceOccurrencesOfStrings:keys withStrings:values options:NSLiteralSearch];
    
    // mark story as read
    self.story.read = [NSNumber numberWithBool:YES];
	[CoreDataManager saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	[storyView loadHTMLString:htmlString baseURL:baseURL];

    // analytics
    NSString *detailString = [NSString stringWithFormat:@"/news/story?storyID=%d", [self.story.story_id integerValue]];
    [[AnalyticsWrapper sharedWrapper] trackPageview:detailString];
}

- (void)didPressNavButton:(id)sender {
    if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger i = theControl.selectedSegmentIndex;
		NewsStory *newStory = nil;
        if (i == 0) { // previous
			newStory = [self.newsController selectPreviousStory];
        } else { // next
			newStory = [self.newsController selectNextStory];
        }
		if (newStory) {
			self.story = newStory;
			[self displayStory:self.story]; // updates enabled state of storyPager as a side effect
		}
    }
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	BOOL result = YES;

	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		NSURL *url = [request URL];
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];

		if ([[url path] rangeOfString:[baseURL path] options:NSAnchoredSearch].location == NSNotFound) {
            [[UIApplication sharedApplication] openURL:url];
            result = NO;
        } else {
            if ([[url path] rangeOfString:@"bookmark" options:NSBackwardsSearch].location != NSNotFound) {
				// toggle bookmarked state
				self.story.bookmarked = [NSNumber numberWithBool:([self.story.bookmarked boolValue]) ? NO : YES];
				[CoreDataManager saveData];
			} else if ([[url path] rangeOfString:@"share" options:NSBackwardsSearch].location != NSNotFound) {
				[self share:nil];
			}
            result = NO;
		}
	}
	return result;
}

- (NSString *)actionSheetTitle {
	return [NSString stringWithString:@"Share article with a friend"];
}

- (NSString *)emailSubject {
	return [NSString stringWithFormat:@"Harvard Gazette: %@", story.title];
}

- (NSString *)emailBody {
	return [NSString stringWithFormat:@"I thought you might be interested in this story found on the Harvard Gazette:\n\n\"%@\"\n%@\n\n%@\n\nTo view this story, click the link above or paste it into your browser.", story.title, story.summary, story.link];
}

- (NSString *)fbDialogPrompt {
	return nil;
}

- (NSString *)fbDialogAttachment {
    NSString *attachment = [NSString stringWithFormat:
                            @"{\"name\":\"%@\","
                            "\"href\":\"%@\","
                            //"\"caption\":\"%@\","
                            "\"description\":\"%@\","
                            "\"media\":["
                            "{\"type\":\"image\","
                            "\"src\":\"%@\","
                            "\"href\":\"%@\"}]}",
                            story.title, story.link, story.summary, story.featuredImage.url, story.link];    
	return attachment;
}

- (NSString *)twitterUrl {
	return story.link;
}

- (NSString *)twitterTitle {
	return story.title;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; 
}

- (void)dealloc {
    self.storyGUID = nil;
    self.storyCategories = nil;
    self.storySearchTitle = nil;
    
	[storyView release];
    [story release];
    [super dealloc];
}

- (void)loadSingleStoryFromServer {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    [params setObject:self.storyGUID forKey:@"storyId"];
    [params setObject:self.storySearchTitle forKey:@"filter"];
    [params setObject:[self.storyCategories componentsJoinedByString:@","] forKey:@"channelNames"];
    JSONAPIRequest *apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    [apiRequest requestObjectFromModule:@"news" command:@"story" parameters:params];
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject {
    NSDictionary *dict = JSONObject;
    BOOL success = [(NSNumber *)[dict objectForKey:@"success"] boolValue];
    if(success) {
        // get the category for story
        NSInteger categoryID = [(NSNumber *)[dict objectForKey:@"channelIndex"] integerValue];
        NSString *categoryName = [dict objectForKey:@"channelName"];
        NSPredicate *categoryIDPredicate = [NSPredicate predicateWithFormat:@"category_id == %d", categoryID];        
        NSArray *categories = [CoreDataManager objectsForEntity:NewsCategoryEntityName matchingPredicate:categoryIDPredicate];
        NewsCategory *category = [categories lastObject];
        if(!category) {
            category = [CoreDataManager insertNewObjectForEntityForName:NewsCategoryEntityName];
            category.title = categoryName;
            category.category_id = [NSNumber numberWithInt:categoryID];
            category.isMainCategory = [NSNumber numberWithBool:YES];
        }
        
        NSDictionary *storyDict = [dict objectForKey:@"story"];
        // use existing story if it's already in the db
        NSInteger storyID = [[storyDict objectForKey:@"WPID"] integerValue];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"story_id == %d", storyID];
        NewsStory *aStory = [[CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate] lastObject];
        // otherwise create new
        if (!aStory) {
            aStory = (NewsStory *)[CoreDataManager insertNewObjectForEntityForName:NewsStoryEntityName];
            aStory.story_id = [NSNumber numberWithInt:storyID];
        }
        aStory.title = [storyDict objectForKey:@"title"];
        aStory.summary = [storyDict objectForKey:@"description"];
        aStory.postDate = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)[storyDict objectForKey:@"pubDate"] doubleValue]];
        aStory.body = [storyDict objectForKey:@"body"];
        aStory.link = [storyDict objectForKey:@"link"];
        aStory.author = [storyDict objectForKey:@"author"];
        
        NSDictionary *imageDict = [storyDict objectForKey:@"image"];
        NewsImage *image = [CoreDataManager insertNewObjectForEntityForName:NewsImageEntityName];
        image.url= [imageDict objectForKey:@"src"];
        image.width = [imageDict objectForKey:@"width"];
        image.height = [imageDict objectForKey:@"height"];
        aStory.featuredImage = image;
        aStory.categories = [NSSet setWithObject:category];
        
        
        [CoreDataManager saveData];
        self.story = aStory;
        
        [self.loadingView removeFromSuperview];
        [self displayStory:self.story];
    } else {
        [self showStoryLoadingErrorWithMessage:[dict objectForKey:@"error"]];
    }
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
    return YES;
}

- (void)showStoryLoadingErrorWithMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Loading Failure" message:message delegate:self cancelButtonTitle:@"okay" otherButtonTitles: nil];
    [alertView show];
    [alertView release];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)alertViewCancel:(UIAlertView *)alertView {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
