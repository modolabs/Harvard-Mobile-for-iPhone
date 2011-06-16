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

- (void)searchWithQuery:(NSString *)query withHandler:(VideosHandler)handler {
    JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = [handler copy];
    api.useKurogoApi = YES;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    [params setObject:@"0" forKey:@"section"];
    [params setObject:query forKey:@"q"];
    [api requestObject:params pathExtension:@"video/search"];    
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject {
    
    if (![request.params objectForKey:@"q"]) {
        // we purge old videos after requesting the featured videos
        // (do not purge for "video/search" request just purge "video/videos" request
        [self purgeOldVideos];
    }
    
    NSDictionary *responseDict = JSONObject;
    NSArray *videoDicts = [responseDict objectForKey:@"response"];
    NSMutableArray *videos = [NSMutableArray arrayWithCapacity:[videoDicts count]];
    for(NSDictionary *videoDict in videoDicts) {
        Video *video = [[CoreDataManager coreDataManager] insertNewObjectForEntityForName:VideoEntityName];
        video.mediaSource = [videoDict objectForKey:@"mediaSource"];
        
        if ([video.mediaSource length] == 0) {
            // default to brightCove
            video.mediaSource = @"Brightcove";
        }
        
        if ([video.mediaSource isEqualToString:@"Brightcove"]) {
            video.videoID = [videoDict objectForKey:@"brightCoveId"];
        } else if ([video.mediaSource isEqualToString:@"Youtube"]) {
            video.videoID = [videoDict objectForKey:@"youtubeId"];
        }
        
        video.title = [videoDict objectForKey:@"title"];
        video.summary = [videoDict objectForKey:@"description"];
        video.largeImageURL = [videoDict objectForKey:@"stillImage"];
        video.thumbnailURL = [videoDict objectForKey:@"image"];
        video.published = [NSDate dateWithTimeIntervalSince1970:[[videoDict objectForKey:@"publishedTimestamp"] intValue]];
        video.duration = [videoDict objectForKey:@"duration"];
        [videos addObject:video];
                        
    }
    [CoreDataManager saveData];
                           
    VideosHandler handler = request.userData;
    handler(videos);
    [handler release];
    request.userData = nil;                                                     
}
@end
