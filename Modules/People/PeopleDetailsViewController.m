#import "PeopleDetailsViewController.h"
#import "MultiLineTableViewCell.h"
#import "ConnectionDetector.h"
#import "PeopleRecentsData.h"
#import "MIT_MobileAppDelegate.h"
#import "MITUIConstants.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"
#import "ModoNavigationController.h"
#import "AddressFormatter.h"
#import "MapBookmarkManager.h"
#import "TileServerManager.h"
#import "AnalyticsWrapper.h"
#import "MITMailComposeController.h"

static const CGFloat kEmailLineBreakThresholdWidth = 190.0f;
static const CGFloat kMaxHeightOfSingleLineOfEmailText = 18.0f;

@interface PeopleDetailsViewController (Private)

// Finds values in PersonDetails corresponding to the given ldapKey and adds them to multiValue without 
// overwriting existing values.
- (void)addMultivalueValuesAndLabelsTo:(ABMutableMultiValueRef)multiValue
							usingLabel:(CFStringRef)label
				 withValuesFromLDAPKey:(NSString *)ldapKey;

@end

@implementation PeopleDetailsViewController

@synthesize personDetails, sectionArray, fullname;

NSString * const RequestUpdatePersonDetails = @"update";
NSString * const RequestLookupAddress = @"address";

- (void)addMultivalueValuesAndLabelsTo:(ABMutableMultiValueRef)multiValue
							usingLabel:(CFStringRef)label
				 withValuesFromLDAPKey:(NSString *)ldapKey {
	
	NSArray *existingValues = (NSArray *)ABMultiValueCopyArrayOfAllValues(multiValue);
	NSArray *ldapValue = nil;
	if (ldapValue = [self.personDetails separatedValuesForKey:ldapKey]) {
        DLog(@"%@", [ldapValue description]);
		for (NSString *value in ldapValue) {
			if (![existingValues containsObject:value]) {
				ABMultiValueAddValueAndLabel(multiValue, value, label, NULL);
			}
		}
	}	
	[existingValues release];
}

- (void)viewDidLoad
{
	self.title = @"Info";
	[self.tableView applyStandardColors];
	
	// get fullname for header
	NSMutableArray *multiPartAttribute = [[NSMutableArray alloc] initWithCapacity:2];	
	NSString *value;
	if (value = [self.personDetails formattedValueForKey:@"givenname"])
		[multiPartAttribute addObject:value];
	if (value = [self.personDetails formattedValueForKey:@"sn"])
		[multiPartAttribute addObject:value];
	self.fullname = [multiPartAttribute componentsJoinedByString:@" "];
	[multiPartAttribute release];
	
	// populate remaining contents to be displayed
	self.sectionArray = [NSMutableArray array];
	
	NSArray *jobSection = [NSArray arrayWithObjects:@"title", nil];
	NSArray *phoneSection = [NSArray arrayWithObjects:@"telephonenumber", @"facsimiletelephonenumber", nil];
	NSArray *emailSection = [NSArray arrayWithObject:@"mail"];
	NSArray *officeSection = [NSArray arrayWithObject:@"postaladdress"];
    NSArray *unitSection = [NSArray arrayWithObject:@"ou"];
	
	NSArray *sectionCandidates = [NSArray arrayWithObjects:jobSection, emailSection, phoneSection, officeSection, unitSection, nil];
	
	NSString *displayTag;
	NSString *ldapValue;
	
	for (NSArray *section in sectionCandidates) {
		// each element of currentSection will be a 2-array of NSString *tag and NSString *value
		NSMutableArray *currentSection = [NSMutableArray array];
		for (NSString *ldapTag in section) {
			ldapValue = [self.personDetails formattedValueForKey:ldapTag];
			displayTag = [self.personDetails displayNameForKey:ldapTag];
			
            DLog(@"%@", ldapValue);
            
			if ([ldapValue length] > 0) {
				// create one tag/label pair for each email/phone/office label
				if ([ldapTag isEqualToString:@"mail"] || 
					[ldapTag isEqualToString:@"telephonenumber"] ||
					[ldapTag isEqualToString:@"facsimiletelephonenumber"] ||
					[ldapTag isEqualToString:@"postaladdress"]) {
					for (NSString *value in [ldapValue componentsSeparatedByString:kPersonDetailsValueSeparatorToken])
						[currentSection addObject:[NSArray arrayWithObjects:displayTag, value, nil]];
					continue;
				}
				[currentSection addObject:[NSArray arrayWithObjects:displayTag, ldapValue, nil]];
			}
		}
        DLog(@"%@", [currentSection description]);
		
		if ([currentSection count] > 0)
			[self.sectionArray addObject:currentSection];
	}
	
	// create header
    UIFont *font = [UIFont fontWithName:CONTENT_TITLE_FONT size:CONTENT_TITLE_FONT_SIZE];
	CGSize labelSize = [self.fullname sizeWithFont:font
								 constrainedToSize:CGSizeMake(self.tableView.frame.size.width - 20.0, 2000.0)
									 lineBreakMode:UILineBreakModeWordWrap];
	UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 10.0, labelSize.width, labelSize.height)];
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, labelSize.height + 14.0)] autorelease];
	nameLabel.text = self.fullname;
	nameLabel.numberOfLines = 0;
	nameLabel.lineBreakMode = UILineBreakModeWordWrap;
	nameLabel.font = font;
	nameLabel.backgroundColor = [UIColor clearColor];
	[header addSubview:nameLabel];
	[nameLabel release];

	self.tableView.tableHeaderView = header;

