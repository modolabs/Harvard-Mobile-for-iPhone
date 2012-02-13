#import <Foundation/Foundation.h>
#import "MITMapRoute.h"
#import "ShuttleRouteCache.h"

@interface ShuttleRoute : NSObject <MITMapRoute> {
    BOOL _gpsActive;
    BOOL _isRunning;
	ShuttleRouteCache *_cache;
	
    NSMutableArray *_stops;
	NSMutableDictionary *_stopsById;
	
	// parsed path locations for the entire route. 
	NSMutableArray* _pathLocations;
	
	// annotaions for each shuttle stop 
	NSMutableArray* _stopAnnotations;
	
	// locations, if available of any vehicles on the route. 
	NSArray* _vehicleLocations;
}

- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithCache:(ShuttleRouteCache *)cachedRoute;
- (void)updateInfo:(NSDictionary *)routeInfo;
- (void)getStopsFromCache;
- (void)updatePath;

- (NSString *)fullSummary;
- (NSString *)trackingStatus;

// transient properties

@property (nonatomic, assign) BOOL liveStatusFailed;
@property (nonatomic, assign) BOOL gpsActive;
@property (nonatomic, assign) BOOL isRunning;

@property (nonatomic, retain) NSString *nextStopId;
@property (nonatomic, retain) NSArray *vehicleLocations;

// drawing properties

@property (nonatomic, retain) NSString *agency;
@property (nonatomic, retain) NSString *color;

@property (nonatomic, retain) NSString *stopMarkerURL;
@property (nonatomic, retain) NSString *genericMarkerURL;
@property (nonatomic, retain) UIImage *genericMarkerImage;

// properties of associated ShuttleRouteCache object

@property (nonatomic, retain) NSString *routeDescription;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *summary;
@property (nonatomic, assign) NSInteger interval;
@property (nonatomic, retain) NSString *routeID;
@property (nonatomic, assign) NSInteger sortOrder;
@property (nonatomic, retain) NSArray *path;

// other core data properties

@property (readwrite, retain) ShuttleRouteCache *cache;
@property (nonatomic, retain) NSMutableArray *stops;

@end
