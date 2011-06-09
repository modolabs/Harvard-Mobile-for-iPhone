#import <Foundation/Foundation.h>
#import "Video.h"
#import "MITThumbnailView.h"

#define VIDEO_CELL_THUMBNAIL_TAG 1
#define VIDEO_CELL_TITLE_TAG 2
#define VIDEO_CELL_SUBTITLE_TAG 3

void populateCell(UITableViewCell *cell, Video *video) {
    
    MITThumbnailView *thumbnailView = (MITThumbnailView *)[cell viewWithTag:VIDEO_CELL_THUMBNAIL_TAG];
    thumbnailView.imageURL = video.thumbnailURL;
    [thumbnailView loadImage];
    
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:VIDEO_CELL_TITLE_TAG];
    titleLabel.text = video.title;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM F, yyyy"];
    NSString *date = [dateFormatter stringFromDate:video.published];
    [dateFormatter release];
    
    NSInteger minutes = [video.duration intValue] / 60;
    NSInteger seconds = [video.duration intValue] % 60;
    NSString *durationString = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
    
    UILabel *subtileLabel = (UILabel *)[cell viewWithTag:VIDEO_CELL_SUBTITLE_TAG];
    subtileLabel.text = [NSString stringWithFormat:@"%@ | Uploaded %@", durationString, date];
    
}

