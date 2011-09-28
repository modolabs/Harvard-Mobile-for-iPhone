#import "SocialHomeViewController.h"
#import "SocialPost.h"
#import "Foundation+MITAdditions.h"
#import "MIT_MobileAppDelegate.h"
#import "TwitterViewController.h"

@interface SocialHomeViewController (Private)

- (void)requestFeaturedItem;
- (void)requestItems;
- (void)requestLinks;

@end


@implementation SocialHomeViewController

@synthesize webView = _webView, featuredPost = _featuredPost, posts = _posts,
parentTemplate = _parentTemplate, templateValues = _templateValues, postTemplate = _postTemplate,
dateFormatter = _dateFormatter;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _currentStart = 0;
    _scrollPosition = 0;

	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
    
    self.webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)] autorelease];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    self.webView.delegate = self;
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"social/social_home.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSString *htmlString = [[[NSString alloc] initWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error] autorelease];
    if (!htmlString) {
        NSLog(@"failed to load social_home template: %@", [error description]);
    }
    self.parentTemplate = htmlString;
    self.templateValues = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           @"", @"__LINKS__",
                           @"", @"__FEATURED_POST__",
                           [NSMutableString string], @"__POSTS__",
                           nil];
    
    
    fileURL = [NSURL URLWithString:@"social/social_post.html" relativeToURL:baseURL];
    htmlString = [[[NSString alloc] initWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error] autorelease];
    if (!htmlString) {
        NSLog(@"failed to load social_post template: %@", [error description]);
    }
    self.postTemplate = htmlString;

    self.dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    
    
    
    [self.view addSubview:self.webView];
    
    [self requestFeaturedItem];
    [self requestItems];
    [self requestLinks];
}

- (NSString *)htmlForPost:(SocialPost *)post featured:(BOOL)isFeatured
{
    NSMutableDictionary *postVars = [NSMutableDictionary dictionaryWithObjectsAndKeys:
#ifndef DEBUG
                                     @"", @"__MESSAGE__",
                                     @"", @"__AUTHOR_ICON__",
                                     @"", @"__TYPE__",
                                     @"", @"__AUTHOR_URL__",
                                     @"", @"__TIME__",
                                     @"", @"__AUTHOR__",
#endif
                                     @"", @"__RETWEET_LINK__",
                                     nil];

    if (post.message) {
        [postVars setObject:post.message forKey:@"__MESSAGE__"];
    }
    if (post.icon) {
        [postVars setObject:post.icon forKey:@"__AUTHOR_ICON__"];
    }
    if (post.type) {
        [postVars setObject:post.type forKey:@"__TYPE__"];
        if ([post.type isEqualToString:@"twitter"]) {
            NSString *featuredClass = isFeatured ? @"featured" : @"";
            NSString *message = post.message ? post.message : @"";
            NSString *author = post.author ? post.author : @"";
            NSString *retweetLink = [NSString stringWithFormat:@"<a class=\"retweet %@\""
                                     "href=\"retweet://RT+%@+%@\">Retweet</a>",
                                     featuredClass, author, message];
            
            [postVars setObject:retweetLink forKey:@"__RETWEET_LINK__"];
        }
    }
    if (post.authorURL) {
        [postVars setObject:post.authorURL forKey:@"__AUTHOR_URL__"];
    }
    if (post.date) {
        [postVars setObject:[post.date agoString] forKey:@"__TIME__"];
    }
    if (post.author) {
        [postVars setObject:post.author forKey:@"__AUTHOR__"];
    }
    
    NSMutableString *htmlString = [NSMutableString stringWithString:self.postTemplate];
    [postVars enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [htmlString replaceOccurrencesOfString:key withString:obj options:NSLiteralSearch range:NSMakeRange(0, htmlString.length)];
    }];

    return htmlString;
}

#pragma mark - webview delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = request.URL;
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSString *urlString = [url absoluteString];
        if ([urlString rangeOfString:@"http"].location == 0) {
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
            return NO;
        }
        
        if ([urlString rangeOfString:@"retweet"].location == 0 && [urlString length] > [@"retweet" length] + 3) {
            NSString *message = [urlString substringFromIndex:[@"retweet" length] + 3];
            message = [message stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            UIViewController *twitterVC = [[[TwitterViewController alloc] initWithMessage:message url:nil] autorelease];
            MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate presentAppModalViewController:twitterVC animated:YES];

            return NO;
        }
        
        if ([urlString rangeOfString:@"loadMore"].location == 0) {
            [self requestItems];
            
            return NO;
        }
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (_scrollPosition) {
        [self.webView stringByEvaluatingJavaScriptFromString:
         [NSString stringWithFormat:@"scrollTo(0, %d)", _scrollPosition]];
    }
}

#pragma mark -

- (void)updateWebView
{
    __block NSMutableString *htmlString = [NSMutableString stringWithString:self.parentTemplate];
    [self.templateValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [htmlString replaceOccurrencesOfString:key withString:obj options:NSLiteralSearch range:NSMakeRange(0, htmlString.length)];
    }];

    _scrollPosition = [[self.webView stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"] integerValue];
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    [self.webView loadHTMLString:htmlString baseURL:baseURL];
}

- (void)requestFeaturedItem
{
    if (!_featuredItemRequest) {
        _featuredItemRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
        _featuredItemRequest.useKurogoApi = YES;
        [_featuredItemRequest requestObject:nil pathExtension:@"social/featured"];
    }
}

- (void)requestItems
{
    if (!_itemsRequest) {
        _itemsRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
        _itemsRequest.useKurogoApi = YES;
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithFormat:@"%d", _currentStart], @"start",
                                @"20", @"count",
                                nil];

        [_itemsRequest requestObject:params pathExtension:@"social/posts"];
    }
}

