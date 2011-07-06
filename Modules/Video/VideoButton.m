#import "VideoButton.h"
#import "MITThumbnailView.h"
#import <QuartzCore/QuartzCore.h>

#define PADDING 5

@interface VideoButton (Private)
- (void)updateBackground;
@end

@implementation VideoButton
@synthesize userData;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _thumbnailSubview = [[MITThumbnailView alloc] 
                             initWithFrame:CGRectMake(
                                                      PADDING, PADDING,
                                                      frame.size.width-2*PADDING, frame.size.height-2*PADDING)];
        _thumbnailSubview.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _thumbnailSubview.userInteractionEnabled = NO;
        [self addSubview:_thumbnailSubview];
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.borderWidth = 0.5;
        
        [self updateBackground];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setSelected:(BOOL)selected {
    if(selected != _selected) {
        _selected = selected;
        [self updateBackground];       
    }
    
}

- (void)updateBackground {
    NSString *imageName = _selected ? 
        @"video/video_button_selected.png" : @"video/video_button_unselected.png";
    UIImage *backgroundImage = [UIImage imageNamed:imageName];
    self.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
}

- (void)setImageURL:(NSString *)url {
    _thumbnailSubview.imageURL = url;
    [_thumbnailSubview loadImage];
}

- (void)dealloc
{
    [_thumbnailSubview release];
    self.userData = nil;
    [super dealloc];
}

@end
