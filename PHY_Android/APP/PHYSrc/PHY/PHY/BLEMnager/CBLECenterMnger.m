//
//  CBLEMnger.m
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//

#import "CBLECenterMnger.h"
#import "CBLEDataMsg.h"
#import "CBLEOTAMnger.h"

@interface CBLECenterMnger()
@property(nonatomic,strong)NSMutableArray*       waitSendMsgList;
@property(nonatomic,assign)NSInteger             msgLastType;
@property(nonatomic,strong)CBCentralManager*     centerMnager;
@property(nonatomic,assign)NSInteger             reConnectIdx;    //蓝牙重新断开后，重新连接的次数
@end


@implementation CBLECenterMnger

+ (BOOL)BLEIsPowerOff{
    
    return ![CBLECenterMnger shareMnger].bIsPowerOn;
}

+ (nullable CBLECenterMnger *)shareMnger{
    
    static dispatch_once_t pred = 0;
    __strong static CBLECenterMnger   *_bleMnger = nil;
    dispatch_once(&pred, ^{
        _bleMnger = [[self alloc] init];
    });
    return _bleMnger;
}

-(instancetype)init{
    if ( self = [super init] ){
        _centerMnager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _dataPherals  = [CDataPheralMnger dataMnger];
        [self resetDefaultData];
    }
    return self;
}

-(void)resetDefaultData{
    
    _reConnectIdx  = 0;
    _bIsPowerOn    = NO;
    [_dataPherals removeAll];
    _curPheral = nil;
}


- (void)cmdStopScan{
    [_centerMnager stopScan];
}

- (void)scanANCSPheriacl{
    
    NSString *strSericeID = @"7905F431-B5CE-4E99-A40F-4B1E122D00D0";
    strSericeID = SERVICE_OTA_UUID;
    CBUUID   *uuid = [CBUUID UUIDWithString:strSericeID];
    
    //UUID是外设的服务UUID，满足UUID 的外设就会放在数组中
    __weak __typeof(&*self)weakSelf = self;
    NSArray *arr = [_centerMnager retrieveConnectedPeripheralsWithServices:@[uuid]];
    [arr enumerateObjectsUsingBlock:^(CBPeripheral *obj, NSUInteger idx, BOOL *stop) {
        [weakSelf centralManager:_centerMnager didDiscoverPeripheral:obj advertisementData:nil RSSI:[NSNumber numberWithInt:0]];
            //NSLog(@"连接=====%@ %lu   /n%@",obj,(unsigned long)idx,obj.services);
    //        [self discoverANCS:obj];
    }];
}

- (void)cmdStartScan{

    if (_curPheral != nil ) {
        [_centerMnager cancelPeripheralConnection:_curPheral.peripheral];
        _curPheral = nil;
        //_readCharacteristic = nil;
        //_writeNotifyCharacteristic = nil;
        //_writeOTAWithRespCharac = nil;
        //_writeOTAWithoutRespCharac = nil;
    }
    //-------- TODO:设置 SERVICE_UUID
    //连接指定外设，就是通过UUID连接的，这个UUID被连接的设备要广播出来，这样BLE才能搜索到并且连接。
    //其中的uuid就是被连接设备广播出来的UUID字符串。
    //services为nil时是全扫描
    //@[[CBUUID UUIDWithString:SERVICE_UUID]]
    

    [self scanANCSPheriacl];
    [_centerMnager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
}

- (void)cmdDisconnectCurPheral{
   
    if ( _curPheral == nil ) return;
    [_centerMnager cancelPeripheralConnection:_curPheral.peripheral];
    _curPheral = nil;
}


- (void)cmdConnect2Pheral:(CDataPheralInfo*)pheral;{

    if ( pheral == nil ) return;
    
    _curPheral = pheral;
    [_centerMnager connectPeripheral:pheral.peripheral options:nil];
}


- (BOOL)isScaning{
    return [_centerMnager isScanning];
}

- (BOOL)isCanScan{
    if ( _bIsPowerOn && _curPheral == nil )
        return YES;
    return FALSE;
}

- (BOOL)isConnectOK{
    if ( _curPheral != nil &&
        CBPeripheralStateConnected == _curPheral.peripheral.state )
        return YES;
    return NO;
}

-(void)logicCBPowerOn:(BOOL)bIsPowerOn{
    
    //蓝牙中心设备状态改变，通知界面给出提示
    _bIsPowerOn = bIsPowerOn;
    [[NSNotificationCenter defaultCenter] postNotificationName:BLEMSG_CENTER_POWERON object:nil];
}

//
// 蓝牙中心代理
//
#pragma mark 【1】监测蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state){
        case CBManagerStateUnknown:      break;
        case CBManagerStateUnsupported:  break;
        case CBManagerStateUnauthorized: break;
        case CBManagerStatePoweredOff: [self logicCBPowerOn:NO];break;
        case CBManagerStateResetting:    break;
        case CBManagerStatePoweredOn:  [self logicCBPowerOn:YES];break;
    }
}

