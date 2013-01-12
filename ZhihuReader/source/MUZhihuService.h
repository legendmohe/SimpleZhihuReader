//
//  MUZhihuService.h
//  ZhihuReader
//
//  Created by 何 新宇 on 13-1-9.
//  Copyright (c) 2013年 doublesix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZhihuEntities.h"

#define kZhihuReaderURLPrefix @"http://www.zhihu.com/reader/json/"

typedef void(^MUZhihuJsonResponseHandler)(id jsonObject, NSURL *aURL, NSError* error);
typedef void(^MUZhihuResponseProgressHandler)(NSUInteger expectedContentLength, NSUInteger currentLength);
typedef void(^MUZhihuResponseCancelHandler)();

@interface MUZhihuService : NSObject<NSURLConnectionDelegate>{
    NSMutableData* _responseData;
	NSURLConnection* _connection;
    NSURL* _url;
    
    MUZhihuJsonResponseHandler _handlerBlock;
    MUZhihuResponseProgressHandler _progressBlock;
    MUZhihuResponseCancelHandler _cancelBlock;
    NSUInteger _expectedContentLength;
    
    NSError* _error;
}

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

+ (MUZhihuService*) shareService;

#pragma mark - connection
- (void) requestForResponseStringWithZhihuURL:(NSURL*) aURL withBlock:(MUZhihuJsonResponseHandler) handlerBlock progressBlock:(MUZhihuResponseProgressHandler) progressBlock cancelBlock:(MUZhihuResponseCancelHandler) cancelBlock;
- (id) jsonObjectForResponseData:(NSData*) responseData;
- (void) cancelDownloadingData;
- (NSData*)responseData;
- (NSError*)error;

#pragma mark - coredata

- (NSArray*) saveJSONObjectToCoreDataAndRetriveAnswers:(id) JSONObject;
- (Question*) questionOfQID:(NSNumber*) qid;
- (Answer*) answerOfAID:(NSNumber*) aid;
- (User*) userOfUID:(NSString*) uid;
- (Topic*) topicOfTID:(NSNumber*) tid;

@end
