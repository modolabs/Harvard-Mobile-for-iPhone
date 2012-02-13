#import "ShuttleRoute.h"
#import "ShuttleStop.h" 
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopLocation.h"
#import "ShuttleLocation.h"
#import "ShuttleRouteStop.h"
#import "ShuttleDataManager.h"
#import "CoreDataManager.h"

@implementation ShuttleRoute

// live properties
@synthesize liveStatusFailed = _liveStatusFailed, gpsActive = _gpsActive, isRunning = _isRunning,
vehicleLocations = _vehicleLocations, nextStopId = _nextStopId;

// drawing properties
@synthesize agency = _agency, color = _color, stopMarkerURL, genericMarkerURL, genericMarkerImage;

// ShuttleRouteCache
@dynamic routeDescription;
@dynamic title;
@dynamic summary;
@dynamic interval;
@dynamic routeID;
@dynamic sortOrder;
@dynamic path;

// other core data
@synthesize cache = _cache, stops = _stops;

#pragma mark Getters and setters

- (NSString *)title {
	return self.cache.title;
}

- (void)setTitle:(NSString *)title {
	if (title != nil && self.cache != nil)
		self.cache.title = title;
}

- (NSString *)routeDescription {
	return self.cache.routeDescription;
}

- (void)setRouteDescription:(NSString *)description {
	if (description != nil && self.cache != nil)
		self.cache.routeDescription = description;
}

- (NSString *)summary {
	return self.cache.summary;
}

- (void)setSummary:(NSString *)summary {
	if (summary != nil && self.cache != nil)
		self.cache.summary = summary;
}

- (NSString *)routeID {
	return self.cache.routeID;
}

- (void)setRouteID:(NSString *)routeID {
	if (routeID != nil) {
		if (self.cache == nil) {
			self.cache = [ShuttleDataManager routeCacheWithID:routeID];
		}
	} else {
		self.cache.routeID = routeID;
	}
}

- (NSInteger)interval {
	return [self.cache.interval intValue];
}

- (void)setInterval:(NSInteger)interval {
	if (self.cache != nil)
		self.cache.interval = [NSNumber numberWithInt:interval];
}

- (NSInteger)sortOrder {
    return [self.cache.sortOrder intValue];
}

- (void)setSortOrder:(NSInteger)order {
    self.cache.sortOrder = [NSNumber numberWithInt:order];
}

- (NSArray *)path
{
	NSData *pathData = self.cache.path;
	return [NSKeyedUnarchiver unarchiveObjectWithData:pathData];
}

- (void)setPath:(NSArray *)path
{
	NSData *pathData = [NSKeyedArchiver archivedDataWithRootObject:path];
	self.cache.path = pathData;
}

#pragma mark -

