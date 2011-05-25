#import "ShuttleModule.h"
//#import "ShuttleRoutes.h"
#import "ShuttleRouteViewController.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttlesMainViewController.h"

@implementation ShuttleModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = ShuttleTag;
        self.shortName = @"Shuttles";
        self.longName = @"ShuttleTracker";
        self.iconName = @"shuttle";
        self.pushNotificationSupported = YES;
		
		ShuttlesMainViewController *theVC = [[[ShuttlesMainViewController alloc] init] autorelease];
        self.viewControllers = [NSArray arrayWithObject:theVC];
    }
    return self;
}

- (void) didAppear {
	// for now mark all shuttle notifications as read as soon as the module appears to the user
	//[MITUnreadNotifications removeNotifications:[MITUnreadNotifications unreadNotificationsForModuleTag:self.tag]];
}

- (BOOL) handleLocalPath:(NSString *)localPath query:(NSString *)query {
	if (localPath.length==0) {
		return YES;
	}
	
	NSArray *components = [localPath componentsSeparatedByString:@"/"];
	NSString *pathRoot = [components objectAtIndex:0];
	[self popToRootViewController];
	UIViewController *rootViewController = [self rootViewController];
	 
	if ([pathRoot isEqualToString:@"route-list"] || [pathRoot isEqualToString:@"route-map"]) {
		NSString *routeID = [components objectAtIndex:1];
		ShuttleRoute *route = [ShuttleDataManager shuttleRouteWithID:routeID];
		if(route) {
			ShuttleRouteViewController *routeViewController = [[[ShuttleRouteViewController alloc] initWithNibName:@"ShuttleRouteViewController" bundle:nil] autorelease];
			routeViewController.route = route;
			[rootViewController.navigationController pushViewController:routeViewController animated:NO];
			
			ShuttleStop *stop = nil;
			ShuttleStopMapAnnotation *annotation = nil;
			if (components.count > 2) {
				NSString *stopID = [components objectAtIndex:2];
                NSError *error = nil;
				stop = [ShuttleDataManager stopWithRoute:routeID stopID:stopID error:&error];
				
				// need to force routeViewController to load to initialize the route annotations
				routeViewController.view;
				for (ShuttleStopMapAnnotation *anAnnotation in [routeViewController.route annotations]) {
					if ([anAnnotation.shuttleStop.stopID isEqualToString:stopID]) {
						annotation = anAnnotation;
					}
				}
			}
			
			if ([pathRoot isEqualToString:@"route-list"]) {
				if (stop) {
					[routeViewController pushStopViewControllerWithStop:stop annotation:annotation animated:NO];
				}
			}
			
			// for route map case
			if([pathRoot isEqualToString:@"route-map"]) {
				[routeViewController setMapViewMode:YES animated:NO];
				if (stop) {
					// show a specific stop
					[routeViewController showStop:annotation animated:NO];
				}
				
				if (components.count > 3 && 
					[@"stops" isEqualToString:[components objectAtIndex:3]]) {
						[routeViewController pushStopViewControllerWithStop:stop annotation:annotation animated:NO];
				}
			}
		}
	}
	return YES;
}
	
@end
