#import <CoreData/CoreData.h>


@interface ShuttleRouteCache :  NSManagedObject
{
}

@property (nonatomic, retain) id path;
@property (nonatomic, retain) NSString * routeID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * interval;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSSet* stops;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSString * agency;
@property (nonatomic, retain) NSString * color;
@property (nonatomic, retain) NSString * routeDescription;
 
@end

