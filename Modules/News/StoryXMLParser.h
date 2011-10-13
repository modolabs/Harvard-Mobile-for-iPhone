#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"

@class StoryXMLParser;
@class NewsImage;
@class NewsImageRep;

@protocol StoryXMLParserDelegate <NSObject>

- (void)parserDidFinishParsing:(StoryXMLParser *)parser;

@optional
- (void)parserDidStartDownloading:(StoryXMLParser *)parser;
- (void)parserDidStartParsing:(StoryXMLParser *)parser;
- (void)parserDidMakeConnection:(StoryXMLParser *)parser;
- (void)parser:(StoryXMLParser *)parser didMakeProgress:(CGFloat)percentDone;
- (void)parser:(StoryXMLParser *)parser didFailWithDownloadError:(NSError *)error;
- (void)parser:(StoryXMLParser *)parser didFailWithParseError:(NSError *)error;
- (void)parser:(StoryXMLParser *)parser downloadMadeProgress:(CGFloat)progress;
@end

@interface StoryXMLParser : NSObject <ConnectionWrapperDelegate, NSXMLParserDelegate> {
    id <StoryXMLParserDelegate> delegate;
    
	NSThread *thread;
	
    ConnectionWrapper *connection;
    
	NSXMLParser *xmlParser;
	
    NSInteger expectedStoryCount;
    
    BOOL parsingTopStories;
    
	NSString *currentElement;
    NSMutableArray *currentStack;
    NSMutableSet *currentCategories;
    NSMutableDictionary *currentContents;
    NSMutableDictionary *currentImage;
	BOOL done;
    BOOL parseSuccessful;
    BOOL shouldAbort;
	BOOL isSearch;
	BOOL loadingMore;
    NSInteger searchIndex;
	NSInteger totalAvailableResults;
    
    NSMutableArray *downloadedStories;
    
	NSAutoreleasePool *downloadAndParsePool;
}

@property (nonatomic, assign) id <StoryXMLParserDelegate> delegate;
@property (nonatomic, retain) ConnectionWrapper *connection;
@property (nonatomic, retain) NSXMLParser *xmlParser;
@property (nonatomic, assign) BOOL parsingTopStories;
@property (nonatomic, assign) BOOL isSearch;
@property (nonatomic, assign) BOOL loadingMore;
@property (nonatomic, assign) NSInteger totalAvailableResults;
@property (nonatomic, retain) NSString *currentElement;
@property (nonatomic, retain) NSMutableArray *currentStack;
@property (nonatomic, retain) NSMutableDictionary *currentContents;
@property (nonatomic, retain) NSMutableDictionary *currentImage;
@property (nonatomic, retain) NSMutableArray *downloadedStories;
@property (nonatomic, assign) NSAutoreleasePool *downloadAndParsePool;
@property (nonatomic, assign) NSInteger searchIndex;

// called by main thread
- (void)loadStoriesForCategory:(NSInteger)category afterStoryId:(NSInteger)storyId count:(NSInteger)count;
- (void)loadStoriesforQuery:(NSString *)query afterStoryId:(NSInteger)storyId searchIndex:(NSInteger)index count:(NSInteger)count;
- (void)abort;

@end