- (void)updateInfo:(NSDictionary *)routeInfo
{
    // these are included in routes api
	self.agency = [routeInfo objectForKey:@"agency"];
	self.title = [routeInfo objectForKey:@"title"];
	self.summary = [routeInfo objectForKey:@"summary"];
	self.routeDescription = [routeInfo objectForKey:@"description"];
	self.color = [routeInfo objectForKey:@"color"];
	self.isRunning = [[routeInfo objectForKey:@"running"] boolValue];
	self.gpsActive = [[routeInfo objectForKey:@"live"] boolValue];
	self.interval = [[routeInfo objectForKey:@"frequency"] intValue];

    // these come in the route api
    self.genericMarkerURL = [routeInfo objectForKey:@"vehicleIconURL"];
	self.stopMarkerURL = [routeInfo objectForKey:@"stopIconURL"];

    if (self.genericMarkerImage && !self.genericMarkerURL) {
        self.genericMarkerImage = [[ShuttleDataManager sharedDataManager] imageForURL:self.genericMarkerURL];
    }
    
	NSArray *stops = [routeInfo objectForKey:@"stops"];
    if (stops) {
        for (NSDictionary *aDict in stops) {
            NSString *stopID = [aDict objectForKey:@"id"];
            if (stopID) {
                ShuttleStop *aStop = [_stopsById objectForKey:stopID];
                if (!aStop) {
                    NSError *error = nil;
                    aStop = [ShuttleDataManager stopWithRoute:self.routeID stopID:stopID error:&error];
                    [_stopsById setObject:aStop forKey:stopID];
                    [self.stops addObject:aStop];
                    ShuttleStopMapAnnotation* annotation = [[[ShuttleStopMapAnnotation alloc] initWithShuttleStop:aStop] autorelease];
                    if(!_stopAnnotations) {
                        _stopAnnotations = [[NSMutableArray alloc] init];
                    }
                    [_stopAnnotations addObject:annotation];
                }

                aStop.upcoming = NO;
                [aStop updateStaticInfo:aDict];
                NSArray *arrives = [aDict objectForKey:@"arrives"];
                if (arrives) {
                    [aStop updateArrivalTimes:arrives];
                }
            }
        }
        // TODO: figure out which stop is next and set stop ID here
        //self.nextStopId = 
    }
    
    NSArray *segments = [routeInfo objectForKey:@"paths"];
	if ([segments isKindOfClass:[NSArray class]]) {
        NSMutableArray *paths = [NSMutableArray array];
        for (id segment in segments) {
            if ([segment isKindOfClass:[NSArray class]]) {
                NSMutableArray *aPath = [NSMutableArray array];
                for (id coord in (NSArray *)segment) {
                    if ([coord isKindOfClass:[NSDictionary class]]) {
                        id lat = [coord objectForKey:@"lat"];
                        id lon = [coord objectForKey:@"lon"];
                        if ([lat respondsToSelector:@selector(doubleValue)] && [lon respondsToSelector:@selector(doubleValue)]) {
                            CLLocation *location = [[[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lon doubleValue]] autorelease];
                            [aPath addObject:location];
                        }
                    }
                }
                [paths addObject:aPath];
            }
        }
        
        //self.pathLocations = paths;
        self.path = paths;
    }

    NSArray *vehicles = [routeInfo objectForKey:@"vehicles"];
    if (vehicles) {
		NSMutableArray* formattedVehicleLocations = [NSMutableArray arrayWithCapacity:vehicles.count];
		for (NSDictionary* dictionary in vehicles) {
            NSString *nextStop = [dictionary objectForKey:@"nextStop"];
            if (nextStop) {
                ShuttleStop *stop = [_stopsById objectForKey:nextStop];
                if (stop) {
                    stop.upcoming = YES;
                }
            }
            
			ShuttleLocation* shuttleLocation = [[[ShuttleLocation alloc] initWithDictionary:dictionary] autorelease];
			[formattedVehicleLocations addObject:shuttleLocation];
		}
		self.vehicleLocations = formattedVehicleLocations;
    }
}

