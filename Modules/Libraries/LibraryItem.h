#import <CoreData/CoreData.h>


@interface LibraryItem :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * publisher;
@property (nonatomic, retain) NSString * itemId;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * nonLatinTitle;
@property (nonatomic, retain) NSString * workType;
@property (nonatomic, retain) NSString * fullImageLink;
@property (nonatomic, retain) NSString * formatDetail;
@property (nonatomic, retain) NSString * onlineLink;
@property (nonatomic, retain) NSString * callNumber;
@property (nonatomic, retain) NSNumber * isBookmarked;
@property (nonatomic, retain) NSString * typeDetail;
@property (nonatomic, retain) NSString * edition;
@property (nonatomic, retain) NSString * year;
@property (nonatomic, retain) NSString * details;
@property (nonatomic, retain) NSNumber * numberOfImages;
@property (nonatomic, retain) NSString * catalogLink;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * figureLink;
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSString * nonLatinAuthor;
@property (nonatomic, retain) NSString * authorLink;
@property (nonatomic, retain) NSData * thumbnailImage;

- (void)requestImage;

@end



