//
//  NSString+GetParam.m
//  KDLC
//
//  Created by 杨运 on 16/6/3.
//  Copyright © 2016年 llyt. All rights reserved.
//

#import "NSString+GetParam.h"

@implementation NSString (GetParam)
- (NSString *)urlClear
{
    NSString *tmpStr = [self stringByReplacingOccurrencesOfString:@" " withString:@""];
    tmpStr = [tmpStr stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    tmpStr = [tmpStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return tmpStr;
}

@end
