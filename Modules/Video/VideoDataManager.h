#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "Video.h"

typedef void (^VideosHandler)(NSArray *videos);


@interface VideoDataManager : NSObject <JSONAPIDelegate> {
    
}

+ (VideoDataManager *)sharedManager;

- (void)requestVideosWithHandler:(VideosHandler)handler;
- (void)searchWithQuery:(NSString *)query withHandler:(VideosHandler)handler;
- (void)bookmarkVideo:(Video *)video bookmarked:(BOOL)bookmarked;
- (NSArray *)bookmarkedVideos;
- (BOOL)bookmarksExist;

@end
