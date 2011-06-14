#import "Video.h"


@implementation Video
@dynamic thumbnailURL;
@dynamic largeImageURL;
@dynamic summary;
@dynamic title;
@dynamic mediaSource;
@dynamic videoID;
@dynamic published;
@dynamic duration;

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

@end
