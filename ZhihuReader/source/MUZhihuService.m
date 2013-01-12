//
//  MUZhihuService.m
//  ZhihuReader
//
//  Created by 何 新宇 on 13-1-9.
//  Copyright (c) 2013年 doublesix. All rights reserved.
//

#import "MUZhihuService.h"

@implementation MUZhihuService

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (MUZhihuService*) shareService
{
    static MUZhihuService *service = nil;
	if (service == nil)
	{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            service = [[MUZhihuService alloc] init];
        });
	}
	
	return service;
}

#pragma mark - connections

- (void) requestForResponseStringWithZhihuURL:(NSURL*) aURL withBlock:(MUZhihuJsonResponseHandler) handlerBlock progressBlock:(MUZhihuResponseProgressHandler) progressBlock cancelBlock:(MUZhihuResponseCancelHandler)cancelBlock
{
    _url = [aURL copy];
    _handlerBlock = [handlerBlock copy];
    _progressBlock = [progressBlock copy];
    _cancelBlock = [cancelBlock copy];
    NSMutableURLRequest*  request = [NSMutableURLRequest requestWithURL:aURL];
    [request addValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    _responseData = [[NSMutableData alloc] init];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}
- (void) cancelDownloadingData
{
    [_connection cancel];
    
    if (_cancelBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _cancelBlock();
            [self _cleanup];
        });
    }
}
- (void) _cleanup
{
    _handlerBlock = nil;
    _progressBlock = nil;
    _cancelBlock = nil;
    _url = nil;
    _connection = nil;
    _responseData = nil;
}

- (id) jsonObjectForResponseData:(NSData*) responseData
{
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        NSLog(@"ERROR:[%@],%@", [error domain], [error userInfo]);
        return nil;
    }
    return jsonObject;
}

#pragma mark - connectionDelegate

- (NSData*)responseData {
	return _responseData;
}
- (NSError*)error {
	return _error;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _expectedContentLength = response.expectedContentLength;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if(connection != _connection) return;
	[_responseData appendData:data];
    if (_progressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _progressBlock(_expectedContentLength, [_responseData length]);
        });
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if(connection != _connection) return;
    
    NSLog(@"download:%dKB", [_responseData length]/1000);
    
    if (_handlerBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _handlerBlock([self jsonObjectForResponseData:_responseData], _url, nil);
            [self _cleanup];
        });
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if(connection != _connection) return;
    _error = [error copy];
    
    if (_handlerBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _handlerBlock(nil, _url, nil);
            [self _cleanup];
        });
    }
}

#pragma mark - coredata

- (NSArray*) saveJSONObjectToCoreDataAndRetriveAnswers:(id) JSONObject
{
    if (![JSONObject isKindOfClass:[NSArray class]]) {
        NSLog(@"invaild JSONObject");
        return nil;
    }
    //------parser begin------
    NSMutableArray* questionArray = [NSMutableArray arrayWithCapacity:10];
    for (NSArray* answerItem in JSONObject) {
        NSUInteger delta = 0;
        
        //insert objects to context
        NSNumber* aid = [answerItem objectAtIndex:delta++];
        Answer* anAnswer = [self answerOfAID:aid];
        if (!anAnswer) {
            anAnswer = [NSEntityDescription insertNewObjectForEntityForName:@"Answer" inManagedObjectContext:[self managedObjectContext]];
            anAnswer.aid = aid;
        }
        
        if (![[answerItem objectAtIndex:delta] isKindOfClass:[NSNull class]]) {
            anAnswer.experience = [answerItem objectAtIndex:delta];
        }
        delta++;
        anAnswer.content = [answerItem objectAtIndex:delta++];
        anAnswer.voteCount = [answerItem objectAtIndex:delta++];
        anAnswer.created = [answerItem objectAtIndex:delta++];
        anAnswer.aToken = [answerItem objectAtIndex:delta++];
        
        User* aUser = nil;
        //anonymous user
        if ([[answerItem objectAtIndex:6] isKindOfClass:[NSNumber class]]) {
            delta++;
            aUser = [self userOfUID:@"########"];
            if (!aUser) {
                aUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:[self managedObjectContext]];
                aUser.screenname = @"Unknown";
                aUser.username = @"Unknown";
                aUser.uid = @"########";
            }
        }else {
            NSArray* userInfo = [answerItem objectAtIndex:delta++];
            NSString* uid = [userInfo objectAtIndex:3];
            aUser = [self userOfUID:uid];
            if (!aUser) {
                aUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:[self managedObjectContext]];
                aUser.uid = uid;
            }
            aUser.screenname = [userInfo objectAtIndex:0];
            aUser.username = [userInfo objectAtIndex:1];
            aUser.picURL = [userInfo objectAtIndex:2];
        }
        anAnswer.author = aUser;
        
        NSArray* questionInfo = [answerItem objectAtIndex:delta++];
        NSNumber* qid = [questionInfo objectAtIndex:0];
        Question* aQuestion = [self questionOfQID:qid];
        if (!aQuestion) {
            aQuestion = [NSEntityDescription insertNewObjectForEntityForName:@"Question" inManagedObjectContext:[self managedObjectContext]];
            aQuestion.qid = qid;
        }
        [aQuestion addAnswersObject:anAnswer];
        aQuestion.title = [questionInfo objectAtIndex:1];
        if (![[questionInfo objectAtIndex:2] isKindOfClass:[NSNull class]]) {
            aQuestion.detailInfo = [questionInfo objectAtIndex:2];
        }
        aQuestion.qToken = [questionInfo objectAtIndex:3];
        aQuestion.followerCount = [questionInfo objectAtIndex:4];
        aQuestion.answerCount = [questionInfo objectAtIndex:5];
        for (NSArray* topics in [questionInfo objectAtIndex:7]) {
            
            NSNumber* tid = [topics objectAtIndex:0];
            Topic* aTopic = [self topicOfTID:tid];
            if (!aTopic) {
                aTopic = [NSEntityDescription insertNewObjectForEntityForName:@"Topic" inManagedObjectContext:[self managedObjectContext]];
                aTopic.tid = tid;
            }
            aTopic.name = [topics objectAtIndex:1];
            if (![[topics objectAtIndex:2] isKindOfClass:[NSNull class]]) {
                aTopic.detailInfo = [topics objectAtIndex:2];
            }
            aTopic.picURL = [topics objectAtIndex:3];
            aTopic.tToken = [topics objectAtIndex:4];
            
            [aQuestion addTopicsObject:aTopic];
        }
        
        [questionArray addObject:anAnswer];
    }
    //------parser end------
    
    return questionArray;
}

- (Question*) questionOfQID:(NSNumber*) qid 
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Question" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"qid == %@", qid];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    return [array count] ? [array objectAtIndex:0] : nil;
}
- (Answer*) answerOfAID:(NSNumber*) aid
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Answer" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"aid == %@", aid];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    return [array count] ? [array objectAtIndex:0] : nil;
}
- (User*) userOfUID:(NSString*) uid
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"User" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"uid == %@", uid];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    return [array count] ? [array objectAtIndex:0] : nil;
}
- (Topic*) topicOfTID:(NSNumber*) tid
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Topic" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"tid == %@", tid];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    return [array count] ? [array objectAtIndex:0] : nil;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ZhihuReader" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ZhihuReader.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    //setup a MemoryStore for zhihu
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"delete store:%@",storeURL);
        error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
