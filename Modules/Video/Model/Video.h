#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Video : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * largeImageURL;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * mediaSource;
@property (nonatomic, retain) NSString * videoID;
@property (nonatomic, retain) NSDate * published;
@property (nonatomic, retain) NSNumber * duration;

@end