- (void)requestLinks
{
    if (!_linksRequest) {
        _linksRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
        _linksRequest.useKurogoApi = YES;
        [_linksRequest requestObject:nil pathExtension:@"social/links"];
    }
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject
{
    id response = [(NSDictionary *)JSONObject objectForKey:@"response"];
    
    if (request == _featuredItemRequest) {
        _featuredItemRequest = nil;

        if ([response isKindOfClass:[NSArray class]]) {
            
            NSArray *stringProperties = [NSArray arrayWithObjects:
                                         @"uid", @"type", @"icon",
                                         @"message", @"author", @"authorURL",
                                         nil];

            NSArray *postArray = (NSArray *)response;

            if ([postArray count]) {
                NSDictionary *postDict = [postArray objectAtIndex:0];
                SocialPost *aPost = [[[SocialPost alloc] init] autorelease];
                for (NSString *aProperty in stringProperties) {
                    id value = [postDict objectForKey:aProperty];
                    if (value && [value isKindOfClass:[NSString class]]) {
                        [aPost setValue:value forKey:aProperty];
                    }
                }
                id objDate = [postDict objectForKey:@"date"];
                if ([objDate isKindOfClass:[NSString class]] || [objDate isKindOfClass:[NSNumber class]]) {
                    NSTimeInterval interval = (NSTimeInterval)[objDate floatValue];
                    aPost.date = [NSDate dateWithTimeIntervalSince1970:interval];
                }
                self.featuredPost = aPost;
                
                NSString *featureHTML = [self htmlForPost:aPost featured:YES];
                [self.templateValues setObject:featureHTML forKey:@"__FEATURED_POST__"];
                [self updateWebView];
            }
        }
        
        
    } else if (request == _itemsRequest) {
        _itemsRequest = nil;

        if ([response isKindOfClass:[NSDictionary class]]) {
            
            NSArray *stringProperties = [NSArray arrayWithObjects:
                                         @"uid", @"type", @"icon",
                                         @"message", @"author", @"authorURL",
                                         nil];
                                         
            NSDictionary *jsonDict = (NSDictionary *)response;

            id objTotal = [jsonDict objectForKey:@"total"];
            if ([objTotal isKindOfClass:[NSString class]] || [objTotal isKindOfClass:[NSNumber class]]) {
                _totalPosts = [objTotal integerValue];
            }
            
            id start = [jsonDict objectForKey:@"start"];
            if ([start isKindOfClass:[NSString class]] || [start isKindOfClass:[NSNumber class]]) {
                _currentStart = [start integerValue];
            }

            NSMutableString *postHTML = [self.templateValues objectForKey:@"__POSTS__"];
            
            NSArray *posts = [jsonDict objectForKey:@"posts"];
            for (NSDictionary *postDict in posts) {
                SocialPost *aPost = [[[SocialPost alloc] init] autorelease];
                for (NSString *aProperty in stringProperties) {
                    id value = [postDict objectForKey:aProperty];
                    if (value && [value isKindOfClass:[NSString class]]) {
                        [aPost setValue:value forKey:aProperty];
                    }
                }
                id objDate = [postDict objectForKey:@"date"];
                if ([objDate isKindOfClass:[NSString class]] || [objDate isKindOfClass:[NSNumber class]]) {
                    NSTimeInterval interval = (NSTimeInterval)[objDate floatValue];
                    aPost.date = [NSDate dateWithTimeIntervalSince1970:interval];
                }
                [self.posts addObject:aPost];
                _currentStart++;

                [postHTML appendString:[self htmlForPost:aPost featured:NO]];
            }
            
            [self.templateValues setObject:postHTML forKey:@"__POSTS__"];
            [self updateWebView];
        }
        
    } else if (request == _linksRequest) {        
        _linksRequest = nil;
        
        if ([response isKindOfClass:[NSArray class]]) {
            NSMutableString *linkHTML = [NSMutableString string];
            
            for (NSDictionary *aLink in (NSArray *)response) {
                NSString *name = [aLink objectForKey:@"name"];
                if (!name) {
                    name = @"";
                }

                NSString *type = [aLink objectForKey:@"type"];
                if (!type) {
                    type = @"";
                }
                
                NSString *url = [aLink objectForKey:@"url"];
                if (!url) {
                    url = @"";
                }

                [linkHTML appendFormat:@"<a class=\"%@\" href=\"%@\">%@</a>", type, url, name];
            }
            
            [self.templateValues setObject:linkHTML forKey:@"__LINKS__"];
            
            [self updateWebView];
        }
    }
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error
{
    if (request == _featuredItemRequest) {
        _featuredItemRequest = nil;
    } else if (request == _itemsRequest) {
        _itemsRequest = nil;
    } else if (request == _linksRequest) {
        _linksRequest = nil;
    }
}

- (void)dealloc
{
    if (_featuredItemRequest) {
        _featuredItemRequest.jsonDelegate = nil;
        _featuredItemRequest = nil;
    }
    if (_itemsRequest) {
        _itemsRequest.jsonDelegate = nil;
        _itemsRequest = nil;
    }
    if (_linksRequest) {
        _linksRequest.jsonDelegate = nil;
        _linksRequest = nil;
    }
    [_featuredPost release];
    [_posts release];
    [_webView release];
    [super dealloc];
}

@end