#ifdef USE_MOBILE_DEV
	CGFloat timeLimit = 300;
#else
    CGFloat timeLimit = 86400 * 14;
#endif
	// if lastUpdate is sufficiently long ago, issue a background search
	if ([[self.personDetails valueForKey:@"lastUpdate"] timeIntervalSinceNow] < -timeLimit) {
		if ([ConnectionDetector isConnected]) {
			// issue this query but don't care too much if it fails
			JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
            api.userData = RequestUpdatePersonDetails;
			[api requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"people", @"module", self.fullname, @"q", nil]];
		}
	}

    NSString *detailString = [NSString stringWithFormat:@"/people/detail?id=%@", self.personDetails.uid];
    [[AnalyticsWrapper sharedWrapper] trackPageview:detailString];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	
	self.sectionArray = nil;
	[personDetails release];
	[fullname release];
    [super dealloc];
}

#pragma mark -
#pragma mark Connection methods + wrapper delegate

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result {
    if ([request.userData isEqualToString:RequestUpdatePersonDetails]) {
         // fail silently
        if ([result isKindOfClass:[NSArray class]]) {
            for (NSDictionary *entry in result) {
                if ([[entry objectForKey:@"id"] isEqualToString:[self.personDetails valueForKey:@"uid"]]) {
                    self.personDetails = [PeopleRecentsData updatePerson:self.personDetails withSearchResult:entry];
                    [self.tableView reloadData];
                }
            }
        }

    } else if ([request.userData isEqualToString:RequestLookupAddress]) {
        
        NSArray *searchResults = [result objectForKey:@"results"];
        if ([searchResults count]) {
            [[MapBookmarkManager defaultManager] pruneNonBookmarks];
            NSDictionary *info = [searchResults objectAtIndex:0];
            addressSearchAnnotation = [[ArcGISMapAnnotation alloc] initWithInfo:info];
            if ([TileServerManager isInitialized]) {
                [[MapBookmarkManager defaultManager] saveAnnotationWithoutBookmarking:addressSearchAnnotation];
                NSIndexSet *sections = [NSIndexSet indexSetWithIndex:addressSection];
                [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [[NSNotificationCenter defaultCenter] addObserver:self 
                                                         selector:@selector(tileServerNotificationReceived)
                                                             name:kTileServerManagerProjectionIsReady
                                                           object:nil];
            }
        }
    }
}

- (void)tileServerNotificationReceived {
    [addressSearchAnnotation updateWithInfo:addressSearchAnnotation.info];
    
    // TODO: make a separate function for these three lines
    [[MapBookmarkManager defaultManager] saveAnnotationWithoutBookmarking:addressSearchAnnotation];
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:addressSection];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark -
#pragma mark Table view meth

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	return [self.sectionArray count] + 1;
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == [self.sectionArray count])
		return 2;
	return [[self.sectionArray objectAtIndex:section] count];
}

