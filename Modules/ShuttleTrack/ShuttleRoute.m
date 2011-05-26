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
@synthesize tag = _tag;
@synthesize gpsActive = _gpsActive;
@synthesize isRunning = _isRunning;
@synthesize liveStatusFailed = _liveStatusFailed;
@synthesize vehicleLocations = _vehicleLocations;
@synthesize cache = _cache;
@synthesize agency;
@synthesize color;
@synthesize genericUrlForMarker;
@synthesize urlForStopMarker;
@synthesize nextStopId;
@synthesize genericShuttleMarker;
@synthesize stops = _stops;

// cached properties
@dynamic routeDescription;
@dynamic title;
@dynamic summary;
@dynamic interval;
//@dynamic stops;
@dynamic routeID;
@dynamic sortOrder;
@dynamic path;
//@dynamic agency;

@dynamic fullSummary;


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
	self.title = [routeInfo objectForKey:@"title"];
	self.routeDescription = [routeInfo objectForKey:@"description"];
	self.summary = [routeInfo objectForKey:@"summary"];
	self.interval = [[routeInfo objectForKey:@"interval"] intValue];
	self.agency = [routeInfo objectForKey:@"agency"];
	self.color = [routeInfo objectForKey:@"color"];
	self.genericUrlForMarker = [routeInfo objectForKey:@"genericIconUrl"];
	self.urlForStopMarker = [routeInfo objectForKey:@"stopMarkerUrl"];
	
	if (nil != self.genericUrlForMarker) {
		if (nil == self.genericShuttleMarker) {
			
			NSURL *url = [NSURL URLWithString:self.genericUrlForMarker];
			NSData *data = [NSData dataWithContentsOfURL:url];
			self.genericShuttleMarker = [[UIImage alloc] initWithData:data];
			//self.genericUrlForMarker = [[[UIImageView alloc] initWithImage:marker] autorelease];
		}
	}
	
	self.tag = [routeInfo objectForKey:@"tag"];
	self.gpsActive = [[routeInfo objectForKey:@"gpsActive"] boolValue];
	self.isRunning = [[routeInfo objectForKey:@"isRunning"] boolValue];
    
    NSDate *now = [NSDate date];
    NSNumber *nowSeconds = [routeInfo objectForKey:@"now"];
    if (nowSeconds && [nowSeconds isKindOfClass:[NSNumber class]]) {
        now = [NSDate dateWithTimeIntervalSince1970:[nowSeconds doubleValue]];
    }
    
    NSArray *array = [routeInfo objectForKey:@"path"];
	if (array) {
		self.path = array;
    }

	array = [routeInfo objectForKey:@"stops"];
    if (array) {
        self.stops = [NSMutableArray array];
        [_stopAnnotations release];
        _stopAnnotations = [[NSMutableArray alloc] initWithCapacity:array.count];

        NSError *error = nil;
        for (NSDictionary *aDict in array) {
            NSString *stopID = [aDict objectForKey:@"id"];
            if (stopID) {
                ShuttleStop *aStop = [ShuttleDataManager stopWithRoute:self.routeID stopID:stopID error:&error];
                if (aStop) {
                    [aStop updateInfo:aDict referenceDate:now];
                    [self.stops addObject:aStop];
                    ShuttleStopMapAnnotation* annotation = [[[ShuttleStopMapAnnotation alloc] initWithShuttleStop:aStop] autorelease];
                    [_stopAnnotations addObject:annotation];
                }
                if ([aDict objectForKey:@"upcoming"]) {
                    self.nextStopId = [aDict objectForKey:stopID];
                }
            }
        }
        
        if (!_pathLocations.count) {
            [self updatePath];
        }
	}
	
    if ((array = [routeInfo objectForKey:@"vehicleLocations"]) != nil) {
		
		NSMutableArray* formattedVehicleLocations = [NSMutableArray arrayWithCapacity:array.count];
		for (NSDictionary* dictionary in array) {
			ShuttleLocation* shuttleLocation = [[[ShuttleLocation alloc] initWithDictionary:dictionary] autorelease];
			[formattedVehicleLocations addObject:shuttleLocation];
		}
		self.vehicleLocations = formattedVehicleLocations;
	}
}

- (void)getStopsFromCache
{
	[_stops release];
	_stops = nil;
	
	[_stopAnnotations release];
	_stopAnnotations = nil;
	
	NSSet *cachedStops = self.cache.stops;
	_stops = [[NSMutableArray alloc] initWithCapacity:[cachedStops count]];
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
		//NSLog(@"initialized stop %@ while initializing route %@", [shuttleStop description], self.routeID);
		[_stops addObject:shuttleStop];

		ShuttleStopMapAnnotation* annotation = [[[ShuttleStopMapAnnotation alloc] initWithShuttleStop:shuttleStop] autorelease];
		[_stopAnnotations addObject:annotation];
	}
		
	if (_pathLocations == nil) {
		[self updatePath];
	}
}

- (void)updatePath
{
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

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self != nil) {
		self.routeID = [dict objectForKey:@"route_id"];
		_vehicleLocations = nil;
		_pathLocations = nil;
		_stopAnnotations = nil;
		_liveStatusFailed = NO;
		
		[self updateInfo:dict];
		[self getStopsFromCache];
    }
    return self;
}

- (id)initWithCache:(ShuttleRouteCache *)cachedRoute
{
    if (self != nil) {
		self.cache = cachedRoute;
		_liveStatusFailed = NO;
		_stops = nil;
    }
    return self;
}

-(void) dealloc
{
	self.tag = nil;
	self.cache = nil;
	
	[_stops release];
    self.vehicleLocations = nil;
	//[_vehicleLocations release];	
	[_pathLocations release];
	[_stopAnnotations release];
	
	[super dealloc];
}

- (NSString *)fullSummary 
{
	/*NSString* summaryString = [NSString stringWithFormat:@"Route loop repeats every %d minutes.", self.interval]; //self.interval];
	if (nil != self.summary) {
		summaryString = [NSString stringWithFormat:@"%@ %@", self.summary, summaryString];
	}*/
	
	NSString* summaryString;   // = [NSString stringWithFormat:@"Route loop repeats every %d minutes.", self.interval]; //self.interval];
	NSString* desciptionString = [NSString stringWithFormat:@""];
	
	if (nil != self.routeDescription) {
		if ([self.routeDescription length] > 0)
			desciptionString = [NSString stringWithFormat:@"%@\n", self.routeDescription]; //self.interval];
	}
	if (nil != self.summary) {
		summaryString = [desciptionString stringByAppendingFormat:@"%@", [self summary]]; //[NSString stringWithFormat:@"%@", [self.summary];//, summaryString];
	}
	else {
		summaryString = [desciptionString stringByAppendingFormat:@""];
	}
	
    return [NSString stringWithFormat:@"%@\n%@", [self trackingStatus], summaryString];
}

- (NSString *)trackingStatus
{
	NSString *summaryString = nil;
	
	if (_liveStatusFailed) {
		return @"Real time tracking failed to load.";
	}
	
	ShuttleStop *aStop = [self.stops lastObject];
	if (aStop.nextScheduledDate) { // we have something from the server
		if (self.vehicleLocations && self.vehicleLocations.count > 0) {
			summaryString = [NSString stringWithString:@"Real time bus tracking online."];
		} else if (self.isRunning) {
			summaryString = [NSString stringWithString:@"Tracking offline."];
		} else {
			summaryString = [NSString stringWithString:@"Bus not running."];
		}
	} else {
		summaryString = [NSString stringWithString:@"Loading..."];
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
	return _pathLocations;
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
