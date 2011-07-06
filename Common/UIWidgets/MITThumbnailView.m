#import "MITThumbnailView.h"
#import "MIT_MobileAppDelegate.h"

@interface MITThumbnailView (Private)

- (void)initHelper;

@end

@implementation MITThumbnailView

@synthesize imageURL, connection, loadingView, imageView, delegate;

- (void)initHelper {
    connection = nil;
    imageURL = nil;
    _imageData = nil;
    loadingView = nil;
    imageView = nil;
    self.opaque = YES;
    self.clipsToBounds = YES;
    self.contentMode = UIViewContentModeScaleAspectFill;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self initHelper];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self initHelper];
    }
    return self;
}

- (NSData *)imageData
{
    return _imageData;
}

- (void)setImageData:(NSData *)imageData
{
    if (![_imageData isEqualToData:imageData]) {
        [_imageData release];
        _imageData = [imageData retain];
        _didDisplayImage = NO;
    }
}

- (void)loadImage {
    // show cached image if available
    if (self.imageData) {
        [self displayImage];
    }
    // otherwise try to fetch the image from
    else {
        [self requestImage];
    }
}

- (BOOL)displayImage {
    if (_didDisplayImage) {
        return _didDisplayImage;
    }
    
    [loadingView stopAnimating];
    loadingView.hidden = YES;
    
    UIImage *image = [[UIImage alloc] initWithData:self.imageData];
    
    // don't show imageView if imageData isn't actually a valid image
    if (image && image.size.width > 0 && image.size.height > 0) {
        if (!imageView) {
            imageView = [[UIImageView alloc] initWithImage:nil]; // image is set below
            [self addSubview:imageView];
            imageView.frame = self.bounds;
            imageView.contentMode = self.contentMode;
            imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        }
        
        imageView.image = image;
        imageView.hidden = NO;
        _didDisplayImage = YES;
        [imageView setNeedsLayout];
    }
    [self setNeedsLayout];
    
    [image release];
    return _didDisplayImage;
}

- (void)requestImage {
    // TODO: don't attempt to load anything if there's no net connection
    
    if ([self.connection isConnected]) {
        return;
    }
    
    if (!self.connection) {
        self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    }
    if ([self.connection requestDataFromURL:[NSURL URLWithString:self.imageURL] allowCachedResponse:YES]) {    
        [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
    }
    
    self.imageData = nil;
    
    if (!self.loadingView) {
        loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self addSubview:self.loadingView];
        loadingView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        loadingView.backgroundColor = self.backgroundColor;
    }
    imageView.hidden = YES;
    loadingView.hidden = NO;
    [loadingView startAnimating];
}

- (void)setPlaceholderImage:(UIImage *)image {
    self.backgroundColor = [UIColor colorWithPatternImage:image];
}
     
// ConnectionWrapper delegate
- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    // TODO: If memory usage becomes a concern, convert images to PNG using UIImagePNGRepresentation(). PNGs use considerably less RAM.
    self.imageData = data;
    BOOL validImage = [self displayImage];
    if (validImage) {
        [self.delegate thumbnail:self didLoadData:data];
    }
    
    self.connection = nil;
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    self.imageData = nil;
    [self displayImage]; // will fail to load the image, displays placeholder thumbnail instead
    self.connection = nil;
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
}

- (BOOL)connection:(ConnectionWrapper *)wrapper shouldDisplayAlertForError:(NSError *)error {
    return NO;
}

- (void)dealloc {
	[connection cancel];
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    [connection release];
    connection = nil;

    self.imageData = nil;
    [loadingView release];
    [imageView release];
    [imageURL release];
    self.delegate = nil;
    [super dealloc];
}

@end

