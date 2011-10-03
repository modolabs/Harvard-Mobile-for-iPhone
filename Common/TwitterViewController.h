#import <UIKit/UIKit.h>
#import "XAuthTwitterEngine.h"
#import "ConnectionWrapper.h"

@interface TwitterViewController : UIViewController <UITextFieldDelegate, MGTwitterEngineDelegate, XAuthTwitterEngineDelegate, ConnectionWrapperDelegate> {
	NSString *message;
	NSString *longURL;
    NSString *shortURL;
    
    NSString *_retweetId;
	
	UILabel *usernameLabel;
    UILabel *counterLabel;
	UIView *contentView;
	UINavigationItem *navigationItem;
	UIButton *signOutButton;
	
	UITextField *usernameField;
	UITextField *passwordField;
	
	UITextField *messageField;
	
	XAuthTwitterEngine *twitterEngine;
	BOOL authenticationRequestInProcess;
    
    ConnectionWrapper *connection;
}

- (id) initWithMessage:(NSString *)aMessage url:(NSString *)longURL;
- (id) initWithRetweetId:(NSString *)tweetId;

@property (nonatomic, retain) ConnectionWrapper *connection;
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) NSString *retweetId;

@end
