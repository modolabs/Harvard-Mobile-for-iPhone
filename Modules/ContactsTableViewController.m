//
//  ContactsTableViewController.m
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/24/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import "ContactsTableViewController.h"
#import "MITUIConstants.h"
#import "JSONAPIRequest.h"

@implementation ContactsTableViewController
@synthesize parentViewController;

#define GROUPED_VIEW_CELL_COLOR [UIColor colorWithHexString:@"#FDFAF6"] 

#pragma mark -
#pragma mark Initialization

-(NSArray *)getEmergencyPhoneNumbers{
	return [NSArray arrayWithObjects:@"617-495-1212", @"617-495-5711", nil];
}

-(NSArray *)getShuttleServicePhoneNumbers{
	return [NSArray arrayWithObjects:@"617-495-0400", @"617-495-3772", @"617-384-7433", @"617-496-4357", @"617-632-2800", nil];

}

-(NSArray *)getSystemArrayPhoneNumbers{
	return nil;
}

-(NSArray *)getEmergencyPhoneNumbersText{
	return [NSArray arrayWithObjects:@"University Police", @"Health Services", nil];
}

-(NSArray *)getShuttleServicePhoneNumbersText{
	return [NSArray arrayWithObjects:@"Shuttle Bus and Van Services", @"Parking Service", @"CommuterChoice", @"Motorist Assistance Program", @"M2 Shuttle", nil];
}

static NSString const * kAboutHarvardShuttles = @"About Harvard Shuttles";
static NSString const * kAboutMASCOShuttles = @"About MASCO Shuttles";
static NSString const * kShuttlesCalendar = @"Shuttles Calendar";

-(NSArray *)getSystemArrayPhoneNumbersText {
	return [NSArray arrayWithObjects:kAboutHarvardShuttles, kAboutMASCOShuttles, kShuttlesCalendar, nil];
}


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 375.0);
	[self.tableView applyStandardColors];
	
	detailsViewController = [[ContactsSystemDetailsViewController alloc] init];
    aboutSystemText = [[NSMutableDictionary alloc] initWithCapacity:3];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}



#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	switch (section) {
		case 0:
			return [[self getSystemArrayPhoneNumbersText] count];
			break;
		case 1:
			return [[self getShuttleServicePhoneNumbersText] count];
			break;
		case 2:
			return [[self getEmergencyPhoneNumbersText] count];
			break;			
	}
	return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCell *cell;
	static NSString *CellIdentifier;
	switch (indexPath.section) {
		case 0:
			//return [[self getSystemArrayPhoneNumbersText] count];
			
			CellIdentifier = @"Celling1";
			
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			}
			
			// Configure the cell...
			cell.textLabel.text = [[self getSystemArrayPhoneNumbersText] objectAtIndex:indexPath.row];
			cell.backgroundColor = GROUPED_VIEW_CELL_COLOR;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			
			return cell;
			break;
		case 1:
			//return [[self getShuttleServicePhoneNumbersText] count];
			
			CellIdentifier = @"Celling2";
			
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
			}
			
			// Configure the cell...
			cell.textLabel.text = [[self getShuttleServicePhoneNumbersText] objectAtIndex:indexPath.row];
			cell.detailTextLabel.text = [NSString stringWithFormat:@"(%@)", [[self getShuttleServicePhoneNumbers] objectAtIndex:indexPath.row]];
			cell.backgroundColor = GROUPED_VIEW_CELL_COLOR;
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
			return cell;
			break;
		case 2:
			//return [[self getEmergencyPhoneNumbersText] count];
			
			CellIdentifier = @"Celling3";
			
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
			}
			
			cell.textLabel.text = [[self getEmergencyPhoneNumbersText] objectAtIndex:indexPath.row];
			cell.detailTextLabel.text = [NSString stringWithFormat:@"(%@)", [[self getEmergencyPhoneNumbers] objectAtIndex:indexPath.row]];
			cell.backgroundColor = GROUPED_VIEW_CELL_COLOR;
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
			// Configure the cell...
			return cell;
			break;			
	}
	return nil;

}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return GROUPED_SECTION_HEADER_HEIGHT;
}


- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString *sectionHeader = nil;
	
	if(section == 0) {
		sectionHeader = @"System Information";
	}
	else if(section == 1) {
		sectionHeader = @"Shuttle Service Phone Numbers";
	}
	else if(section == 2) {
		sectionHeader = @"Emergency Phone Numbers";
	}

	return [UITableView groupedSectionHeaderWithTitle:sectionHeader];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSString *phoneNumber;
	switch (indexPath.section) {
		case 0:
			phoneNumber = nil;
            NSString *key = [[self getSystemArrayPhoneNumbersText] objectAtIndex:indexPath.row];
            NSString *htmlString = [aboutSystemText objectForKey:key];
            if (htmlString == nil) {
                JSONAPIRequest *request = [JSONAPIRequest requestWithJSONAPIDelegate:self];
                request.userData = key;
                if (key == kAboutHarvardShuttles) {
                    [request requestObjectFromModule:@"shuttles" command:@"about"
                                          parameters:[NSDictionary dictionaryWithObjectsAndKeys:@"harvard", @"agency", nil]];
                    detailsViewController.pageID = @"harvard";
                }
                else if (key == kAboutMASCOShuttles) {
                    [request requestObjectFromModule:@"shuttles" command:@"about"
                                          parameters:[NSDictionary dictionaryWithObjectsAndKeys:@"masco", @"agency", nil]];
                    detailsViewController.pageID = @"masco";
                }
                else if (key == kShuttlesCalendar) {
                    [request requestObjectFromModule:@"shuttles" command:@"calendar" parameters:nil];
                    detailsViewController.pageID = @"calendar";
                }
            }
            else {
                detailsViewController.detailsString = htmlString;
            }
            detailsViewController.titleString = key;
			[self.parentViewController pushViewController:detailsViewController animated:YES];	
			break;
		case 1:
			phoneNumber = [[self getShuttleServicePhoneNumbers] objectAtIndex:indexPath.row];
			break;
		case 2:
			phoneNumber = [[self getEmergencyPhoneNumbers] objectAtIndex:indexPath.row];
			break;			
	}
	
	if (phoneNumber != nil) {
		NSURL *externURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
		if ([[UIApplication sharedApplication] canOpenURL:externURL])
			[[UIApplication sharedApplication] openURL:externURL];
	}
}

#pragma mark JSONAPIRequest

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
    return TRUE;
}

- (void)request:(JSONAPIRequest *)request jsonLoaded: (id)JSONObject {
    [aboutSystemText setObject:[JSONObject objectForKey:@"html"] forKey:request.userData];

    if ([detailsViewController.titleString isEqualToString:request.userData]
        && [JSONObject isKindOfClass:[NSDictionary class]])
    {
        detailsViewController.detailsString = [JSONObject objectForKey:@"html"];
    }
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    parentViewController = nil;
    [aboutSystemText release];
    [detailsViewController release];
    [super dealloc];
}


@end

