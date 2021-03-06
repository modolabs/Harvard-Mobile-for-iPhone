/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "DiningHallStatus.h"


@implementation DiningHallStatus

@synthesize breakfast_status;
@synthesize breakfast_restriction;
@synthesize lunch_status;
@synthesize lunch_restriction;
@synthesize dinner_status;
@synthesize dinner_restriction;
@synthesize bb_status;
@synthesize bb_restriction;
@synthesize brunch_status;
@synthesize brunch_restriction;
@synthesize currentMeal;
@synthesize nextMeal;
@synthesize currentMealTime;
@synthesize nextMealRestriction;
@synthesize nextMealTime;
@synthesize nextMealStatus;
@synthesize hallName;

@synthesize currentStat;


int timeToNextMeal;  //starting with ONE DAY

-(BOOL)isCorrectDay:(NSString*)day dayIndex:(int)index {
	
	BOOL correctDay = NO;
	
	switch (index) {
		case 0:
			if ([day isEqualToString:@"Monday"] || [day isEqualToString:@"Tuesday"] || [day isEqualToString:@"Wednesday"]
				|| [day isEqualToString:@"Thursday"] || [day isEqualToString:@"Friday"] || [day isEqualToString:@"Saturday"])
				correctDay = YES;
			else {
				correctDay = NO;
			}
			break;
		case 1:
			if ([day isEqualToString:@"Monday"] || [day isEqualToString:@"Tuesday"] || [day isEqualToString:@"Wednesday"]
				|| [day isEqualToString:@"Thursday"] || [day isEqualToString:@"Friday"] || [day isEqualToString:@"Saturday"])
				correctDay = YES;
			else {
				correctDay = NO;
			}
			break;
		case 2:
			correctDay = YES;
			break;
		case 3:
			if ([day isEqualToString:@"Monday"] || [day isEqualToString:@"Tuesday"] || [day isEqualToString:@"Wednesday"]
				|| [day isEqualToString:@"Thursday"] || [day isEqualToString:@"Sunday"])
				correctDay = YES;
			else {
				correctDay = NO;
			}
			
			break;
		case 4:
			if ([day isEqualToString:@"Sunday"])
				correctDay = YES;
			else {
				correctDay = NO;
			}
			break;
			
	}
	
	return correctDay;
}

