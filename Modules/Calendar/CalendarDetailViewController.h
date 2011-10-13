#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "CalendarConstants.h"
#import "ShareDetailViewController.h"
#import "MIT_MobileAppDelegate.h"

@class MITCalendarEvent;

typedef enum {
	CalendarDetailRowTypeTime,
	CalendarDetailRowTypeLocation,
	CalendarDetailRowTypePhone,
	CalendarDetailRowTypeURL,
	CalendarDetailRowTypeTicketURL,
	CalendarDetailRowTypeEmail,
	CalendarDetailRowTypeDescription,
	CalendarDetailRowTypeCategories
} CalendarDetailRowType;

@interface CalendarDetailViewController : ShareDetailViewController <UITableViewDelegate, UITableViewDataSource, JSONAPIDelegate, ShareItemDelegate, UIWebViewDelegate> {
	
    BOOL isRegularEvent;
    
	MITCalendarEvent *event;
	CalendarDetailRowType* rowTypes;
	NSInteger numRows;
	
	UITableView *_tableView;
	UIButton *shareButton;
	
    NSInteger descriptionHeight;
	NSString *descriptionString;
	
    CGFloat categoriesHeight;
	NSString *categoriesString;

	// list of events to scroll through for previous/next buttons
	NSArray *events;
}

@property (nonatomic, assign) MITCalendarEvent *event;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, assign) NSArray *events;

- (void)reloadEvent;
- (void)setupHeader;
- (void)setupShareButton;
- (void)showNextEvent:(id)sender;

- (NSString *)htmlStringFromString:(NSString *)source;

@end

