//
//  CBLEMnger.h
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CBLEDataMnger.h"
#import "CBLEDataMsg.h"

NS_ASSUME_NONNULL_BEGIN

//作为中央设备
@interface CBLECenterMnger : NSObject<CBCentralManagerDelegate>
@property (nonatomic, assign) BOOL              bIsPowerOn;     //蓝牙是否上电
@property (nonatomic, strong) CDataPheralMnger* dataPherals;    //所有的外围设备
@property (nonatomic, strong) CDataPheralInfo*  curPheral;      //当前连接的外围设备
/*!
 *  desc    : 创建全局蓝牙管理中心
 *  @return : 返回蓝牙管理中心对象单例
 */
+ (nullable CBLECenterMnger *)shareMnger;
+ (BOOL)BLEIsPowerOff;

//蓝牙中心设备命令
- (void)cmdStopScan;
- (void)cmdStartScan;
- (BOOL)isScaning;
- (BOOL)isCanScan;
- (BOOL)isConnectOK;
- (void)cmdConnect2Pheral:(CDataPheralInfo*)pheral;
- (void)cmdDisconnectCurPheral;
@end

@interface CBLECenterMnger (BLEWristCmd)
- (void)wristWriteOTACmd:(NSData*)data bInOTA:(BOOL)bInOTA;
- (void)wristWriteOTAData:(NSData*)data;
- (void)wristCmdSetLED:(NSUInteger)nChannel nVal:(NSUInteger)nVal;
- (void)wristCmdStartSensor:(BOOL)bStart;
- (void)wristCmdStartHR:(BOOL)bStart;
- (void)wristNotifyNewMsg:(NSUInteger)nMsgType;
- (void)wristSendMsgByWeChat:(NSString*)strBrief strMsg:(NSString*)strMsg;
- (void)wristSendMsgBySMS:(NSString*)strBrief strMsg:(NSString*)strMsg;
- (void)wristSendMsgMore;
@end


@interface CBLECenterMnger (BLEWristOTACmdInApp)
-(void)appCmdSwitch2OTA;
-(void)appCmdVersion;
@end


@interface CBLECenterMnger (BLEWristOTACmdInOTA)
-(void)otaCmd2App;
-(void)otaCmsStart:(NSInteger)nPartitionNums;
@end











NS_ASSUME_NONNULL_END
