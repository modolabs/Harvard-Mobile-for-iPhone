#import <Foundation/Foundation.h>

@interface SocialPost : NSObject {

}

@property (nonatomic, retain) NSString *uid;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *icon;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *authorURL;
@property (nonatomic, retain) NSDate *date;

@end