#define TEXTVIEW_TAG 235

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;

	NSString *cellID = [NSString stringWithFormat:@"%d",section];
	
	if (section == [self.sectionArray count]) { 
		// cells for Create New / Add Existing rows at the end
		// we are mimicking the style of UIButtonTypeRoundedRect until we find something more built-in
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
		
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
		}

		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
		cell.textLabel.textColor = STANDARD_CONTENT_FONT_COLOR;
		if (row == 0)
			cell.textLabel.text = @"Create New Contact";
		else
			cell.textLabel.text = @"Add to Existing Contact";
		
		return cell;
		
	} else { // cells for displaying person details
		MultiLineTableViewCell *cell = (MultiLineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
		
		if (cell == nil) {			
			cell = [[[MultiLineTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellID] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
		}
		
		NSArray *personInfo = [[self.sectionArray objectAtIndex:section] objectAtIndex:row];
		NSString *tag = [personInfo objectAtIndex:0];
		NSString *data = [personInfo objectAtIndex:1];
		
		cell.textLabel.text = tag;
        cell.textLabel.textColor = [UIColor colorWithHexString:@"#554C41"];
        
        // use a textView for the address so people can copy/paste.
        if ([tag isEqualToString:[personDetails displayNameForKey:@"postaladdress"]]) {
            addressSection = section;
            
            UIFont *font = [UIFont boldSystemFontOfSize:15.0];
            CGFloat width = [MultiLineTableViewCell widthForTextLabel:NO
                                                            cellStyle:UITableViewCellStyleValue2
                                                            tableView:self.tableView
                                                        accessoryType:UITableViewCellAccessoryDetailDisclosureButton
                                                            cellImage:NO
                                                             hasIndex:NO];
            
            // in MultiLineTableViewCell, we are assuming the detailTextLabel starts at 24% of the cell width
            // the following line is just replicates part of the calculation made in MultiLineTableViewCell
            CGFloat originX = 20.0 + floor((self.view.frame.size.width - 50.0) * 0.24);
            CGSize size = [data sizeWithFont:font
                           constrainedToSize:CGSizeMake(width, 2000.0f)
                               lineBreakMode:UILineBreakModeWordWrap];
            
            // -[MultiLineTableViewCell layoutSubviews] will adjust the originY to where the detailTextLabel is
            UITextView *textView = [[[UITextView alloc] initWithFrame:CGRectMake(originX, 0, width + 10, size.height)] autorelease];
            textView.text = data;
            textView.tag = TEXTVIEW_TAG;
            textView.backgroundColor = [UIColor clearColor];
            textView.font = font;
            textView.textColor = cell.detailTextLabel.textColor;
            textView.editable = NO;
            textView.scrollEnabled = NO;
            textView.contentInset = UIEdgeInsetsMake(-8, -9, -8, -9); // imitate the margins of UILabel (which detailTextLabel is)
            
            [cell.contentView addSubview:textView];
            
            // put a placeholder in the detailText so the textLabel will be top-aligned
            CGSize oneLineSize = [DirectoryTag sizeWithFont:font];
            NSInteger numLines = floor(size.height / oneLineSize.height);
            NSMutableString *placeholder = [NSMutableString stringWithString:@" "];
            while (numLines > 1) {
                [placeholder appendString:@"\n "];
                numLines--;
            }
            
            cell.detailTextLabel.text = placeholder;
            
            if (addressSearchAnnotation) {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
                textView.userInteractionEnabled = NO;
            } else {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewBlank];
                textView.userInteractionEnabled = YES;
            }

        } else {
            UIView *textView = [cell.contentView viewWithTag:TEXTVIEW_TAG];
            if (textView)
                [textView removeFromSuperview];
            cell.detailTextLabel.text = data;
        }
        
		
		if ([tag isEqualToString:[personDetails displayNameForKey:@"mail"]]) {
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
            cell.detailTextLabel.minimumFontSize = 8;
		} else if ([tag isEqualToString:[personDetails displayNameForKey:@"telephonenumber"]]) {
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
		}/* else if ([tag isEqualToString:[personDetails displayNameForKey:@"postaladdress"]]) {
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            if (addressSearchAnnotation) {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
            } else {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewBlank];
            }
		}*/ else {
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
			return cell;
		}
		
		return cell;
	}	
}

- (void)tableView:(UITableView *)tableView 
  willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.sectionArray.count > indexPath.section) {
        NSArray *rowArray = [self.sectionArray objectAtIndex:indexPath.section];
        if (rowArray.count > indexPath.row) {
            NSArray *personInfo = [rowArray objectAtIndex:indexPath.row];
            if (personInfo.count > 0) {            
                NSString *personTag = [personInfo objectAtIndex:0];
                if ([personTag isEqualToString:@"email"]) {
                    // Is this going to be one or two lines?
                    CGSize textSize = 
                    [cell.detailTextLabel.text 
                     sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]
                     constrainedToSize:CGSizeMake(kEmailLineBreakThresholdWidth, 1000)
                     lineBreakMode:UILineBreakModeCharacterWrap];
                    if (textSize.height <= kMaxHeightOfSingleLineOfEmailText) {
                        // If it's going to fit on one line, set font size adjustment 
                        // up so that things don't touch the accessory view.
                        cell.detailTextLabel.numberOfLines = 1;
                        cell.detailTextLabel.font = 
                        [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
                        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
                    }
                     
                }
            }
        }
    }
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	
	NSInteger row = indexPath.row;
	NSInteger section = indexPath.section;
	if (section == [self.sectionArray count]) {
		return 44.0;
	}
	
	NSArray *personInfo = [[self.sectionArray objectAtIndex:section] objectAtIndex:row];
	NSString *tag = [personInfo objectAtIndex:0];
	NSString *data = [personInfo objectAtIndex:1];
        
	// If the cell's 'tag' string matches the display name for any of these personDetails properties, 
	// add a disclosure button.
    UITableViewCellAccessoryType accessoryType = 
	([tag isEqualToString:[personDetails displayNameForKey:@"telephonenumber"]] || 
	 [tag isEqualToString:[personDetails displayNameForKey:@"mail"]])
    ? UITableViewCellAccessoryDetailDisclosureButton
    : UITableViewCellAccessoryNone;
    
    // special case for addresses: add a disclosure button if we find something,
    // otherwise don't indicate this as an actionable cell
    if ([tag isEqualToString:[personDetails displayNameForKey:@"postaladdress"]]) {
        if (!addressSearchAnnotation) {
            // issue a prelim search for person's address
            
            NSString *searchText = [AddressFormatter streetAddressFromAddressBlockText:data];
            JSONAPIRequest *apiRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
            apiRequest.userData = RequestLookupAddress;
            [apiRequest requestObjectFromModule:@"map"
                                        command:@"search"
                                     parameters:[NSDictionary dictionaryWithObjectsAndKeys:searchText, @"q", nil]];
        }
        accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    return [MultiLineTableViewCell heightForCellWithStyle:UITableViewCellStyleValue2
                                                tableView:tableView 
                                                     text:tag
                                             maxTextLines:1
                                               detailText:data
                                           maxDetailLines:0
                                                     font:nil
                                               detailFont:[UIFont boldSystemFontOfSize:15.0]  
                                            accessoryType:accessoryType
                                                cellImage:NO];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == [self.sectionArray count]) { // user selected create/add to contacts
		
		if (indexPath.row == 0) { // create addressbook entry
			ABRecordRef person = ABPersonCreate();
			CFErrorRef error = NULL;
			NSString *value;
		
			// set single value properties
			if (value = [self.personDetails formattedValueForKey:@"givenname"])
				ABRecordSetValue(person, kABPersonFirstNameProperty, value, &error);
			if (value = [self.personDetails formattedValueForKey:@"sn"])
				ABRecordSetValue(person, kABPersonLastNameProperty, value, &error);
			if (value = [self.personDetails formattedValueForKey:@"title"])
				ABRecordSetValue(person, kABPersonJobTitleProperty, value, &error);
			if (value = [self.personDetails formattedValueForKey:@"ou"])
				ABRecordSetValue(person, kABPersonDepartmentProperty, value, &error);
		
			// set multivalue properties: email and phone numbers
			ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
			if ([self.personDetails formattedValueForKey:@"mail"]) {
				[self addMultivalueValuesAndLabelsTo:multiEmail usingLabel:kABWorkLabel withValuesFromLDAPKey:@"mail"];
				ABRecordSetValue(person, kABPersonEmailProperty, multiEmail, &error);
			}
			CFRelease(multiEmail);
		
			BOOL haveValues = NO;
			ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
			if ([self.personDetails formattedValueForKey:@"telephonenumber"]) {
				[self addMultivalueValuesAndLabelsTo:multiPhone usingLabel:kABWorkLabel withValuesFromLDAPKey:@"telephonenumber"];
				ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone, &error);
				haveValues = YES;
			}
			if ([self.personDetails formattedValueForKey:@"facsimiletelephonenumber"]) {
				[self addMultivalueValuesAndLabelsTo:multiPhone usingLabel:kABPersonPhoneWorkFAXLabel withValuesFromLDAPKey:@"facsimiletelephonenumber"];
				haveValues = YES;
			}
			if (haveValues) {
				ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone, &error);
			}
			CFRelease(multiPhone);
			
			ABNewPersonViewController *creator = [[ABNewPersonViewController alloc] init];
			creator.displayedPerson = person;
			[creator setNewPersonViewDelegate:self];
			
			// present newPersonController in a separate navigationController
			// since it doesn't have its own nav bar
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:creator];
			
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			[appDelegate presentAppModalViewController:navController animated:YES];

			[creator release];
			[navController release];
			
		} else {
			ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
			[picker setPeoplePickerDelegate:self];
			
			MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
			[appDelegate presentAppModalViewController:picker animated:YES];
			
			[picker release];
		}
		
	} else {
		
		NSArray *personInfo = [[self.sectionArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		NSString *tag = [personInfo objectAtIndex:0];
		
		// React if the cell tapped has text that that matches the display name of mail, telephonenumber, or postaladdress.
		if ([tag isEqualToString:[personDetails displayNameForKey:@"mail"]])
			[self emailIconTapped:[personInfo objectAtIndex:1]];
		else if ([tag isEqualToString:[personDetails displayNameForKey:@"telephonenumber"]])
			[self phoneIconTapped:[personInfo objectAtIndex:1]];
		else if ([tag isEqualToString:[personDetails displayNameForKey:@"postaladdress"]] && addressSearchAnnotation)
			[self mapIconTapped:[personInfo objectAtIndex:1]];

	}
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark -
#pragma mark Address book methods

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}

- (BOOL)        personViewController:(ABPersonViewController *)personViewController 
 shouldPerformDefaultActionForPerson:(ABRecordRef)person 
							property:(ABPropertyID)property 
						  identifier:(ABMultiValueIdentifier)identifierForValue
{
	return NO;
}

/* when they pick a person we are recreating the entire record using
 * the union of what was previously there and what we received from
 * the server
 */
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	CFErrorRef error;
	
	ABAddressBookRef ab = ABAddressBookCreate();
	
	//ABPersonViewController *personController = [[ABPersonViewController alloc] init];
	//personController.personViewDelegate = self;
	//personController.allowsEditing = YES;
	//personController.displayedPerson = person;

	NSString *ldapValue = nil;
	ABRecordRef newPerson = ABPersonCreate();
	CFTypeRef recordValue = NULL;
	
	// get values for single-value properties
    recordValue = ABRecordCopyValue(person, kABPersonFirstNameProperty);
	if (recordValue != nil) {
		ABRecordSetValue(newPerson, kABPersonFirstNameProperty, recordValue, &error);
        CFRelease(recordValue);
    }
	else if (ldapValue = [self.personDetails formattedValueForKey:@"givenname"])
		ABRecordSetValue(newPerson, kABPersonFirstNameProperty, ldapValue, &error);
	
    recordValue = ABRecordCopyValue(person, kABPersonLastNameProperty);
	if (recordValue != nil) {
        ABRecordSetValue(newPerson, kABPersonLastNameProperty, recordValue, &error);
        CFRelease(recordValue);
    }
	else if (ldapValue = [self.personDetails formattedValueForKey:@"sn"])
		ABRecordSetValue(newPerson, kABPersonLastNameProperty, ldapValue, &error);
	
    recordValue = ABRecordCopyValue(person, kABPersonJobTitleProperty);
	if (recordValue != nil) {
        ABRecordSetValue(newPerson, kABPersonJobTitleProperty, recordValue, &error);
        CFRelease(recordValue);
    }
	else if (ldapValue = [self.personDetails formattedValueForKey:@"title"])
		ABRecordSetValue(newPerson, kABPersonJobTitleProperty, ldapValue, &error);
	
    recordValue = ABRecordCopyValue(person, kABPersonDepartmentProperty);
	if (recordValue != nil) {
        ABRecordSetValue(newPerson, kABPersonDepartmentProperty, recordValue, &error);
        CFRelease(recordValue);
    }
	else if (ldapValue = [self.personDetails formattedValueForKey:@"ou"])
		ABRecordSetValue(newPerson, kABPersonDepartmentProperty, ldapValue, &error);
		
	// multi value phone property (including fax numbers)
	ABMultiValueRef multi = ABRecordCopyValue(person, kABPersonPhoneProperty);
	ABMutableMultiValueRef phone = ABMultiValueCreateMutableCopy(multi);
	[self addMultivalueValuesAndLabelsTo:phone usingLabel:kABWorkLabel withValuesFromLDAPKey:@"telephonenumber"];
	[self addMultivalueValuesAndLabelsTo:phone usingLabel:kABPersonPhoneWorkFAXLabel withValuesFromLDAPKey:@"facsimiletelephonenumber"];

	ABRecordSetValue(newPerson, kABPersonPhoneProperty, phone, &error);
	CFRelease(phone);
    CFRelease(multi);
	
	// multi value email property
	multi = ABRecordCopyValue(person, kABPersonEmailProperty);
	ABMutableMultiValueRef email = ABMultiValueCreateMutableCopy(multi);
	[self addMultivalueValuesAndLabelsTo:email usingLabel:kABWorkLabel withValuesFromLDAPKey:@"mail"];
	ABRecordSetValue(newPerson, kABPersonEmailProperty, email, &error);
	CFRelease(email);

	CFRelease(multi);
	
	// save all the stuff we unilaterally overwrote with the user's barely informed consent
	ABAddressBookRemoveRecord(ab, person, &error);
    ABAddressBookAddRecord(ab, newPerson, &error);
    ABAddressBookHasUnsavedChanges(ab);
    ABAddressBookSave(ab, &error);
	CFRelease(newPerson);
    CFRelease(ab);
	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
	
	return NO; // don't navigate to built-in view
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person 
								property:(ABPropertyID)property 
							  identifier:(ABMultiValueIdentifier)identifier
{
	return NO;
}
	
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark App-switching actions

- (void)mapIconTapped:(NSString *)address
{
    NSURL *internalURL = [NSURL internalURLWithModuleTag:CampusMapTag
                                                    path:LocalPathMapsSelectedAnnotation
                                                   query:addressSearchAnnotation.uniqueID];

    [[UIApplication sharedApplication] openURL:internalURL];
}

- (void)phoneIconTapped:(NSString *)phone
{
	NSArray *phoneNumbers = [phone componentsSeparatedByString:@"\n"];
	if(phoneNumbers.count > 0) {
		NSString *firstNumber = [phoneNumbers objectAtIndex:0];
		NSURL *externURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", firstNumber]];
		if ([[UIApplication sharedApplication] canOpenURL:externURL]) {
			if (phoneNumbers.count == 1) {
				// just call the single number
				[[UIApplication sharedApplication] openURL:externURL];
			} else {
				// for multiple numbers bring up a dialog 
				// asking the user which number to call
				UIAlertView *alertView = [[UIAlertView alloc] 
											  initWithTitle:@"Call"	
											  message:nil
											  delegate:self
											  cancelButtonTitle:@"Cancel"					
											  otherButtonTitles:nil];
				
				// add phone number button
				for (NSString *phoneNumber in phoneNumbers) {
					[alertView addButtonWithTitle:phoneNumber];
				}
				
				[alertView show];
				[alertView release];
			}
		}
	}
}

- (void)emailIconTapped:(NSString *)email
{
    [MITMailComposeController presentMailControllerWithEmail:email subject:nil body:nil];
}

@end


