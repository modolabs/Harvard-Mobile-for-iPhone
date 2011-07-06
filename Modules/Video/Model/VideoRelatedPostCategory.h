#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VideoRelatedPost;

@interface VideoRelatedPostCategory : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) VideoRelatedPost * relatedPost;

@end
