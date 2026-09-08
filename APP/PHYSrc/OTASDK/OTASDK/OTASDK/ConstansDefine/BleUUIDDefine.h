//
//  BleUUIDDefine.h
//  PHYSDKDemo
//
//  Created by Yang on 2018/10/13.
//  Copyright © 2018 PHYSDKDemo. All rights reserved.
//

#ifndef BleUUIDDefine_h
#define BleUUIDDefine_h


/**
 通用命令相关 实时监测的值
 Wrist私有协议由三种通信方式构成：命令+应答，推送通知，只读区域
 */
#define SERVICE_UUID                                         @"0000ff01-0000-1000-8000-00805f9b34fb"
#define CHARACTERISTIC_WRITE_UUID                            @"0000ff02-0000-1000-8000-00805f9b34fb"    //命令+应答和推送通知使用一个UUID：0xff02
#define CHARACTERISTIC_READ_UUID                             @"0000ff10-0000-1000-8000-00805f9b34fb"    //只读区域提供一个的UUID：0xff10
#define DESCRIPTOR_UUID                                      @"00002902-0000-1000-8000-00805f9b34fb"    //文件描述符

/**
 电量相关
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
#define CHARACTERISTIC_OTA_WRITE_UUID                        @"5833ff02-9b8b-5191-6142-22a4536ef123"//white
#define CHARACTERISTIC_OTA_INDICATE_UUID                     @"5833ff03-9b8b-5191-6142-22a4536ef123"//notify
#define CHARACTERISTIC_OTA_DATA_WRITE_UUID                   @"5833ff04-9b8b-5191-6142-22a4536ef123"

/**
 一些命令
 */
//
//#define START_OTA                                            @"START_OTA"



#endif /* BleUUIDDefine_h */