#pragma mark 【2】发现外部蓝牙设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    //NSLog(@"发现新的蓝牙设备......\r\n");
    if ( peripheral.name == nil || peripheral.name.length <=0 ||
        [peripheral.name isEqual:[NSNull null]] )
        return;
    
     CDataPheralInfo *data = [CDataPheralInfo dataPheral:peripheral advData:advertisementData RSSI:RSSI];
    BOOL bNewPheral = [self.dataPherals addPheral:data];
    //只有新发现的蓝牙才通知UI
    if ( bNewPheral )
        [[NSNotificationCenter defaultCenter] postNotificationName:BLEMSG_CENTER_NEWPHERAL object:data];
}

#pragma mark【3】连接外部蓝牙设备成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    _reConnectIdx = 0;
    [_curPheral startFindSrv:peripheral];
    POST_MESSAGE(BLEMSG_PHERAL_CONNECT_RST);
    
    //连接蓝牙成功以后，查询BOOTLOAD版本
    [self performSelector:@selector(checkBootVerInAppMode) withObject:nil afterDelay:1];
}

#pragma mark 【4】连接外部蓝牙设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    //连接蓝牙失败，通知界面做逻辑处理
    _curPheral = nil;
    POST_MESSAGE(BLEMSG_PHERAL_CONNECT_RST);
}

#pragma mark 【5】蓝牙外设连接断开，自动重连
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    _curPheral = nil;
    POST_MSG_WITHOBJ(BLEMSG_PHERAL_DISCONNECT,0);
#if 0
    //1.停止发送所有指令
    
    //2.通知界面
    _reConnectIdx ++;
    NSString *strTryNum = [NSString stringWithFormat:@"%ld",(long)_reConnectIdx];
    POST_MSG_WITHOBJ(BLEMSG_PHERAL_DISCONNECT,strTryNum);
    if ( peripheral && _reConnectIdx < BLE_CONST_MAX_TRYCONNECT ) {
        _reConnectIdx++;
        NSLog(@"\n\n断开与%@的连接，正在尝试第[%ld]次重连...\n\n",_curPheral.peripheral,(long)_reConnectIdx);
        [self cmdConnect2Pheral:_curPheral bConnect:YES];
    }
#endif
}


-(void)checkBootVerInAppMode{
    if ( !self.curPheral.bIsInOTA ){
        [self appCmdVersion];
    }
}

@end









////////////////////////////////////////////////////////////////////////////////
/*
 *       CBLECenterMnger BLEWrist command with ack
 */
////////////////////////////////////////////////////////////////////////////////
@implementation CBLECenterMnger (BLEWristCmd)
- (void)wristSendCmdAckMsg:(NSData*)data{
    
    if ( _curPheral != nil ){
        [_curPheral writeCmdAckMsg:data];
    } else {
        NSLog(@"------>当前没有连接蓝牙，不能发送wrist命令!");
    }
}

-(void)wristWriteOTACmd:(NSData*)data bInOTA:(BOOL)bInOTA{
 
    if ( _curPheral != nil ){
        [_curPheral writeOTACmd:data bInOTA:bInOTA];
    } else {
        NSLog(@"------>当前没有连接蓝牙，不能发送OTA命令!");
    }
}

-(void)wristWriteOTAData:(NSData*)data{
    
    if ( _curPheral != nil ){
        [_curPheral writeOTAData:data];
    } else {
        NSLog(@"------>当前没有连接蓝牙，不能发送OTA数据!");
    }
}

