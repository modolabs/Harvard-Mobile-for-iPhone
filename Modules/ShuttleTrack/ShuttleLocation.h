
#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface ShuttleLocation : NSObject <MKAnnotation>{

	int _secsSinceReport;
	int _heading;
    CGFloat _speed;
    UIImage *_image;

	CLLocationCoordinate2D _coordinate;
}

@property (nonatomic) NSInteger secsSinceReport;
@property (nonatomic) NSInteger heading;
@property (nonatomic) CGFloat speed;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) NSString *vehicleId;
@property (nonatomic, retain) UIImage *image;

- (id)initWithDictionary:(NSDictionary*)dictionary;

@end
