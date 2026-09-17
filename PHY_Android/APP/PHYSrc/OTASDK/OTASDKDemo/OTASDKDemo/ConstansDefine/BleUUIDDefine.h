//
//  BleUUIDDefine.h
//  PHY
//
//  Created by Yang on 2018/10/13.
//  Copyright © 2018 phy. All rights reserved.
//

#ifndef BleUUIDDefine_h
#define BleUUIDDefine_h

typedef NS_ENUM(NSUInteger, SendMessageType) {
    /**
     *  来电提醒
     */
    phoneReminding = 0,
    /**
     *  来电提醒结束
     */
    phoneRemindingEnd = 1,
    /**
     *  短信
     */
    phoneSMS = 3,
    /**
     *  微信
     */
    phoneWechat = 5
};


/**
 通用命令相关 实时监测的值
 Wrist私有协议由三种通信方式构成：命令+应答，推送通知，只读区域
 */
#define SERVICE_UUID                                         @"0000ff01-0000-1000-8000-00805f9b34fb"
#define CHARACTERISTIC_WRITE_UUID                            @"0000ff02-0000-1000-8000-00805f9b34fb"    //命令+应答和推送通知使用一个UUID：0xff02
#define CHARACTERISTIC_READ_UUID                             @"0000ff10-0000-1000-8000-00805f9b34fb"    //只读区域提供一个的UUID：0xff10
#define DESCRIPTOR_UUID                                      @"00002902-0000-1000-8000-00805f9b34fb"    //文件描述符

/**
 点量相关
 */
#define SERVICE_BATTERY_UUID                                 @"0000180f-0000-1000-8000-00805f9b34fb"
#define CHARACTERISTIC_BATTERY_READ_UUID                     @"00002a19-0000-1000-8000-00805f9b34fb"

/**
 系统信息相关
 */
#define SERVICE_DEVICE_INFO_UUID                             @"0000180A-0000-1000-8000-00805f9b34fb"
#define CHARACTERISTIC_MAC_READ_UUID                         @"00002A23-0000-1000-8000-00805f9b34fb"


/**
 OTA相关
 */
#define SERVICE_OTA_UUID                                     @"5833ff01-9b8b-5191-6142-22a4536ef123"
#define CHARACTERISTIC_OTA_WRITE_UUID                        @"5833ff02-9b8b-5191-6142-22a4536ef123"
#define CHARACTERISTIC_OTA_INDICATE_UUID                     @"5833ff03-9b8b-5191-6142-22a4536ef123"
#define CHARACTERISTIC_OTA_DATA_WRITE_UUID                   @"5833ff04-9b8b-5191-6142-22a4536ef123"

/**
 一些命令
 */
//#define GET_VERSION                                          @"GET_VERSION"  //获取版本
//#define SYNC_TIME                                            @"SYNC_TIME"   //系统时间
//#define GET_TIME                                             @"GET_TIME"    //获取时间
//#define START_GSENSOR                                        @"START_GSENSOR"   //启用加速度传感器数据输出
//#define STOP_GSENSOR                                         @"STOP_GSENSOR"    //停止加速度传感器数据输出
//#define GSENSOR_DATA                                         @"GSENSOR_DATA"    //
//#define GET_BATTERY                                          @"GET_BATTERY"     //获得电量
//#define START_HEART_RATE                                     @"START_HEART_RATE"    //启动心率血压检测
//#define HEART_RATE_DATA                                      @"HEART_RATE_DATA"
//#define HEART_RATE_LAST_DATA                                 @"HEART_RATE_LAST_DATA"
//#define SEND_MESSAGE                                         @"SEND_MESSAGE"    //发送信息
//#define LED_SETTING                                          @"LED_SETTING"     //LED设定
//
//#define START_OTA                                            @"START_OTA"

//新增的命令






#endif /* BleUUIDDefine_h */
