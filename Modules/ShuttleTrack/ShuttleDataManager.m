#import "ShuttleDataManager.h"
#import "ShuttleRoute.h"
#import "ShuttleStop.h"
#import "ShuttleRouteStop.h"
#import "CoreDataManager.h"
#import "Constants.h"

static ShuttleDataManager* s_dataManager = nil;

@interface ShuttleDataManager(Private)

-(void) sendRoutesToDelegates:(NSArray*)routes;
-(void) sendStopToDelegates:(NSArray*)shuttleStopSchedules forStopID:(NSString*)stopID;
-(void) sendRouteToDelegates:(ShuttleRoute *)route forRouteID:(NSString*)routeID;

- (ShuttleRoute *)shuttleRouteWithID:(NSString *)routeID;
- (ShuttleRouteCache *)routeCacheWithID:(NSString *)routeID;
- (ShuttleStop *)stopWithRoute:(NSString *)routeID stopID:(NSString *)stopID error:(NSError **)error;
- (ShuttleStopLocation *)stopLocationWithID:(NSString *)stopID;

@end

// At 2 queries per second this results in an error dialog every 20 seconds
#define MAX_CONSECUTIVE_ERROR_COUNT 10


@implementation ShuttleDataManager
@synthesize shuttleRoutes = _shuttleRoutes;
@synthesize shuttleRoutesByID = _shuttleRoutesByID;
@synthesize stopLocations = _stopLocations;
@synthesize stopLocationsByID = _stopLocationsByID;

+ (ShuttleDataManager *)sharedDataManager {
    @synchronized(self) {
        if (s_dataManager == nil) {
            self = (id)[[super allocWithZone:NULL] init]; 
			s_dataManager = (ShuttleDataManager *)self;
        }
    }
	
    return s_dataManager;
}

-(void) dealloc
{
	[_shuttleRoutes release];
	[_shuttleRoutesByID release];
	
	[_registeredDelegates release];
	
	[super dealloc];
}


- (id)init {
    self = [super init];
    if (self) {
        _stopLocations = nil;
        _stopLocationsByID = nil;
        _requestRouteErrorCount = 0;
        
        // populate route cache in memory
        _shuttleRoutes = [[NSMutableArray alloc] init];	
        _shuttleRoutesByID = [[NSMutableDictionary alloc] init];
        
        NSPredicate *matchAll = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
        NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES] autorelease];
        NSArray *cachedRoutes = [CoreDataManager objectsForEntity:ShuttleRouteEntityName
                                                matchingPredicate:matchAll
                                                  sortDescriptors:[NSArray arrayWithObject:sort]];
        DLog(@"%d routes cached", [cachedRoutes count]);
        
        for (ShuttleRouteCache *cachedRoute in cachedRoutes) {
            NSString *routeID = cachedRoute.routeID;
            ShuttleRoute *route = [[[ShuttleRoute alloc] initWithCache:cachedRoute] autorelease];
            DLog(@"fetched route %@ from core data", route.routeID);
            [_shuttleRoutes addObject:route];
            [_shuttleRoutesByID setValue:route forKey:routeID];
        }
    }
	
	return self;
}

# pragma mark core data abstraction

- (NSArray *)shuttleStops
{
	NSArray *routeStops = [CoreDataManager objectsForEntity:ShuttleRouteStopEntityName
										  matchingPredicate:[NSPredicate predicateWithFormat:@"TRUEPREDICATE"]];
	NSMutableArray *stops = [NSMutableArray arrayWithCapacity:[routeStops count]];
	for (ShuttleRouteStop *routeStop in routeStops) {
		ShuttleStop *stop = [[[ShuttleStop alloc] initWithRouteStop:routeStop] autorelease];
		[stops addObject:stop];
	}
	
	return stops;
}

+ (ShuttleRoute *)shuttleRouteWithID:(NSString *)routeID
{
	return [[ShuttleDataManager sharedDataManager] shuttleRouteWithID:routeID];
}

- (ShuttleRoute *)shuttleRouteWithID:(NSString *)routeID
{
	return [_shuttleRoutesByID objectForKey:routeID];
}

+ (ShuttleRouteCache *)routeCacheWithID:(NSString *)routeID
{
	return [[ShuttleDataManager sharedDataManager] routeCacheWithID:routeID];
}

