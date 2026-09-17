//
//  GToolUtil.h
//  KDIOSApp
//
//  Created by 曹晓丽 on 16/4/27.
//  Copyright © 2016年 KDIOSApp. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface GToolUtil : NSObject

//获取网络状态
+(NSString *)getNetworkType;
//获取app当前版本
+ (NSString *)getCurrentAppVersionCode;
//版本比较的函数 相等返回0 第一个比第二个版本号大1
+ (int)compareVersion:(NSString *)firstVersion version:(NSString *)secondVersion;
@end
