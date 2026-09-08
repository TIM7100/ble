//
//  GToolUtil.m
//  KDIOSApp
//
//  Created by 曹晓丽 on 16/4/27.
//  Copyright © 2016年 KDIOSApp. All rights reserved.
//

#import "GToolUtil.h"
#import "sys/utsname.h"
//#import "RegisterVC.h"
//#import "LoginSecVC.h"

#import "AFNetworkReachabilityManager.h"

#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
@interface GToolUtil()
@end

@implementation GToolUtil


//获取网络状态
+(NSString *) getNetworkType{
    
    NSString *type = @"";
    AFNetworkReachabilityStatus status = [[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus];
    if (status == AFNetworkReachabilityStatusReachableViaWWAN) {
        //2g,3g
        type = @"2g,3g,4g";
    }
    else if (status == AFNetworkReachabilityStatusReachableViaWiFi)
    {
        //wifi
        type = @"wifi";
    }
    return type;
}

+ (NSString *)getCurrentAppVersionCode
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
    return version;
}

//版本比较的函数 相等返回0 第一个比第二个版本号大1
+ (int)compareVersion:(NSString *)firstVersion version:(NSString *)secondVersion {
    int result = 0;
    NSArray *firstVersionItems = [firstVersion componentsSeparatedByString:@"."];
    NSArray *secondVersionItems = [secondVersion componentsSeparatedByString:@"."];
    for (int i = 0; i<[firstVersionItems count] || i< [secondVersionItems count]; i++)
    {
        int firstItem = 0;
        int secondItem = 0;
        if (i<[firstVersionItems count])
        {
            firstItem = [[firstVersionItems objectAtIndex:i] intValue];
        }
        if (i<[secondVersionItems count])
        {
            secondItem = [[secondVersionItems objectAtIndex:i] intValue];
        }
        
        if (firstItem != secondItem)
        {
            result = (firstItem<secondItem)?-1:1;
            break;
        }
    }
    
    return result;
}

@end
