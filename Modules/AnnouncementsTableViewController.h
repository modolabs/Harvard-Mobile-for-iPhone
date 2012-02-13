#import <UIKit/UIKit.h>
#import "MultiLineTableViewCell.h"

@interface AnnouncementsTableViewController : UITableViewController {

	NSArray * harvardAnnouncements;
	NSArray * mascoAnnouncements;
	UINavigationController *parentNavigationViewController;
}

@property (nonatomic, retain) UINavigationController *parentNavigationViewController;
@property (nonatomic, retain) NSArray * harvardAnnouncements;
@property (nonatomic, retain) NSArray * mascoAnnouncements;

@end


@interface AnnouncementsTableViewHeaderCell : MultiLineTableViewCell
{
	CGFloat height;
}

@property CGFloat height;

@end