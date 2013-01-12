//
//  Topic.h
//  ZhihuReader
//
//  Created by 何 新宇 on 13-1-9.
//  Copyright (c) 2013年 doublesix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Question;

@interface Topic : NSManagedObject

@property (nonatomic, retain) NSString * detailInfo;
@property (nonatomic, retain) NSNumber * tid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * picURL;
@property (nonatomic, retain) NSString * tToken;
@property (nonatomic, retain) NSSet *questions;
@end

@interface Topic (CoreDataGeneratedAccessors)

- (void)addQuestionsObject:(Question *)value;
- (void)removeQuestionsObject:(Question *)value;
- (void)addQuestions:(NSSet *)values;
- (void)removeQuestions:(NSSet *)values;

@end
