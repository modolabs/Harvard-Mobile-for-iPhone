#import <Foundation/Foundation.h>
#import "MITModule.h"
#import "VideoDataManager.h"

@interface VideoModule : MITModule <VideosReceivedDelegate> {
    UIViewController *mainViewController;
    
}

@end
