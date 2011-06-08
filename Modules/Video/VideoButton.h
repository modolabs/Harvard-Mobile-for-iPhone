#import <UIKit/UIKit.h>
#import "MITThumbnailView.h"

@interface VideoButton : UIControl {
    MITThumbnailView *_thumbnailSubview;
    BOOL _selected;
}

@property (nonatomic, retain) id userData;

- (void)setImageURL:(NSString *)url;


@end
