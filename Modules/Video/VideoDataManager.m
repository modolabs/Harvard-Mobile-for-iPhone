#import "Video.h"
#import "VideoDataManager.h"
#import "CoreDataManager.h"
#import "Constants.h"

@implementation VideoDataManager

+ (VideoDataManager *)sharedManager {
    static VideoDataManager *s_sharedManager;
    if (s_sharedManager == nil) {
        s_sharedManager = [[VideoDataManager alloc] init];
    }
    return s_sharedManager;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)purgeOldVideos {
    NSArray *oldVideos = [CoreDataManager objectsForEntity:VideoEntityName matchingPredicate:nil];
    [CoreDataManager deleteObjects:oldVideos];
}

- (void)requestVideosWithHandler:(VideosHandler)handler {
    JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = [handler copy];
    api.useKurogoApi = YES;
    NSDictionary *params = [NSDictionary dictionaryWithObject:@"0" forKey:@"section"];    
    [api requestObject:params pathExtension:@"video/videos"];    
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject {
    [self purgeOldVideos];
    
    NSDictionary *responseDict = JSONObject;
    NSArray *videoDicts = [responseDict objectForKey:@"response"];
    NSMutableArray *videos = [NSMutableArray arrayWithCapacity:[videoDicts count]];
    for(NSDictionary *videoDict in videoDicts) {
        Video *video = [[CoreDataManager coreDataManager] insertNewObjectForEntityForName:VideoEntityName];
        video.mediaSource = [videoDict objectForKey:@"mediaSource"];
        
        if ([video.mediaSource isEqualToString:@"BrightCove"]) {
            video.videoID = [videoDict objectForKey:@"brightCoveId"];
        } else if ([video.mediaSource isEqualToString:@"Youtube"]) {
            video.videoID = [videoDict objectForKey:@"youtubeId"];
        }
        
        video.title = [videoDict objectForKey:@"title"];
        video.summary = [videoDict objectForKey:@"description"];
        video.largeImageURL = [videoDict objectForKey:@"stillImage"];
        video.thumbnailURL = [videoDict objectForKey:@"image"];
        video.published = [NSDate dateWithTimeIntervalSince1970:[[videoDict objectForKey:@"publishedTimestamp"] intValue]];
        [videos addObject:video];
                        
    }
    [CoreDataManager saveData];
                           
    VideosHandler handler = request.userData;
    handler(videos);
    [handler release];
    request.userData = nil;                                                     
}
@end