- (ShuttleRouteCache *)routeCacheWithID:(NSString *)routeID
{
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"routeID LIKE %@", routeID];
	NSArray *routeCaches = [CoreDataManager objectsForEntity:ShuttleRouteEntityName matchingPredicate:pred];
	ShuttleRouteCache *routeCache = nil;
	if ([routeCaches count] == 0) {
		NSManagedObject *newRoute = [CoreDataManager insertNewObjectForEntityForName:ShuttleRouteEntityName];
		[newRoute setValue:routeID forKey:@"routeID"];
		routeCache = (ShuttleRouteCache *)newRoute;
	} else {
		routeCache = [routeCaches lastObject];
	}
	return routeCache;
}

+ (ShuttleStop *)stopWithRoute:(NSString *)routeID stopID:(NSString *)stopID error:(NSError **)error
{
	return [[ShuttleDataManager sharedDataManager] stopWithRoute:routeID stopID:stopID error:error];
}

- (ShuttleStop *)stopWithRoute:(NSString *)routeID stopID:(NSString *)stopID error:(NSError **)error
{
	ShuttleStop *stop = nil;
	ShuttleRoute *route = [_shuttleRoutesByID objectForKey:routeID];
	if (route != nil) {
        for (ShuttleStop *aStop in route.stops) {
            if ([aStop.stopID isEqualToString:stopID]) {
                stop = aStop;
                break;
            }
        }
        
        if (stop == nil) {
            //NSLog(@"attempting to create new ShuttleStop for stop %@ on route %@", stopID, routeID);
            ShuttleStopLocation *stopLocation = [self stopLocationWithID:stopID];
            stop = [[[ShuttleStop alloc] initWithStopLocation:stopLocation routeID:routeID] autorelease];
        }
        
	} else {
		if (error != NULL) {
        NSString *message = [NSString stringWithFormat:@"route %@ does not exist", routeID];
        *error = [NSError errorWithDomain:ShuttlesErrorDomain
                                     code:errShuttleRouteNotAvailable
                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, @"message", nil]];
    }
		return nil;
    }
	
	return stop;
}

+ (ShuttleStopLocation *)stopLocationWithID:(NSString *)stopID
{
	return [[ShuttleDataManager sharedDataManager] stopLocationWithID:stopID];
}

- (ShuttleStopLocation *)stopLocationWithID:(NSString *)stopID
{
	if (_stopLocations == nil) {
		// populate stop cache in memory
		
		_stopLocations = [[NSMutableArray alloc] init];
		_stopLocationsByID = [[NSMutableDictionary alloc] init];
		NSPredicate *matchAll = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
		NSArray *stopLocations = [CoreDataManager objectsForEntity:ShuttleStopEntityName matchingPredicate:matchAll];
		
		for (ShuttleStopLocation *stopLocation in stopLocations) {
			NSString *stopID = [stopLocation stopID];
			[_stopLocations addObject:stopLocation];
			[_stopLocationsByID setObject:stopLocation forKey:stopID];
		}
	}
	
	ShuttleStopLocation *stopLocation = [_stopLocationsByID objectForKey:stopID];
	if (stopLocation == nil) {
		NSManagedObject *newStopLocation = [CoreDataManager insertNewObjectForEntityForName:ShuttleStopEntityName];
		[newStopLocation setValue:stopID forKey:@"stopID"];
		stopLocation = (ShuttleStopLocation *)newStopLocation;	
		[_stopLocations addObject:stopLocation];
		[_stopLocationsByID setObject:stopLocation forKey:stopID];
	}
	return stopLocation;
}

#pragma mark - API requests

- (void)requestInfo
{
    if (_infoRequest) {
        return;
    }
    _infoRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    _infoRequest.useKurogoApi = YES;
    [_infoRequest requestObject:nil pathExtension:@"transit/info"];
}

- (void)requestRoutes
{
    if (_routesRequest) {
        return;
    }
    _routesRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    _routesRequest.useKurogoApi = YES;
    [_routesRequest requestObject:nil pathExtension:@"transit/routes"];
}

- (void)requestRoute:(NSString *)routeID
{
    if (_routeRequest) {
        [_routeRequest abortRequest]; // assume UI only wants to show full route info for one route at a time
    }
    _routeRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    _routeRequest.useKurogoApi = YES;
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:routeID, @"id", nil];
    [_routeRequest requestObject:params pathExtension:@"transit/route"];
}

- (void)requestStop:(NSString *)stopID
{
    if (_stopRequest) {
        [_stopRequest abortRequest]; // assume UI only wants to show full stop info for one stop at a time
    }
    _stopRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    _stopRequest.useKurogoApi = YES;
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:stopID, @"id", nil];
    [_stopRequest requestObject:params pathExtension:@"transit/stop"];
}

