#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VideoRelatedPost;

@interface Video : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber *bookmarked;
@property (nonatomic, retain) NSString * largeImageURL;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSDate * published;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * mediaSource;
@property (nonatomic, retain) NSString * videoID;
@property (nonatomic, retain) NSSet* relatedPosts;

- (NSString *)durationString;
- (NSString *)dateString;
- (NSString *)uploadedString;
- (CGFloat)aspectRatio;

@end