-(int)getStatusOfMeal:(NSString *)timeString usingDetails:(NSDictionary *)details {
	
	BOOL correctDay = NO;
	NSString *message;
	NSString *hoursKey;
	NSString *restrictionKey;
	int status; 
	int restriction;
	int current_meal_restriction;
	
	NSString *dayOfWeek;

	NSDate *today = [NSDate date];
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	
	[dateFormat setDateFormat:@"EEEE"];
	dayOfWeek= [dateFormat stringFromDate:today];
    [dateFormat release];
	timeToNextMeal = 24*60*60;
	for (int index=0; index < 5; index++) {
		switch (index) {
			case 0:
				hoursKey = @"breakfast_hours";
				restrictionKey = @"NA";
				correctDay = [self isCorrectDay:dayOfWeek dayIndex:index];
				break;
			case 1:
				hoursKey = @"lunch_hours";
				restrictionKey = @"lunch_restrictions";
				correctDay = [self isCorrectDay:dayOfWeek dayIndex:index];
				break;
			case 2:
				hoursKey = @"dinner_hours";
				restrictionKey = @"dinner_restrictions";
				correctDay = YES;
				break;
			case 3:
				hoursKey = @"bb_hours";
				restrictionKey = @"NA";
				correctDay = [self isCorrectDay:dayOfWeek dayIndex:index];

				break;
			case 4:
				hoursKey = @"brunch_hours";
				restrictionKey = @"brunch_restrictions";
				correctDay = [self isCorrectDay:dayOfWeek dayIndex:index];
				break;
				
		}
		
		NSString *timeStr = [details objectForKey:hoursKey];
		
		if (![timeStr isEqualToString:@"NA"]) {
			
			status = [self getStatus:timeStr mealTime:index];
		}
		
		else {
			status = CLOSED;
		}
			
		NSDictionary *restrictions = [details objectForKey:restrictionKey];
		message  = [[restrictions valueForKey:@"message"] description];

		
		NSArray *messageArray = [message componentsSeparatedByString:@"\""];
		
		if ([messageArray count] == 3) {
			//message = [messageArray objectAtIndex:1];
			restriction = RESTRICTED;
		}
		
		else {
			//message = @"None";
			restriction = NO_RESTRICTION;
		}
		
		NSString *restrictionDaysString = [[restrictions valueForKey:@"days"] description];
		
		NSRange range = [restrictionDaysString rangeOfString:dayOfWeek];

		if (range.location == NSNotFound) {
			restriction = NO_RESTRICTION;
		}
		
		if (correctDay == NO) {
			status =  CLOSED;
		}
		
		/*
		 NSString *timeStr =  [[restrictions valueForKey:@"time"] description];
		 NSArray *timeArray = [timeStr componentsSeparatedByString:@"\""];
		 
		 if ([timeArray count] == 3) {
		 timeStr = [[timeArray objectAtIndex:1] description];
		 int r = 2;
		 }
		 
		 else {
		 timeStr = @"None";
		 }
		 
		 int restriction;
		 if ([message isEqualToString:@"None"] && [timeStr isEqualToString:@"None"])
		 restriction = NO_RESTRICTION;
		 
		 else if (![message isEqualToString:@"None"] &&[timeStr isEqualToString:@"None"])
		 restriction = RESTRICTED;
		 
		 else if (![message isEqualToString:@"None"] && ![timeStr isEqualToString:@"None"]) {
		 int status_of_restriction = [self getStatusOfMeal:timeStr];
		 
		 if (status_of_restriction == OPEN)
		 restriction = RESTRICTED;
		 
		 else {
		 restriction = NO_RESTRICTION;
		 }
		 
		 }
		 int tsfdss = restriction; */
		
		
		

		//populate the correct meal-status
		switch (index) {
			case 0:
				breakfast_status = status;
				breakfast_restriction = NO_RESTRICTION;
				
				if (status == OPEN) {
					current_meal_restriction = breakfast_restriction;
					currentMeal = @"Breakfast";
					currentMealTime = timeStr;
				}
				break;
			case 1:
				lunch_status = status;
				lunch_restriction = restriction;
				if (status == OPEN) {
					current_meal_restriction = lunch_restriction;
					currentMeal = @"Lunch";
					currentMealTime = timeStr;
				}
				break;
			case 2:
				dinner_status = status;
				dinner_restriction = restriction;
				if (status == OPEN) {
					current_meal_restriction = dinner_restriction;	
					currentMeal = @"Dinner";
					currentMealTime = timeStr;
				}
				break;
			case 3:
				bb_status = status;
				bb_restriction = NO_RESTRICTION;
				if (status == OPEN) {
					current_meal_restriction = bb_restriction;
					currentMeal = @"Brain-Break";
					currentMealTime = [timeStr stringByReplacingOccurrencesOfString:@"starting" withString:@""];
				}
				break;
			case 4:
				brunch_status = status;
				brunch_restriction = restriction;
				if (status == OPEN) {
					current_meal_restriction = brunch_restriction;	
					currentMeal = @"Brunch";
					currentMealTime = timeStr;
				}
				break;
				
				
				
		}
	}
	
	
	if ((breakfast_status == OPEN) || (lunch_status == OPEN) || (dinner_status == OPEN) || (bb_status == OPEN) || (brunch_status == OPEN)) {
		if (current_meal_restriction == RESTRICTED) {
			return RESTRICTED;
		}
		else {
			return OPEN;
		}
	}
	else {
		
		if ([nextMeal isEqualToString:@"Breakfast"]) {
				nextMeal = @"Breakfast ";
				nextMealRestriction = breakfast_restriction;
				nextMealStatus = breakfast_status;
		}
		else if ([nextMeal isEqualToString:@"Lunch"]) {
			nextMeal = @"Lunch ";
			nextMealRestriction = lunch_restriction;
			nextMealStatus = lunch_status;
		}
		else if ([nextMeal isEqualToString:@"Dinner"]) {
			nextMeal = @"Dinner ";
			nextMealRestriction = dinner_restriction;
			nextMealStatus = dinner_status;
		}
		else if ([nextMeal isEqualToString:@"Brain-Break"]) {
			nextMeal = @"Brain Break ";
			nextMealRestriction = bb_restriction;
			nextMealStatus = bb_status;
		}
		else if ([nextMeal isEqualToString:@"Brunch"]) {
			nextMeal = @"Brunch ";
			nextMealRestriction = brunch_restriction;
			nextMealStatus = brunch_status;
		}
		
		return CLOSED;
	}
}



