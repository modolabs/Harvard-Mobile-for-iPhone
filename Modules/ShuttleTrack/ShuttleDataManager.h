#import <Foundation/Foundation.h>
#import "JSONAPIRequest.h"

@class ShuttleStop;
@class ShuttleRoute;
@class ShuttleRouteCache;
@class ShuttleStopLocation;

@protocol ShuttleDataManagerDelegate<NSObject>

// everything is optional. 
@optional

// message sent when routes were received. If request failed, this is called with a nil routes array
-(void) routesReceived:(NSArray*) routes;

// message sent when a shuttle stop is received. If request fails, this is called with nil 
-(void) stopInfoReceived:(NSArray*)shuttleStopSchedules forStopID:(NSString*)stopID;

// message sent when a shuttle route is received. If request fails, this is called with nil
-(void) routeInfoReceived:(ShuttleRoute*)shuttleRoute forRouteID:(NSString*)routeID;

- (void)announcementsReceived:(NSDictionary *)announcements urgentCount:(NSUInteger)urgentCount;
- (void)infoReceived:(NSDictionary *)info;

@end


@interface ShuttleDataManager : NSObject <JSONAPIDelegate> {

	// cached shuttle routes.
	NSMutableArray* _shuttleRoutes;
	
	// cached shuttle routes sorted by route ID
	NSMutableDictionary* _shuttleRoutesByID;
	
	// cached shuttle stops locations. 
	NSMutableArray* _stopLocations;
	NSMutableDictionary *_stopLocationsByID;
	
	// registered delegates
	NSMutableSet* _registeredDelegates;
	
	// counter to limit error dialogs from requests on the 2 second timer
	NSInteger _requestRouteErrorCount;

    JSONAPIRequest *_infoRequest;
    JSONAPIRequest *_routesRequest;
    JSONAPIRequest *_routeRequest;
    JSONAPIRequest *_stopRequest;
    JSONAPIRequest *_announcementsRequest;
    
    NSMutableDictionary *_markerImages;
}

@property (readonly) NSArray* shuttleRoutes;
@property (readonly) NSDictionary* shuttleRoutesByID;
@property (readonly) NSArray* stopLocations;
@property (readonly) NSDictionary *stopLocationsByID;

// get the signleton data manager
+(ShuttleDataManager*) sharedDataManager;

// return a list of all shuttle stops.
// this method is only here for backwards compatibility with CampusMapViewController
// which includes a function to display all shuttle stops on the map
// though that function is not used as we decided to get rid of the shuttle button from the UI
// so this can go away if that goes away
- (NSArray *)shuttleStops;

+ (ShuttleRoute *)shuttleRouteWithID:(NSString *)routeID;
+ (ShuttleRouteCache *)routeCacheWithID:(NSString *)routeID;
+ (ShuttleStop *)stopWithRoute:(NSString *)routeID stopID:(NSString *)stopID error:(NSError **)error;
+ (ShuttleStopLocation *)stopLocationWithID:(NSString *)stopID;

// delegate registration and unregistration
-(void) registerDelegate:(id<ShuttleDataManagerDelegate>)delegate;

-(void) unregisterDelegate:(id<ShuttleDataManagerDelegate>)delegate;

- (void)requestInfo;
- (void)requestRoutes;
- (void)requestRoute:(NSString *)routeID;
- (void)requestStop:(NSString *)stopID;
- (void)requestAnnouncements;

- (UIImage *)imageForURL:(NSString *)urlString;

@end
