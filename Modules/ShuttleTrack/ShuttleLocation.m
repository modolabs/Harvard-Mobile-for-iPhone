#import "ShuttleLocation.h"
#import "ShuttleDataManager.h"

@implementation ShuttleLocation
@synthesize coordinate = _coordinate;
@synthesize secsSinceReport = _secsSinceReport;
@synthesize heading = _heading;
@synthesize speed = _speed;
@synthesize vehicleId = _vehicleId;
@synthesize image = _image;

- (id)initWithDictionary:(NSDictionary*)dictionary
{
	if (self = [super init])
	{
        id vehicleId = [dictionary objectForKey:@"id"];
        if (![vehicleId isKindOfClass:[NSString class]]) {
            self.vehicleId = [vehicleId description];
        } else {
            self.vehicleId = (NSString *)vehicleId;
        }
        
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
    self.vehicleId = nil;
    [super dealloc];
}

@end
