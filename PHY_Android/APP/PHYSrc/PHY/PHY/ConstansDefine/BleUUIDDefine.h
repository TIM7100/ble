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
//都有这个服务特征值
#define SERVICE_OTA_UUID                                     @"5833FF01-9B8B-5191-6142-22A4536EF123"   //5833FF01-9B8B-5191-6142-22A4536EF123
#define CHARACTERISTIC_OTA_WRITE_UUID                        @"5833FF02-9B8B-5191-6142-22A4536EF123"
#define CHARACTERISTIC_OTA_INDICATE_UUID                     @"5833FF03-9B8B-5191-6142-22A4536EF123"
#define CHARACTERISTIC_OTA_DATA_WRITE_UUID                   @"5833FF04-9B8B-5191-6142-22A4536EF123"
//只有在OTA模式下才有04这个CHAR
//新增的命令



//应用模式下发送命令
// 01 00 //4个参数

#endif /* BleUUIDDefine_h */
