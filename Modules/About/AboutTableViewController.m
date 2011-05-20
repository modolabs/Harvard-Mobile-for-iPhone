#import "AboutTableViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "UIKit+MITAdditions.h"
#import "AboutMITVC.h"
#import "UITableView+MITUIAdditions.h"
#import "MITUIConstants.h"
#import "MITMailComposeController.h"
#import "AnalyticsWrapper.h"

@implementation AboutTableViewController

- (void)viewDidLoad {
    [self.tableView applyStandardColors];
    showBuildNumber = NO;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 20, 45)];
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, footerView.frame.size.width, 30)];
    footerLabel.text = @"Copyright © 2011 The President and Fellows of Harvard College";
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.textAlignment = UITextAlignmentCenter;
    footerLabel.textColor = CELL_DETAIL_FONT_COLOR;
    footerLabel.font = [UIFont systemFontOfSize:12.0];
    footerLabel.lineBreakMode = UILineBreakModeWordWrap;
    footerLabel.numberOfLines = 0;
    [footerView addSubview:footerLabel];
    self.tableView.tableFooterView = footerView;
    [footerLabel release];
    [footerView release];
    
    [[AnalyticsWrapper sharedWrapper] trackPageview:@"/mobile-about"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
        case 1:
            return 2;
        default:
            return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 1) {
        NSString *aboutText = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"AboutAppText"];
        UIFont *aboutFont = [UIFont systemFontOfSize:14.0];
        CGSize aboutSize = [aboutText sizeWithFont:aboutFont constrainedToSize:CGSizeMake(270, 2000) lineBreakMode:UILineBreakModeWordWrap];
        return aboutSize.height + 40;
    }
    else {
        return self.tableView.rowHeight;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                {
                    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
                    if (!showBuildNumber) {
                        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [infoDict objectForKey:@"CFBundleName"], [infoDict objectForKey:@"CFBundleVersion"]];
                    } else {
                        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", [infoDict objectForKey:@"CFBundleName"], [infoDict objectForKey:@"CFBundleVersion"], MITBuildNumber];
                    }
                    cell.textLabel.textAlignment = UITextAlignmentCenter;
                    cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
        			cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.backgroundColor = [UIColor whiteColor];
                }
                    break;
                case 1:
                {
                    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
                    cell.textLabel.text = [infoDict objectForKey:@"AboutAppText"];
                    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
                    cell.textLabel.numberOfLines = 0;
                    cell.textLabel.font = [UIFont systemFontOfSize:15.0];
        			cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.backgroundColor = [UIColor whiteColor];
                }
                    break;
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"About Harvard";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    cell.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
                    break;
                case 1:
                    cell.textLabel.text = @"Send Feedback";
                    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    break;
                break;
            }
        default:
            break;
    }
    
    return cell;    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        showBuildNumber = !showBuildNumber;
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0: {
                AboutMITVC *aboutMITVC = [[AboutMITVC alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:aboutMITVC animated:YES];
                [aboutMITVC release];
                break;
            }
            case 1: {
                NSString *subject = [NSString stringWithFormat:@"Feedback for Harvard Mobile %@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], MITBuildNumber];
                NSString *email = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"AppFeedbackAddress"];
                [MITMailComposeController presentMailControllerWithEmail:email subject:subject body:[NSString string]];
				break;
            }
            default:
                break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -

- (void)dealloc {
    [super dealloc];
}


@end

