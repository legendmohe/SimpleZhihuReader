//
//  Question.h
//  ZhihuReader
//
//  Created by 何 新宇 on 13-1-9.
//  Copyright (c) 2013年 doublesix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Answer, Topic;

@interface Question : NSManagedObject

@property (nonatomic, retain) NSNumber * answerCount;
@property (nonatomic, retain) NSString * detailInfo;
@property (nonatomic, retain) NSNumber * followerCount;
@property (nonatomic, retain) NSNumber * qid;
@property (nonatomic, retain) NSNumber * qToken;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *answers;
@property (nonatomic, retain) NSSet *topics;
@end

@interface Question (CoreDataGeneratedAccessors)

- (void)addAnswersObject:(Answer *)value;
- (void)removeAnswersObject:(Answer *)value;
- (void)addAnswers:(NSSet *)values;
- (void)removeAnswers:(NSSet *)values;

- (void)addTopicsObject:(Topic *)value;
- (void)removeTopicsObject:(Topic *)value;
- (void)addTopics:(NSSet *)values;
- (void)removeTopics:(NSSet *)values;

@end
