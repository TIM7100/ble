//
//  Constants.h
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Constants : NSObject

//通知 预留

//extern NSString * const kNotificationNeedLogin;     //需要用户登录时使用，暂时不用
////错误描述
//extern NSString * const kErrorUnknown;
////http请求方式
//extern NSString * const kHttpRequestPost;
//extern NSString * const kHttpRequestGet;


/**
 *常量表  开始
 */
//================= start ======================
extern NSUInteger const LAMPCHANNELONE;//LED灯通道0
extern NSUInteger const LAMPCHANNELTWO;//LED灯通道1
extern NSUInteger const LAMPCHANNELTHREE;//LED灯通道2

extern NSUInteger const START_HEART_RATE;//启动血压检测
extern NSUInteger const STOP_HEART_RATE;//停止血压检测
extern NSUInteger const START_GSENSOR;//启动加速器传感器
extern NSUInteger const STOP_GSENSOR;//停止加速器传感器
extern NSUInteger const LED_SETTING;//LED灯设定
extern NSUInteger const HEART_RATE_LAST_DATA;//获取心率数据最后的测量值

extern NSUInteger const SEND_MESSAGE;//推送消息
extern NSUInteger const UPDATE_SYSTEM_TIME;//更新系统时间
extern NSUInteger const GET_BLE_SYSTEM_INFO;  //取得蓝牙系统版本信息


extern NSUInteger const START_OTA;//OTA

extern NSUInteger const REROOT;//OTA

@end

NS_ASSUME_NONNULL_END
