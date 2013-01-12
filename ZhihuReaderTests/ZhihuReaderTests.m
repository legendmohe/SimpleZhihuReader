//
//  ZhihuReaderTests.m
//  ZhihuReaderTests
//
//  Created by 何 新宇 on 13-1-9.
//  Copyright (c) 2013年 doublesix. All rights reserved.
//

#import "ZhihuReaderTests.h"
#import "MUZhihuService.h"

@implementation ZhihuReaderTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testZhihu
{
    NSString* testURLString = [NSString stringWithFormat:@"%@%@", kZhihuReaderURLPrefix, @"1"];
    [[MUZhihuService shareService] requestForResponseStringWithZhihuURL:[NSURL URLWithString:testURLString]
     withBlock:^(id jsonObject, NSURL *aURL, NSError *error) {
         NSLog(@"%@", error);
         NSLog(@"%@", aURL);
         NSLog(@"%@", jsonObject);
    }];
}

@end
