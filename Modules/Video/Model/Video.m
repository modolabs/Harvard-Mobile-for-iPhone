#import "Video.h"
#import "VideoRelatedPost.h"


@implementation Video
@dynamic bookmarked;
@dynamic largeImageURL;
@dynamic thumbnailURL;
@dynamic published;
@dynamic summary;
@dynamic title;
@dynamic duration;
@dynamic mediaSource;
@dynamic videoID;
@dynamic relatedPosts;

- (void)addRelatedPostsObject:(VideoRelatedPost *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"relatedPosts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"relatedPosts"] addObject:value];
    [self didChangeValueForKey:@"relatedPosts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeRelatedPostsObject:(VideoRelatedPost *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"relatedPosts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"relatedPosts"] removeObject:value];
    [self didChangeValueForKey:@"relatedPosts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addRelatedPosts:(NSSet *)value {    
    [self willChangeValueForKey:@"relatedPosts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"relatedPosts"] unionSet:value];
    [self didChangeValueForKey:@"relatedPosts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeRelatedPosts:(NSSet *)value {
    [self willChangeValueForKey:@"relatedPosts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"relatedPosts"] minusSet:value];
    [self didChangeValueForKey:@"relatedPosts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

- (NSString *)durationString {
    NSInteger minutes = [self.duration intValue] / 60;
    NSInteger seconds = [self.duration intValue] % 60;
    return [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
}

- (NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM F, yyyy"];
    NSString *date = [dateFormatter stringFromDate:self.published];
    [dateFormatter release];
    return date;
}

- (NSString *)uploadedString {
    return [NSString stringWithFormat:@"Uploaded %@", [self dateString]];
    
}

- (CGFloat)aspectRatio {
    // for now we assume all videos have the same aspect ratio
    return 320.0f / 180.0f;
}

@end
