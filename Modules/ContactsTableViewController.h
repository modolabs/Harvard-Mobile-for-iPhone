//
//  ContactsTableViewController.h
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/24/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactsSystemDetailsViewController.h"
#import "JSONAPIRequest.h"

@class ContactsSystemDetailsViewController;

@interface ContactsTableViewController : UITableViewController <JSONAPIDelegate> {

	UINavigationController *parentNavigationViewController;
	ContactsSystemDetailsViewController *detailsViewController;
    NSMutableDictionary *aboutSystemText;
}

@property (nonatomic, retain) UINavigationController *parentNavigationViewController;


-(NSArray *)getEmergencyPhoneNumbers;
-(NSArray *)getShuttleServicePhoneNumbers;
-(NSArray *)getSystemArrayPhoneNumbers;

-(NSArray *)getEmergencyPhoneNumbersText;
-(NSArray *)getShuttleServicePhoneNumbersText;
-(NSArray *)getSystemArrayPhoneNumbersText;

@end
