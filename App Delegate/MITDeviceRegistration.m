
#import "MITDeviceRegistration.h"

@implementation MITIdentity
@synthesize deviceID, passKey;

- (id) initWithDeviceId: (NSString *)aDeviceId passKey: (NSString *)aPassKey {
    if (!aDeviceId || !aPassKey) {
        [self release];
        return nil;
    }
    
    self = [super init];
	if (self) {
		deviceID = [aDeviceId retain];
		passKey = [aPassKey retain];
	}
	return self;
}

- (NSMutableDictionary *) mutableDictionary {
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
	[mutableDictionary setObject:deviceID forKey:MITDeviceIdKey];
	[mutableDictionary setObject:passKey forKey:MITPassCodeKey];
	[mutableDictionary setObject:@"ios" forKey:@"platform"];
	return mutableDictionary;
}

- (void) dealloc {
	[deviceID release];
	[passKey release];
	[super dealloc];
}

@end

@implementation MITDeviceRegistration

+ (NSString *) stringFromToken: (NSData *)deviceToken {
	NSString *hex = [deviceToken description]; // of the form "<21d34 2323a 12324>"
	// eliminate the "<" and ">" and " "
	hex = [hex stringByReplacingOccurrencesOfString:@"<" withString:@""];
	hex = [hex stringByReplacingOccurrencesOfString:@">" withString:@""];
	hex = [hex stringByReplacingOccurrencesOfString:@" " withString:@""];
	return hex;
}
	
+ (void) registerNewDeviceWithToken: (NSData *)deviceToken {
	NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:@"ios" forKey:@"platform"];
	if(deviceToken) {
		[parameters setObject:[self stringFromToken:deviceToken] forKey:@"device_token"];
	}
    JSONAPIRequest *request = [JSONAPIRequest requestWithJSONAPIDelegate:[MITIdentityLoadedDelegate withDeviceToken:deviceToken]];
    request.useKurogoApi = YES;
    [request requestObject:parameters pathExtension:@"push/register"];
}

+ (void) newDeviceToken: (NSData *)deviceToken {
	NSMutableDictionary *parameters = [[self identity] mutableDictionary];
	[parameters setObject:@"ios" forKey:@"platform"];
	[parameters setObject:[self stringFromToken:deviceToken] forKey:@"device_token"];
	
    JSONAPIRequest *request = [JSONAPIRequest requestWithJSONAPIDelegate:[MITIdentityLoadedDelegate withDeviceToken:deviceToken]];
    request.useKurogoApi = YES;
    [request requestObject:parameters pathExtension:@"push/register"];
}
	
+ (MITIdentity *) identity {
	NSString *deviceId = [[[NSUserDefaults standardUserDefaults] objectForKey:MITDeviceIdKey] description];
	NSString *passKey = [[[NSUserDefaults standardUserDefaults] objectForKey:MITPassCodeKey] description];

	if(deviceId) {
		return [[[MITIdentity alloc] initWithDeviceId:deviceId passKey:passKey] autorelease];
	} else {
		return nil;
	}
}
@end


@implementation MITIdentityLoadedDelegate
@synthesize deviceToken;

+ (MITIdentityLoadedDelegate *) withDeviceToken: (NSData *)deviceToken {
	MITIdentityLoadedDelegate *delegate = [[self new] autorelease];
	delegate.deviceToken = deviceToken;
	return delegate;
}
		
- (void) dealloc {
	[deviceToken release];
	[super dealloc];
}

- (void)request:(JSONAPIRequest *)request jsonLoaded: (id)JSONObject {
	
	[[NSUserDefaults standardUserDefaults] setObject:self.deviceToken forKey:DeviceTokenKey];

	if ([JSONObject isKindOfClass:[NSDictionary class]]) {
        id result = [JSONObject objectForKey:@"response"];
        if ([result isKindOfClass:[NSDictionary class]]) {
            NSDictionary *jsonDict = result;
            [[NSUserDefaults standardUserDefaults] setObject:[jsonDict objectForKey:MITDeviceIdKey] forKey:MITDeviceIdKey];
            [[NSUserDefaults standardUserDefaults] setObject:[jsonDict objectForKey:MITPassCodeKey] forKey:MITPassCodeKey];
        }
	}
}

@end
