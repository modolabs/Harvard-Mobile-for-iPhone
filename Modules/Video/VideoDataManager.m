#import "Video.h"
#import "VideoRelatedPost.h"
#import "VideoRelatedPostCategory.h"
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bookmarked == %d", NO];
    NSArray *oldVideos = [CoreDataManager objectsForEntity:VideoEntityName matchingPredicate:predicate];
    [CoreDataManager deleteObjects:oldVideos];
}

- (void)requestVideosWithDelegate:(id<VideosReceivedDelegate>)delegate {
    JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = delegate;
    api.useKurogoApi = YES;
    NSDictionary *params = [NSDictionary dictionaryWithObject:@"0" forKey:@"section"];
    [api requestObject:params pathExtension:@"video/videos"];    
}

- (void)searchWithQuery:(NSString *)query withDelegate:(id<VideosReceivedDelegate>)delegate {
    JSONAPIRequest *api = [JSONAPIRequest requestWithJSONAPIDelegate:self];
    api.userData = delegate;
    api.useKurogoApi = YES;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    [params setObject:@"0" forKey:@"section"];
    [params setObject:query forKey:@"q"];
    [api requestObject:params pathExtension:@"video/search"];    
}

- (void)request:(JSONAPIRequest *)request jsonLoaded:(id)JSONObject {
    
    VideoRequestType requestType;
    if (![request.params objectForKey:@"q"]) {
        // we purge old videos after requesting the featured videos
        // (do not purge for "video/search" request just purge "video/videos" request
        [self purgeOldVideos];
        requestType = VideoRequestTypeFeatured;
    } else {
        requestType = VideoRequestTypeSearch;
    }
    
    NSDictionary *responseDict = JSONObject;
    NSArray *videoDicts = [responseDict objectForKey:@"response"];
    NSMutableArray *videos = [NSMutableArray arrayWithCapacity:[videoDicts count]];
    for(NSDictionary *videoDict in videoDicts) {
        NSString *mediaSource = [videoDict objectForKey:@"mediaSource"];
        if ([mediaSource length] == 0) {
            // default to brightCove
            mediaSource = @"Brightcove";
        }        
        NSString *videoID;
        if ([mediaSource isEqualToString:@"Brightcove"]) {
            videoID = [videoDict objectForKey:@"brightCoveId"];
        } else if ([mediaSource isEqualToString:@"Youtube"]) {
            videoID = [videoDict objectForKey:@"youtubeId"];
        }
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mediaSource == %@ AND videoID == %@", mediaSource, videoID];
        NSArray *videoArray = [CoreDataManager objectsForEntity:VideoEntityName matchingPredicate:predicate];
        Video *video = [videoArray lastObject];
        if(!video) {
            video = [[CoreDataManager coreDataManager] insertNewObjectForEntityForName:VideoEntityName];
            video.mediaSource = mediaSource;
            video.videoID = videoID;
        }
        
        video.title = [videoDict objectForKey:@"title"];
        video.summary = [videoDict objectForKey:@"description"];
        video.largeImageURL = [videoDict objectForKey:@"stillImage"];
        video.thumbnailURL = [videoDict objectForKey:@"image"];
        video.published = [NSDate dateWithTimeIntervalSince1970:[[videoDict objectForKey:@"publishedTimestamp"] intValue]];
        video.duration = [videoDict objectForKey:@"duration"];
        
        NSArray *relatedPostDicts = [videoDict objectForKey:@"relatedPosts"];
        NSMutableSet *posts = [NSMutableSet set];
        for (NSInteger index=0; index < relatedPostDicts.count; index++) {
            NSDictionary *relatedPostDict = [relatedPostDicts objectAtIndex:index];
            VideoRelatedPost *post = [[CoreDataManager coreDataManager] insertNewObjectForEntityForName:VideoRelatedPostEntityName];
            post.sortOrder = [NSNumber numberWithInteger:index];
            post.guid = [relatedPostDict objectForKey:@"guid"];
            post.title = [relatedPostDict objectForKey:@"title"];
            NSString *wpidString = [relatedPostDict objectForKey:@"wpid"];
            post.wpid = [NSNumber numberWithInteger:[wpidString integerValue]];
            [relatedPostDict objectForKey:@"wpid"];
            
            NSMutableSet *categories = [NSMutableSet set];
            for(NSString *categoryTitle in [relatedPostDict objectForKey:@"category"]) {
                VideoRelatedPostCategory *category = [[CoreDataManager coreDataManager] insertNewObjectForEntityForName:VideoRelatedPostCategoryEntityName];
                category.title = categoryTitle;
                [categories addObject:category];
            }
            post.categories = categories;
            
            [posts addObject:post];
        }
        video.relatedPosts = posts;        
        [videos addObject:video];
                        
    }
    [CoreDataManager saveData];
                           
    id<VideosReceivedDelegate>delegate = request.userData;
    [delegate videosReceived:videos forRequestType:requestType];
    request.userData = nil;                                                     
}

- (void)request:(JSONAPIRequest *)request handleConnectionError:(NSError *)error {
    id<VideosReceivedDelegate>delegate = request.userData;
    VideoRequestType requestType = ([request.params objectForKey:@"q"] == nil) ? VideoRequestTypeFeatured : VideoRequestTypeSearch;
    [delegate errorLoadingVideosForRequestType:requestType];
    request.userData = nil;
}

- (BOOL)request:(JSONAPIRequest *)request shouldDisplayAlertForError:(NSError *)error {
    return YES;
}

- (void)bookmarkVideo:(Video *)video bookmarked:(BOOL)bookmarked {
    video.bookmarked = [NSNumber numberWithBool:bookmarked];
    [CoreDataManager saveData];
}

- (BOOL)bookmarksExist {
    NSManagedObjectContext *context = [CoreDataManager managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setPredicate:[NSPredicate predicateWithFormat:@"bookmarked == %d", YES]];
    [request setEntity:[NSEntityDescription entityForName:VideoEntityName
                                   inManagedObjectContext:context]];
    [request setIncludesSubentities:NO];
    NSError *error = nil;
    NSInteger count = [context countForFetchRequest:request error:&error];
    [request release];
    return (count > 0);
}

- (NSArray *)bookmarkedVideos {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bookmarked == %d", YES];
    return [CoreDataManager objectsForEntity:VideoEntityName matchingPredicate:predicate];    
}

@end
