#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface UIColor (MITAdditions)

+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end

@interface UIImageView (MITAdditions)

+ (UIImageView *)accessoryViewWithMITType:(MITAccessoryViewType)type;

@end

@interface UIImage (KGOAdditions)

+ (UIImage *)blankImageOfSize:(CGSize)size;

@end

