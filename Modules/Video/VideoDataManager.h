#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"

typedef void (^VideosHandler)(NSArray *videos);


@interface VideoDataManager : NSObject <JSONAPIDelegate> {
    
}

+ (VideoDataManager *)sharedManager;

- (void)requestVideosWithHandler:(VideosHandler)handler;
- (void)searchWithQuery:(NSString *)query withHandler:(VideosHandler)handler;

@end
