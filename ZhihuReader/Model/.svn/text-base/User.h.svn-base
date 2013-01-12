//
//  User.h
//  ZhihuReader
//
//  Created by 何 新宇 on 13-1-9.
//  Copyright (c) 2013年 doublesix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Answer;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * picURL;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * screenname;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *answer;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addAnswerObject:(Answer *)value;
- (void)removeAnswerObject:(Answer *)value;
- (void)addAnswer:(NSSet *)values;
- (void)removeAnswer:(NSSet *)values;

@end