- (void)wristCmdSetLED:(NSUInteger)nChannel nVal:(NSUInteger)nVal{
    NSData *cmdData = [CBLEDataMsg buildLEDMsg:nChannel nVal:nVal];
    [self wristSendCmdAckMsg:cmdData];
}

- (void)wristCmdStartSensor:(BOOL)bStart{
    NSData *cmdData = [CBLEDataMsg buildStartSensorMsg:bStart];
    [self wristSendCmdAckMsg:cmdData];
}


- (void)wristCmdStartHR:(BOOL)bStart{
    NSData *cmdData = [CBLEDataMsg buildStartHeartRate:bStart];
    [self wristSendCmdAckMsg:cmdData];
}

- (void)wristNotifyNewMsg:(NSUInteger)nMsgType{
    NSData *cmdData = [CBLEDataMsg buildNewMsgNotify:nMsgType strMsg:nil  moreState:WristMsgFlagBrief];
    [self wristSendCmdAckMsg:cmdData];
}

- (void)wristSendMsg:(NSString*)strSummary strMsg:(NSString*)strMsg msgType:(NSUInteger)msgType{
    
    self.msgLastType = msgType;
    NSInteger moreState = WristMsgFlagBrief;
    
    if ( strMsg != nil && strMsg.length > 0 ){
        moreState = WristMsgFlagBriefText;
        //在此将消息正文转换为数组
        self.waitSendMsgList = [CBLEDataMsg convertMsg2Ary:strMsg];
    }
    
    NSData *cmdData = [CBLEDataMsg buildNewMsgNotify:msgType strMsg:strSummary  moreState:moreState];
    [self wristSendCmdAckMsg:cmdData];
}

//发送剩余的正文消息
- (void)wristSendMsgMore{
    
    NSInteger nNums = self.waitSendMsgList.count;
    if ( nNums <= 0 ) return;
    
    NSString *strMsg = [self.waitSendMsgList firstObject];
    if ( strMsg == nil || strMsg.length <= 0 )
        return;
    
    [self.waitSendMsgList removeObjectAtIndex:0];
    NSInteger moreState = WristMsgFlagTextMore;
    if ( nNums == 1 )
        moreState = WristMsgFlagTextLast;
    
    NSData *cmdData = [CBLEDataMsg buildNewMsgNotify:self.msgLastType  strMsg:strMsg  moreState:moreState];
    [self wristSendCmdAckMsg:cmdData];
    
}

- (void)wristSendMsgByWeChat:(NSString*)strBrief strMsg:(NSString*)strMsg{
    [self wristSendMsg:strBrief strMsg:strMsg msgType:BLEWristSendMsgTypeNewWeChat];
}

- (void)wristSendMsgBySMS:(NSString*)strBrief strMsg:(NSString*)strMsg{
   [self wristSendMsg:strBrief strMsg:strMsg msgType:BLEWristSendMsgTypeNewSMS];
}

@end



////////////////////////////////////////////////////////////////////////////////
/*
 *       CBLECenterMnger BLEWrist OTACmd for app
 */
////////////////////////////////////////////////////////////////////////////////

@implementation CBLECenterMnger (BLEWristOTACmdInApp)

-(void)appCmdSwitch2OTA{
   
    NSData *cmdData = [CBLEDataMsg buildApp2OTA];
    [self wristWriteOTACmd:cmdData bInOTA:NO];
    
}

-(void)appCmdVersion{
    NSData *cmdData = [CBLEDataMsg buildBleVersion];
    [self wristWriteOTACmd:cmdData bInOTA:NO];
}

@end



////////////////////////////////////////////////////////////////////////////////
/*
 *       CBLECenterMnger BLEWrist command for OTA mode
 */
////////////////////////////////////////////////////////////////////////////////


@implementation CBLECenterMnger (BLEWristOTACmdInOTA)
-(void)otaCmd2App{
    
    NSData *cmdData = [CBLEDataMsg buildOTA2App];
    [self wristWriteOTACmd:cmdData bInOTA:YES];
    //POST_MSG_WITHOBJ(BLEMSG_PHERAL_DISCONNECT,0);
}

-(void)otaCmsStart:(NSInteger)nPartitionNums{
    NSData *cmdData = [CBLEDataMsg buildOTAStart:nPartitionNums];
    [self wristWriteOTACmd:cmdData bInOTA:YES];
}

-(void)otaCmdByData:(NSData*)cmdData{
    
}
@end
