/* ShuttleStop represents a stop along a specific route,
 * i.e. a unique route-stop combination.
 * Stop location information that does not vary by route is stored in the stopLocation property.
 * This is a retrofit interface that combines the old ShuttleStop with RouteStopSchedule
 */

#import <Foundation/Foundation.h>

@class ShuttleStopLocation;
@class ShuttleRouteStop;

@interface ShuttleStop : NSObject {
	
	BOOL _upcoming;
	NSArray *_predictions;

	ShuttleStopLocation *_stopLocation;
	ShuttleRouteStop *_routeStop;
}

- (void)updateInfo:(NSDictionary *)stopInfo referenceDate:(NSDate *)refDate;

- (id)initWithRouteStop:(ShuttleRouteStop *)routeStop;
- (id)initWithStopLocation:(ShuttleStopLocation *)stopLocation routeID:(NSString *)routeID;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *stopID;
@property double latitude;
@property double longitude;
@property (nonatomic, retain) NSArray *routeStops;
@property (nonatomic, retain) NSString* direction;

@property (nonatomic, readonly) NSString* routeID;
@property (nonatomic, retain) NSArray* path;
@property (nonatomic, assign) NSInteger order;
@property (nonatomic, retain) ShuttleRouteStop *routeStop;

@property (nonatomic, retain) NSDate *nextScheduledDate;
@property (nonatomic, retain) NSArray* predictions;
@property BOOL upcoming;

@end