-(int)getStatus:(NSString *)timeString mealTime:(int)mealIndex{
	
	
	NSString *comp1;
	NSString *comp2;
	NSArray *compArray;
	int start;
	int end;
	int now;
	NSString *dayOfWeek;
	int currentHour;
	
	NSRange range1 = [timeString rangeOfString:@"starting "];
	
	if (range1.location != NSNotFound) {
		comp1 = [timeString stringByReplacingOccurrencesOfString:@"starting " withString:@""];
		start = [self gettime:comp1];
		end = (24*60*60);
	}
	
	else {
		compArray = [timeString componentsSeparatedByString:@"-"];
		
		comp1 = [compArray objectAtIndex:0];
		start = [self gettime:comp1];
		comp2 = [compArray objectAtIndex:1];
		end = [self gettime:comp2];
		
		NSRange range, range1, range3;
		
		range = [comp2 rangeOfString:@"pm"];
		range1 = [comp1 rangeOfString:@"Noon"];
		range3 = [comp1 rangeOfString:@"am"];
		
		if ((range.location != NSNotFound) && (range1.location == NSNotFound) && (range3.location == NSNotFound)){
			start += (12*60*60); // coverting to pm start time
		}
	}
	
	
	//NSDate *today = [NSDate date];
	
	
	// The date in your source timezone
	NSDate* sourceDate = [NSDate date];
	
	NSTimeZone* sourceTimeZone = [NSTimeZone defaultTimeZone];
	NSTimeZone* destinationTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"EST"];
	
	NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
	NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
	NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
	
	NSDate* today = [[[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate] autorelease];
	
	
	
	// Display the Date in the Expected Format: Saturday, June 25
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"EEEE MMMM d"];
	
	[dateFormat setDateFormat:@"HH:mm"];
	NSString *time = [dateFormat stringFromDate:today];
	
	now = [self gettime:time];
	
	[dateFormat release];
	
	NSDateFormatter *dateFormatDay = [[NSDateFormatter alloc] init];
	[dateFormatDay setDateFormat:@"EEEE"];
	dayOfWeek= [dateFormatDay stringFromDate:today];
	[dateFormatDay release];
	
	NSDateFormatter *dateFormatHour = [[NSDateFormatter alloc] init];
	[dateFormatHour setDateFormat:@"HH"];
	currentHour= [[dateFormatHour stringFromDate:today] intValue];
	[dateFormatHour release];
	
	
	if ((now >= start) && (now < end))
		return OPEN;
	
	else {
		if (((start - now) >= 0) && ((start - now) < timeToNextMeal)) {
			
			
			switch (mealIndex) {
				case 0:
					nextMeal = @"Breakfast";
					timeToNextMeal = (start - now);
					break;
				case 1:
					nextMeal = @"Lunch";
					timeToNextMeal = (start - now);
					break;
				case 2:
					nextMeal = @"Dinner";
					timeToNextMeal = (start - now);
					break;
				case 3:
					nextMeal = @"Brain-Break";
					timeToNextMeal = (start - now);
					break;
				case 4:
					if (([dayOfWeek isEqualToString:@"Sunday"]) ||
							(([dayOfWeek isEqualToString:@"Saturday"]) && (currentHour > 18)))
					nextMeal = @"Brunch";
					timeToNextMeal = (start - now);
					break;
			}
			nextMealTime = [timeString stringByReplacingOccurrencesOfString:@"starting" withString:@""];
		}
		
		
	return CLOSED;
	}

}



-(int)gettime:(NSString *)component  {
	int hours = 0;
	int mins = 0;
	
	NSRange range;
	
	range = [component rangeOfString:@"am"];
	
	if (range.location != NSNotFound) {
		component = [component stringByReplacingOccurrencesOfString:@"am" withString:@""];
	}
	
	range = [component rangeOfString:@"pm"];
	
	if (range.location != NSNotFound) {
		component = [component stringByReplacingOccurrencesOfString:@"pm" withString:@""];
		hours +=  12;
	}
	
	range = [component rangeOfString:@"Noon"];
	
	if (range.location != NSNotFound) {
		component = [component stringByReplacingOccurrencesOfString:@"Noon" withString:@"12:00"];
	}
	
	NSString *hourString = [[[component componentsSeparatedByString:@":"] objectAtIndex:0] description];
	NSString *minString = [[[component componentsSeparatedByString:@":"] objectAtIndex:1] description];
	
	hours += [hourString intValue];
	mins += [minString intValue];
	
	return (hours*60*60 + mins*60);
	
}

-(void)setStat:(int)status {
	self.currentStat = status;
	return;
}

@end