- (void)requestAnnouncements
{
    if (_announcementsRequest) {
        return;
    }
    _announcementsRequest = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    _announcementsRequest.useKurogoApi = YES;
    [_announcementsRequest requestObject:nil pathExtension:@"transit/announcements"];
}

#pragma mark Delegate Message distribution

-(void) sendRoutesToDelegates:(NSArray*)routes
{
	for (id<ShuttleDataManagerDelegate> delegate in _registeredDelegates)
	{
		if ([delegate respondsToSelector:@selector(routesReceived:)]) {
			[delegate routesReceived:routes];
		}
	}
}

-(void) sendStopToDelegates:(NSArray*)shuttleStopSchedules forStopID:(NSString*)stopID
{
	for (id<ShuttleDataManagerDelegate> delegate in _registeredDelegates)
	{
		if ([delegate respondsToSelector:@selector(stopInfoReceived:forStopID:)]) {
			[delegate stopInfoReceived:shuttleStopSchedules forStopID:stopID];
		}
	}
}

-(void) sendRouteToDelegates:(ShuttleRoute *)route forRouteID:(NSString*)routeID
{	
	for (id<ShuttleDataManagerDelegate> delegate in _registeredDelegates)
	{
		if ([delegate respondsToSelector:@selector(routeInfoReceived:forRouteID:)]) {
			[delegate routeInfoReceived:route forRouteID:routeID];
		}
	}
}

#pragma mark Delegate registration
-(void) registerDelegate:(id<ShuttleDataManagerDelegate>)delegate
{
	if (nil == _registeredDelegates) {
		_registeredDelegates = [[NSMutableSet alloc] initWithCapacity:1];
	}
    [_registeredDelegates addObject:delegate];
}

-(void) unregisterDelegate:(id<ShuttleDataManagerDelegate>)delegate
{
	[_registeredDelegates removeObject:delegate];

	if ([[CoreDataManager managedObjectContext] hasChanges]) {
		[CoreDataManager saveData];
	}
}


#pragma mark JSONAPIDelegate

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)result
{
    id response = nil;
    if ([result isKindOfClass:[NSDictionary class]]) {
        response = [result objectForKey:@"response"];
    }
    
    if (response) {
        if (request == _infoRequest) {
            NSArray *agencies = [response objectForKey:@"agencies"];
            NSDictionary *sections = [response objectForKey:@"sections"];
            
            _infoRequest = nil;
        }
        else if (request == _routesRequest) {
            
            BOOL routesChanged = NO;

            if ([response isKindOfClass:[NSArray class]]) {
                NSMutableArray *routeIDs = [[NSMutableArray alloc] initWithCapacity:[response count]];
                NSInteger sortOrder = 0;
                for (NSDictionary *routeInfo in response) {
                    NSString *routeID = [routeInfo objectForKey:@"id"];
                    [routeIDs addObject:routeID];

                    ShuttleRoute *route = [_shuttleRoutesByID objectForKey:routeID];
                    if (!route) {
                        route = [[[ShuttleRoute alloc] initWithDictionary:routeInfo] autorelease];
                        [_shuttleRoutes addObject:route];
                        [_shuttleRoutesByID setValue:route forKey:routeID];
                        routesChanged = YES;
                    }
                    [route updateInfo:routeInfo];
                    if (route.sortOrder != sortOrder) {
                        route.sortOrder = sortOrder;
                        routesChanged = YES;
                    }
                    sortOrder++;
                }
                
                // prune routes that don't exist anymore
                NSPredicate *missing = [NSPredicate predicateWithFormat:@"NOT (routeID IN %@)", routeIDs];
                NSArray *missingRoutes = [_shuttleRoutes filteredArrayUsingPredicate:missing];
                
                for (ShuttleRoute *route in missingRoutes) {
                    NSString *routeID = route.routeID;
                    [CoreDataManager deleteObject:route.cache];
                    [_shuttleRoutesByID removeObjectForKey:routeID];
                    [_shuttleRoutes removeObject:route];
                    route = nil;
                    routesChanged = YES;
                }
                
                if (routesChanged) {
                    [CoreDataManager saveData];
                }
                
                [routeIDs release];
                
                [self sendRoutesToDelegates:_shuttleRoutes];
            }

            _routesRequest = nil;
        }
        else if (request == _routeRequest) {
            if ([response isKindOfClass:[NSDictionary class]]) {
                NSString *routeID = [response objectForKey:@"id"];
                ShuttleRoute *route = [_shuttleRoutesByID objectForKey:routeID];
                if (!route) {
                    route = [[[ShuttleRoute alloc] initWithDictionary:response] autorelease];
                } else {
                    [route updateInfo:response];
                }
                
                _requestRouteErrorCount = 0;
                [self sendRouteToDelegates:route forRouteID:routeID];
            }
            
            _routeRequest = nil;
        }
        else if (request == _stopRequest) {
            NSMutableArray *schedules = [NSMutableArray array];
            
            NSString *stopID = [response objectForKey:@"id"];
            NSArray *routesDicts = [response objectForKey:@"routes"];
            for (NSDictionary *routeDict in routesDicts) {
                NSString *routeID = [routeDict objectForKey:@"routeId"];
                NSString *title = [routeDict objectForKey:@"title"];
                NSNumber *running = [routeDict objectForKey:@"running"]; // bool
                NSArray *arrives = [routeDict objectForKey:@"arrives"];

                NSError *error = nil;
                ShuttleStop *stop = [ShuttleDataManager stopWithRoute:routeID stopID:stopID error:&error];
                if (error) {
                    NSLog(@"error getting shuttle stop. code: %d; userinfo: %@", error.code, error.userInfo);
                }
                
                if (stop) {
                    [stop updateStaticInfo:response];
                    [stop updateArrivalTimes:arrives];
                    [schedules addObject:stop];
                }
            }
            [self sendStopToDelegates:schedules forStopID:stopID];

            _stopRequest = nil;
        }
        else if (request == _announcementsRequest) {
            NSMutableDictionary *results = [NSMutableDictionary dictionary];
            NSUInteger urgentCount = 0;
            for (NSDictionary *agency in response) {
                NSString *agencyID = [agency objectForKey:@"agency"];
                NSArray *announcements = [agency objectForKey:@"announcements"];
                for (NSDictionary *announcement in announcements) {
                    BOOL urgent = [[announcement objectForKey:@"urgent"] boolValue];
                    if (urgent) {
                        urgentCount++;
                    } else {
                        NSTimeInterval announceDate = [[announcement objectForKey:@"timestamp"] doubleValue];
                        if ([[NSDate date] timeIntervalSince1970] - announceDate < 86400) {
                            urgentCount++;
                        }
                    }
                }
                [results setObject:announcements forKey:agencyID];
            }

            for (id<ShuttleDataManagerDelegate> aDelegate in _registeredDelegates) {
                if ([aDelegate respondsToSelector:@selector(announcementsReceived:urgentCount:)]) {
                    [aDelegate announcementsReceived:results urgentCount:urgentCount];
                }
            }
            
            _announcementsRequest = nil;
        }
    }
}


- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error
{
	if (request == _routesRequest) {
		[self sendRoutesToDelegates:nil];
        _routesRequest = nil;
	}
	else if (request == _stopRequest) {
		[self sendStopToDelegates:nil forStopID:[request.params valueForKey:@"id"]];
        _stopRequest = nil;
	}
	else if (request == _routeRequest) {
		if (++_requestRouteErrorCount > MAX_CONSECUTIVE_ERROR_COUNT) {
			// This command is called really frequently so only generate an error
			// when there are a large number of consecutive errors
			_requestRouteErrorCount = 0;
			[self sendRouteToDelegates:nil forRouteID:[request.params valueForKey:@"id"]];
		} else {
			DLog(@"Got connection error #%d, ignoring", _requestRouteErrorCount);
		}
        _routeRequest = nil;
	}
    else if (request == _announcementsRequest) {
        _announcementsRequest = nil;
    }
    else if (request == _infoRequest) {
        _infoRequest = nil;
    }
}


- (UIImage *)imageForURL:(NSString *)urlString
{
    if (!_markerImages) {
        _markerImages = [[NSMutableDictionary alloc] init];
    }
    
    NSString *hash = [NSString stringWithFormat:@"shuttle-marker-%d", [urlString hash]];

    static NSString *imageDirectory = nil;
    if (!imageDirectory) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        if (basePath) {
            imageDirectory = [[basePath stringByAppendingPathComponent:@"images"] retain];
        }
    }
    
    NSString *imageFile = [imageDirectory stringByAppendingPathComponent:hash];
    UIImage *image = [UIImage imageWithContentsOfFile:imageFile];

    if (!image) {
        image = [_markerImages objectForKey:hash];
    }
    
    if (!image) {
        NSURL *url = [NSURL URLWithString:urlString];
        NSData *data = [NSData dataWithContentsOfURL:url];
        image = [[[UIImage alloc] initWithData:data] autorelease];
        if (image) {
            [_markerImages setObject:image forKey:hash];
        }
    }

    return image;
}


@end
