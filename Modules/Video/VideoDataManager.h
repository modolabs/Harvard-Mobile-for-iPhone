#import <UIKit/UIKit.h>
#import "JSONAPIRequest.h"
#import "Video.h"

typedef enum {
    VideoRequestTypeFeatured,
    VideoRequestTypeSearch
} VideoRequestType;

@protocol VideosReceivedDelegate <NSObject>

- (void)videosReceived:(NSArray *)videos forRequestType:(VideoRequestType)requestType;
- (void)errorLoadingVideosForRequestType:(VideoRequestType)requestType;

@end

@interface VideoDataManager : NSObject <JSONAPIDelegate> {
    
}

+ (VideoDataManager *)sharedManager;

- (void)requestVideosWithDelegate:(id<VideosReceivedDelegate>)delegate;
- (void)searchWithQuery:(NSString *)query withDelegate:(id<VideosReceivedDelegate>)delegate;
- (void)bookmarkVideo:(Video *)video bookmarked:(BOOL)bookmarked;
- (NSArray *)bookmarkedVideos;
- (BOOL)bookmarksExist;

@end
