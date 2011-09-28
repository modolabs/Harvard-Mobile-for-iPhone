#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"

@class SocialPost;

@interface SocialHomeViewController : UIViewController <JSONAPIDelegate, UIWebViewDelegate> {

    UIWebView *_webView;
    NSInteger _currentStart;
    NSInteger _totalPosts;

    JSONAPIRequest *_featuredItemRequest;
    JSONAPIRequest *_itemsRequest;
    JSONAPIRequest *_linksRequest;

    SocialPost *_featuredPost;
    NSMutableArray *_posts;
    
    NSMutableDictionary *_templateValues;
    NSString *_parentTemplate;
    NSString *_postTemplate;
    NSDateFormatter *_dateFormatter;
    
    NSInteger _scrollPosition;
}

@property (nonatomic, retain) UIWebView *webView;

// TODO: the following two properties may not be necessary
@property (nonatomic, retain) NSMutableArray *posts;
@property (nonatomic, retain) SocialPost *featuredPost;

@property (nonatomic, retain) NSString *parentTemplate;
@property (nonatomic, retain) NSString *postTemplate;
@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, retain) NSMutableDictionary *templateValues;

- (void)updateWebView;
- (NSString *)htmlForPost:(SocialPost *)post featured:(BOOL)isFeatured;

@end


