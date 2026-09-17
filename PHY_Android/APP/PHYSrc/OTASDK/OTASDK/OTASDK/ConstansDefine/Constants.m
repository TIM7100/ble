//
//  Constants.m
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "Constants.h"

@implementation Constants

/**
 *常量表  开始
 */
//================= start======================
NSUInteger const LAMPCHANNELONE = 1;//LED灯通道0
NSUInteger const LAMPCHANNELTWO = 2;//LED灯通道1
NSUInteger const LAMPCHANNELTHREE = 0;//LED灯通道2

NSUInteger const START_HEART_RATE = 0x21;//启动血压检测
NSUInteger const STOP_HEART_RATE = 0x22;//停止血压检测
NSUInteger const START_GSENSOR = 0x23;//启动加速器传感器
NSUInteger const STOP_GSENSOR = 0x24;//停止加速器传感器
NSUInteger const LED_SETTING = 0x30;//LED灯设定
NSUInteger const HEART_RATE_LAST_DATA = 0x81;//获取心率数据最后的测量值
NSUInteger const SEND_MESSAGE = 0x38;//推送消息
NSUInteger const UPDATE_SYSTEM_TIME = 0x02;//更新系统时间


NSUInteger const START_OTA = 0x0102;//OTA

NSUInteger const REROOT = 0x04;//OTA
@end
