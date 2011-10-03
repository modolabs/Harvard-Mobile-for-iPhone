#import "SocialPost.h"

@implementation SocialPost

@synthesize uid, type, typeId, icon, message, messagePlainText, author, authorURL, date;

- (void)setValue:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:@"uid"]) {
        self.uid = value;
    } else if ([key isEqualToString:@"type"]) {
        self.type = value;
    } else if ([key isEqualToString:@"typeId"]) {
        self.typeId = value;
    } else if ([key isEqualToString:@"icon"]) {
        self.icon = value;
    } else if ([key isEqualToString:@"message"]) {
        self.message = value;
    } else if ([key isEqualToString:@"messagePlainText"]) {
        self.messagePlainText = value;
    } else if ([key isEqualToString:@"author"]) {
        self.author = value;
    } else if ([key isEqualToString:@"authorURL"]) {
        self.authorURL = value;
    } else if ([key isEqualToString:@"date"]) {
        self.date = value;
    }
}

- (id)valueForKey:(NSString *)key
{
    if ([key isEqualToString:@"uid"]) {
        return self.uid;
    }
    if ([key isEqualToString:@"type"]) {
        return self.type;
    }
    if ([key isEqualToString:@"typeId"]) {
        return self.typeId;
    }
    if ([key isEqualToString:@"icon"]) {
        return self.icon;
    }
    if ([key isEqualToString:@"message"]) {
        return self.message;
    }
    if ([key isEqualToString:@"messagePlainText"]) {
        return self.messagePlainText;
    }
    if ([key isEqualToString:@"author"]) {
        return self.author;
    }
    if ([key isEqualToString:@"authorURL"]) {
        return self.authorURL;
    }
    if ([key isEqualToString:@"date"]) {
        return self.date;
    }
    return nil;
}

@end