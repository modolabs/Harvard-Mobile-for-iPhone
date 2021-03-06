/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import <Foundation/Foundation.h>

#define OPEN 1
#define CLOSED 2
#define NO_RESTRICTION 3
#define RESTRICTED 4

@interface DiningHallStatus : NSObject {
	
	NSInteger breakfast_status;
	NSInteger breakfast_restriction;
	NSInteger lunch_status;
	NSInteger lunch_restriction;
	NSInteger dinner_status;
	NSInteger dinner_restriction;
	NSInteger bb_status;
	NSInteger bb_restriction;
	NSInteger brunch_status;
	NSInteger brunch_restriction;
	
	NSString *currentMeal;
	NSString *nextMeal;
	NSString *currentMealTime;
	NSString *nextMealTime;
	
	NSInteger nextMealStatus;
	
	NSInteger currentStat;
	
	NSString *hallName;

}

@property  NSInteger breakfast_status;
@property  NSInteger breakfast_restriction;
@property  NSInteger lunch_status;
@property  NSInteger lunch_restriction;
@property  NSInteger dinner_status;
@property  NSInteger dinner_restriction;
@property  NSInteger bb_status;
@property  NSInteger bb_restriction;
@property  NSInteger brunch_status;
@property NSInteger brunch_restriction;
@property (nonatomic, retain) NSString *currentMeal;
@property (nonatomic, retain) NSString *nextMeal;
@property (nonatomic, retain) NSString *currentMealTime;
@property NSInteger nextMealRestriction;
@property (nonatomic, retain) NSString *nextMealTime;
@property NSInteger nextMealStatus;

@property (nonatomic, retain) NSString *hallName;

@property NSInteger currentStat;

-(BOOL)isCorrectDay:(NSString*)day dayIndex:(int)index;
-(int)getStatusOfMeal:(NSString *)timeString usingDetails:(NSDictionary *)details;
-(int)getStatus:(NSString *)timeString mealTime:(int)mealIndex;
-(int)gettime:(NSString *)component;
-(void)setStat:(int)status;
@end
