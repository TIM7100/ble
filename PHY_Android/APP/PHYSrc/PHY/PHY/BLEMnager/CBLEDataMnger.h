//
//  CBLEMnger.h
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CBLEDataMsg.h"


@class CDataPheralInfo;
//蓝牙管理器中心协议

@protocol CDataPheralInfoDelegate <NSObject>

@optional
- (void)wristCmdAck:(nullable CDataPheralInfo *) manager
               ackData:(MsgDataWristAck *)accData;



@end

//1.外部蓝牙设备的基本数据类型
@interface CDataPheralInfo : NSObject
@property (nonatomic, weak, nullable) id <CDataPheralInfoDelegate> delegate;
@property (nonatomic, strong) CBPeripheral  *peripheral;
@property (nonatomic, strong) NSDictionary  *advData;
@property (nonatomic, strong) NSNumber      *RSSI;
@property (nonatomic, copy)   NSString      *adverMacAddr;
@property (nonatomic, assign,readonly)BOOL  bIsInOTA;
@property (nonatomic,copy)    NSString      *strBootVer;
+(instancetype)dataPheral:(CBPeripheral*)pheral advData:(NSDictionary *)advData RSSI:(NSNumber *)RSSI;
-(BOOL)isSamePheral:(CBPeripheral*)pheral;
-(void)startFindSrv:(CBPeripheral*)pheral;
-(void)disConnect:(CBPeripheral*)pheral;

-(void)writeCmdAckMsg:(NSData*)cmdData;
-(void)writeOTACmd:(NSData*)otaCmdData bInOTA:(BOOL)bInOTA;
-(void)writeOTAData:(NSData*)otaData;

-(NSString*)fmtBootVer;
-(BOOL)isSamePheralWithMacAddr:(NSString*)devMac;
-(BOOL)isSamePheralWithUUID:(NSString*)uuidStr;
@end



//2.外部蓝牙设备的数据管理
@interface CDataPheralMnger : NSObject
+(instancetype)dataMnger;
-(NSInteger)totalNums;
-(CDataPheralInfo*)dataWithIndex:(NSInteger)nIdx;

-(void)removeAll;
-(BOOL)addPheral:(CDataPheralInfo*)data;
-(BOOL)addPheral:(CBPeripheral*)pheral advData:(NSDictionary *)advData RSSI:(NSNumber *)RSSI;



@end
