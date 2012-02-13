#import "ShuttleLocation.h"
#import "ShuttleDataManager.h"

@implementation ShuttleLocation
@synthesize coordinate = _coordinate;
@synthesize secsSinceReport = _secsSinceReport;
@synthesize heading = _heading;
@synthesize speed = _speed;
@synthesize vehicleId = _vehicleId;
@synthesize image = _image;

static NSMutableDictionary *s_markerImages = nil;

- (id)initWithDictionary:(NSDictionary*)dictionary
{
	if (self = [super init])
	{
        _vehicleId = [[dictionary objectForKey:@"id"] integerValue];
        
        NSDictionary *coords = [dictionary objectForKey:@"coords"];
        if ([coords isKindOfClass:[NSDictionary class]]) {
            _coordinate.latitude = [[coords objectForKey:@"lat"] doubleValue];
            _coordinate.longitude = [[coords objectForKey:@"lon"] doubleValue];
        }
        
        id lastSeen = [dictionary objectForKey:@"lastSeen"];
        if ([lastSeen respondsToSelector:@selector(integerValue)]) {
            NSTimeInterval lastSeenTime = [lastSeen integerValue];
            self.secsSinceReport = (int)[[NSDate date] timeIntervalSince1970] - lastSeenTime;
        }
        
		self.heading = [[dictionary objectForKey:@"heading"] intValue];
        self.speed = [[dictionary objectForKey:@"speed"] floatValue];
        
        NSString *iconURL = [dictionary objectForKey:@"iconURL"];
        if ([iconURL isKindOfClass:[NSString class]]) {
            self.image = [[ShuttleDataManager sharedDataManager] imageForURL:iconURL];
        }
	}
	
	return self;
}

// Title and subtitle for use by selection UI.
- (NSString *)title
{
	return nil;
}

- (NSString *)subtitle
{
	return nil;
}

- (void)dealloc
{
    self.image = nil;
    [super dealloc];
}

@end