- (void)getStopsFromCache
{
	[_stopAnnotations release];
	_stopAnnotations = nil;
	
	NSSet *cachedStops = self.cache.stops;
    NSUInteger count = cachedStops.count;
    self.stops = [[[NSMutableArray alloc] initWithCapacity:count] autorelease];
    _stopsById = [[NSMutableDictionary alloc] initWithCapacity:count];
	_stopAnnotations = [[NSMutableArray alloc] initWithCapacity:[cachedStops count]];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
	NSArray *sortedStops = [[cachedStops allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];		
	[sortDescriptor release];
	
	for (ShuttleRouteStop *routeStop in sortedStops) {
        NSError *error;
		ShuttleStop *shuttleStop = [ShuttleDataManager stopWithRoute:self.routeID stopID:[routeStop stopID] error:&error]; // should always be nil
		if (shuttleStop == nil) {
			shuttleStop = [[[ShuttleStop alloc] initWithRouteStop:routeStop] autorelease];
		}
		[self.stops addObject:shuttleStop];
        [_stopsById setObject:shuttleStop forKey:shuttleStop.stopID];

		ShuttleStopMapAnnotation* annotation = [[[ShuttleStopMapAnnotation alloc] initWithShuttleStop:shuttleStop] autorelease];
		[_stopAnnotations addObject:annotation];
	}
	/*	
	if (_pathLocations == nil) {
		[self updatePath];
	}
    */
}
/*
- (void)updatePath
{
    self.pathLocations = nil;
	if (_pathLocations != nil) {
		[_pathLocations removeAllObjects];
		_pathLocations = nil;
	}
	
	_pathLocations = [[NSMutableArray alloc] init];

    for (NSDictionary* pathComponent in self.path) {
        CLLocation* location = [[[CLLocation alloc] initWithLatitude:[[pathComponent objectForKey:@"lat"] doubleValue]
                                                           longitude:[[pathComponent objectForKey:@"lon"] doubleValue]
                                 ] autorelease];
			
        [_pathLocations addObject:location];
    }
}
*/
- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self != nil) {
		self.routeID = [dict objectForKey:@"id"];
		_vehicleLocations = nil;
		_pathLocations = nil;
		_stopAnnotations = nil;
		
		[self updateInfo:dict];
		[self getStopsFromCache];
    }
    return self;
}

- (id)initWithCache:(ShuttleRouteCache *)cachedRoute
{
    if (self != nil) {
		self.cache = cachedRoute;
		_stops = nil;
    }
    return self;
}

-(void) dealloc
{
	self.cache = nil;
	
	[_stops release];
    self.vehicleLocations = nil;
	[_pathLocations release];
	[_stopAnnotations release];
	
	[super dealloc];
}

- (NSString *)fullSummary 
{
    NSMutableArray *parts = [NSMutableArray array];
    if (self.routeDescription.length) {
        [parts addObject:self.routeDescription];
    }
    if (self.summary.length) {
        [parts addObject:self.summary];
    }
    return [parts componentsJoinedByString:@"\n"];
}

- (NSString *)trackingStatus
{
    NSString *summaryString = nil;
    if (self.liveStatusFailed) {
        summaryString = @"Real time tracking failed to load.";
    } else if (!self.isRunning) {
        summaryString = @"Bus not running.";
    } else if (!self.gpsActive) {
        summaryString = @"Tracking offline.";
    } else {
        summaryString = @"Real time bus tracking online.";
    }
	return summaryString;
}

#pragma mark -
#pragma mark Useful Overrides

- (NSString *)description {
    return self.title;
}

// override -isEqual: and -hash so that any ShuttleRoute objects with the same self.tag will be considered the same. Useful for finding objects in collections like -[NSArray indexOfObject:].
- (BOOL)isEqual:(id)anObject {
    ShuttleRoute *otherRoute = nil;
    if (anObject && [anObject isKindOfClass:[ShuttleRoute class]]) {
        otherRoute = (ShuttleRoute *)anObject;
    }
    //return (otherRoute && [self.tag isEqual:otherRoute.tag]);

	// backend was changed so that there is no difference between nextbus route tags and our internal route id
	// if we change that for some reason, the API should pick one or the other system and present
	// a single consistent set of route identifiers.
	return (otherRoute && [self.routeID	isEqual:otherRoute.routeID]);
}

- (NSUInteger)hash {
    //return [self.tag hash];
	return [self.routeID hash];
}

- (NSComparisonResult)compare:(ShuttleRoute *)aRoute {
    return [self.title compare:aRoute.title];
}

#pragma mark MITMapRoute

// array of CLLocations making up the path of this route
-(NSArray*) pathLocations
{
	//return _pathLocations;
    return self.path;
}

// array of MKAnnotations that are to be included with this route
-(NSArray*) annotations
{
	return _stopAnnotations;
}

// color of the route line to be rendered
-(UIColor*) lineColor
{
	return [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.75];
}

// width of the route line to be rendered
-(CGFloat) lineWidth
{
	return 3.0;
}

@end
