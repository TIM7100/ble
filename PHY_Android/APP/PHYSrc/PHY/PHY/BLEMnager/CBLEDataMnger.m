//
//  CBLEMnger.m
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//

#import "CBLEDataMnger.h"
#import "CBLEDataParse.h"
#import "JCDataConvert.h"
#import "CBLECenterMnger.h"

@interface CDataPheralInfo()<CBPeripheralDelegate>
@property(nonatomic,strong)CBUUID  *uuidReadMacAddr;
@property(nonatomic,strong)CBUUID  *uuidWristCmdAckPush;
@property(nonatomic,strong)CBUUID  *uuidWristReadAck;

@property(nonatomic,strong)CBUUID  *uuidWR;
@property(nonatomic,strong)CBUUID  *uuidWRWrite;
@property(nonatomic,strong)CBUUID  *uuidWRIndicate;
@property(nonatomic,strong)CBUUID  *uuidWRWriteOTAData;
@property(nonatomic,strong)CBCharacteristic *writeCmdAckChrtcs;
@property(nonatomic,strong)CBCharacteristic *writeOTAWithRespCharac;
@property(nonatomic,strong)CBCharacteristic *writeOTAWithoutRespCharac;
@end


@implementation CDataPheralInfo

- (NSString*)fmtBootVer{
    
    NSString *strTip = @"OTA模式";
    if ( !_bIsInOTA ){
        strTip = [NSString stringWithFormat:@"bootver:%@",_strBootVer];
        if ( _strBootVer == nil || _strBootVer.length <= 0 )
            strTip =@" ";
    }
    return strTip;
}

-(BOOL)isSamePheralWithMacAddr:(NSString*)oldMac{
    
    //0405122696d812fc0000
    //FC:12:D8:96:26:11
    NSString *strCur = self.adverMacAddr;
    if ( strCur == nil || strCur.length <= 0 ) return NO;
    if ( oldMac == nil || oldMac.length <= 0 ) return NO;
   
    NSString *strTemp = [strCur substringWithRange:NSMakeRange(4, 2)];
    NSInteger nNew1 = strtoul([strTemp UTF8String],0,16);

    strTemp = [strCur substringWithRange:NSMakeRange(6, 2)];
    NSInteger nNew2 = strtoul([strTemp UTF8String],0,16);
    
    strTemp = [strCur substringWithRange:NSMakeRange(8, 2)];
    NSInteger nNew3 = strtoul([strTemp UTF8String],0,16);
    
    strTemp = [strCur substringWithRange:NSMakeRange(10, 2)];
    NSInteger nNew4 = strtoul([strTemp UTF8String],0,16);
    
    strTemp = [strCur substringWithRange:NSMakeRange(12, 2)];
    NSInteger nNew5 = strtoul([strTemp UTF8String],0,16);
    
    strTemp = [strCur substringWithRange:NSMakeRange(14, 2)];
    NSInteger nNew6 = strtoul([strTemp UTF8String],0,16);
    
    
    strTemp = [oldMac substringWithRange:NSMakeRange(0, 2)];
    NSInteger nLoc1 = strtoul([strTemp UTF8String],0,16);
    
    strTemp = [oldMac substringWithRange:NSMakeRange(3, 2)];
    NSInteger nLoc2 = strtoul([strTemp UTF8String],0,16);
    
    strTemp = [oldMac substringWithRange:NSMakeRange(6, 2)];
    NSInteger nLoc3 = strtoul([strTemp UTF8String],0,16);
    
    strTemp = [oldMac substringWithRange:NSMakeRange(9, 2)];
    NSInteger nLoc4 = strtoul([strTemp UTF8String],0,16);
    
    strTemp = [oldMac substringWithRange:NSMakeRange(12, 2)];
    NSInteger nLoc5 = strtoul([strTemp UTF8String],0,16);
    
    strTemp = [oldMac substringWithRange:NSMakeRange(15, 2)];
    NSInteger nLoc6 = strtoul([strTemp UTF8String],0,16);

    if( nLoc1 != nNew6 ) return NO;
    if( nLoc2 != nNew5 ) return NO;
    if( nLoc3 != nNew4 ) return NO;
    if( nLoc4 != nNew3 ) return NO;
    if( nLoc5 != nNew2 ) return NO;
    if( nLoc6+1 != nNew1 ) return NO;
    
    return YES;
}

-(BOOL)isSamePheralWithUUID:(NSString*)uuidStr{
    if ( [_peripheral.identifier.UUIDString isEqualToString:uuidStr] )
        return YES;
    return NO;
}


+(instancetype)dataPheral:(CBPeripheral*)pheral advData:(NSDictionary *)advData RSSI:(NSNumber *)RSSI{
    CDataPheralInfo *dataInfo = [[CDataPheralInfo alloc] initWithPheral:pheral advData:advData RSSI:RSSI];
    return dataInfo;
}

-(instancetype)initWithPheral:(CBPeripheral*)pheral advData:(NSDictionary *)advData RSSI:(NSNumber *)RSSI{
    
    if ( self = [super init] ){
        
        _strBootVer = @"";
        _bIsInOTA   = NO;
        _peripheral = pheral;
        _advData    = advData;
        _RSSI       = RSSI;
        
        if ( advData != nil )
            [self parseMacAddr:advData];
        
        _uuidReadMacAddr     = [CBUUID UUIDWithString:BLEUUID_SERVER_DEVICE_READMAC];
        _uuidWristCmdAckPush = [CBUUID UUIDWithString:BLEUUID_SERVER_WRIST_CMDACK];
        _uuidWristReadAck    = [CBUUID UUIDWithString:BLEUUID_SERVER_WRIST_READ];
        
        _uuidWR              = [CBUUID UUIDWithString:BLEUUID_SERVER_WR];
        _uuidWRWrite         = [CBUUID UUIDWithString:BLEUUID_SERVER_WR_WRITE];;
        _uuidWRIndicate      = [CBUUID UUIDWithString:BLEUUID_SERVER_WR_INDICATE];
        _uuidWRWriteOTAData  = [CBUUID UUIDWithString:BLEUUID_SERVER_WR_DATA_WRITE];
    }
    return self;
}



-(void)parseMacAddr:(NSDictionary*)dict{
    // 2 -解析广播数据
    NSObject *value = [dict objectForKey:@"kCBAdvDataManufacturerData"];
    NSString *macStr = nil;
    if (![value isKindOfClass: [NSArray class]]){
        _adverMacAddr = macStr;
        const char *valueString = [[value description] cStringUsingEncoding: NSUTF8StringEncoding];
        
        //如果为空，则跳过，解决出现空指针bug
        if (valueString != NULL) {
            NSString *value = [NSString stringWithFormat:@"%s",valueString];
            value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
            value = [value stringByReplacingOccurrencesOfString:@"<" withString:@""];
            value = [value stringByReplacingOccurrencesOfString:@">" withString:@""];
            _adverMacAddr = value;
        }
    }
}

-(BOOL)isSamePheral:(CBPeripheral*)pheral{
    
    if ( [_peripheral.identifier.UUIDString isEqualToString:pheral.identifier.UUIDString] ){
        return YES;
    }
    return NO;
}


-(void)startFindSrv:(CBPeripheral*)pheral{

    _peripheral = pheral;
    _peripheral.delegate = self;
    _strBootVer = @"";
    [_peripheral discoverServices:nil];
}

-(void)disConnect:(CBPeripheral*)pheral{
    _peripheral = pheral;
}

#pragma mark 蓝牙连接上的代理 【1】寻找蓝牙服务
//外围设备寻找到服务后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if( error ){
        NSLog(@"外围设备寻找服务过程中发生错误，错误信息：%@",error.localizedDescription);
        return;
    }
    
    // 1.查询所有的蓝牙服务
    for (CBService *service in peripheral.services) {
        
        //NSLog(@"------发现蓝牙服务：%@",service.UUID.UUIDString);
        if ( [service.UUID isEqual:_uuidWR ] ){
            _bIsInOTA = NO;
        }
        [peripheral discoverCharacteristics:nil forService:service];
    }
}



#pragma mark 【7】寻找蓝牙服务中的特性
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if (error) {//报错直接返回退出
        NSLog(@"didDiscoverCharacteristicsForService error : %@", [error localizedDescription]);
        return;
    }
    
    //NSLog(@"---------->服务：%@<------",service.UUID);
     for (CBCharacteristic *chrtsc in service.characteristics) {//遍历服务中的所有特性
         //NSLog(@"   --------->蓝牙特征值：%@",chrtsc.UUID.UUIDString );
         
         //1.mac地址
         if ([chrtsc.UUID isEqual:_uuidReadMacAddr]) {
             [peripheral readValueForCharacteristic:chrtsc];
         }
         
         //2.命令、应答、推送 找到收数据特性
         if ([chrtsc.UUID isEqual:_uuidWristCmdAckPush]){
             // 订阅, 实时接收
             [peripheral readValueForCharacteristic:chrtsc];
             [peripheral setNotifyValue:YES forCharacteristic:chrtsc];//订阅其特性（这个特性只有订阅方式）
             _writeCmdAckChrtcs = chrtsc;
         }
         
         //3.找到发数据特性
         if ([chrtsc.UUID isEqual:_uuidWristReadAck ]) {
             [peripheral readValueForCharacteristic:chrtsc];
         }
         
         //4.此时才算真正连接成功，因为此时才有读、写特征，可以正常进行数据交互
         if (_writeCmdAckChrtcs ) {
             NSLog(@"------>连接成功，可以开始读写蓝牙数据------\n");
         }
         
         //5.读写数据指示
         if ([chrtsc.UUID isEqual:_uuidWRIndicate]) {
             [peripheral readValueForCharacteristic:chrtsc];
             [peripheral setNotifyValue:YES forCharacteristic:chrtsc];
         }
         
         if ([chrtsc.UUID isEqual:_uuidWRWrite ]) {
             _writeOTAWithRespCharac = chrtsc;
         }
         
         
         if ([chrtsc.UUID isEqual:_uuidWRWriteOTAData ]) {
             _bIsInOTA = YES;
             _writeOTAWithoutRespCharac = chrtsc;
             POST_MESSAGE(BLEMSG_CENTER_NEWPHERAL_OTA);
             NSLog(@"-----当前蓝牙是OTA模式！！！！！！");
         }
     }
}

#pragma mark 【8】直接读取特征值被更新后  **********读数据*********
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"更新特征值时发生错误，错误信息：name=%@ errorDesc=%@",
              peripheral.name,error.localizedDescription);
        return;
    }

    //NSLog(@"   --------->蓝牙特征值更新的数据：%@",characteristic.UUID.UUIDString);
    CBLEDataParse *parseTool = [CBLEDataParse dataParse];
    
    //1.MAC地址更新
    if([characteristic.UUID isEqual:_uuidReadMacAddr] ){
        NSString *strMacAddr = [parseTool parseMacAddr:characteristic];
        self.adverMacAddr = strMacAddr;
        POST_MESSAGE(BLEMSG_PHERAL_UPDATE_INFO);
    }
    
    //2.Wrist通信协议版本，发送命令的返回值
    if( [characteristic.UUID isEqual:_uuidWristCmdAckPush] ){
        NSInteger nCmd = [parseTool parseCmdAck:characteristic];
        
        //此处的业务需要优化
        if ( nCmd == eBLEWristSendMsg ){
            [[CBLECenterMnger shareMnger] wristSendMsgMore];
        }
        if ( nCmd != 0 && [_delegate respondsToSelector:@selector(wristCmdAck:ackData:)] ){
            [self.delegate wristCmdAck:self ackData:parseTool.ackData];
        }
    }
    
    //3.OTA命令模式下的
    if( [characteristic.UUID isEqual:_uuidWRIndicate] ){
        
        //应用模式下的OTA命令返回的参数
        if ( !_bIsInOTA ){
            NSInteger nCmd = [parseTool parseAppOTAAck:characteristic];
            if ( nCmd == eBLEWristOTACmdVersionAck ){
                _strBootVer = parseTool.ackData.strBootVer;
                _adverMacAddr = parseTool.ackData.strMacAddr;
                POST_MESSAGE(BLEMSG_PHERAL_UPDATE_INFO);
            }
        //OTA的OTA返回参数
        } else {
            NSInteger nCmd = [parseTool parseOTAAck:characteristic];
            POST_MSG_WITHOBJ(BLEMSG_PHERAL_OATCMD_ACK, parseTool);
        }
    }
}

-(void)writeCmdAckMsg:(NSData*)cmdData{
    
    NSString *strCmd = [JCDataConvert convertDataToHexStr:cmdData];
    NSLog(@" -->app cmd: %@",strCmd );
    
    
    if ( _bIsInOTA ){
        NSLog(@"------>当前是OTA模式，不能发送wrist命令！<------");
        return;
    }
    if ( _peripheral != nil && _writeCmdAckChrtcs != nil ){
        [_peripheral writeValue:cmdData
              forCharacteristic:_writeCmdAckChrtcs
                           type:CBCharacteristicWriteWithResponse];
    }
}

-(void)writeOTACmd:(NSData*)otaCmdData bInOTA:(BOOL)bInOTA{
  
    NSString *strCmd = [JCDataConvert convertDataToHexStr:otaCmdData];
    NSLog(@" -->ota cmd: %@",strCmd );
    
    if ( bInOTA && !_bIsInOTA ){
        NSLog(@"------>当前是OTA模式，不能发送wrist命令！<------");
        return;
    }
    
    if ( _peripheral != nil && _writeOTAWithRespCharac != nil ){
        [_peripheral writeValue:otaCmdData
              forCharacteristic:_writeOTAWithRespCharac
                           type:CBCharacteristicWriteWithResponse];
    }
}

-(void)writeOTAData:(NSData*)otaData{
    [_peripheral writeValue:otaData
          forCharacteristic:_writeOTAWithoutRespCharac
                       type:CBCharacteristicWriteWithoutResponse];
}
@end



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@interface CDataPheralMnger()
@property (nonatomic, strong) NSMutableArray      *aryPheral;
@end

@implementation CDataPheralMnger
+(instancetype)dataMnger{
    CDataPheralMnger *dataMnger = [[CDataPheralMnger alloc] init];
    return dataMnger;
}

-(NSInteger)totalNums{
    return _aryPheral.count;
}
-(CDataPheralInfo*)dataWithIndex:(NSInteger)nIdx{
    return [_aryPheral objectAtIndex:nIdx];
}

-(NSMutableArray*)aryPheral{
    if ( _aryPheral == nil ){
        _aryPheral = [NSMutableArray array];
    }
    return _aryPheral;
}

-(void)removeAll{
    if ( _aryPheral != nil && _aryPheral.count > 0 ){
        [_aryPheral removeAllObjects];
    }
}


-(BOOL)addPheral:(CBPeripheral*)pheral advData:(NSDictionary *)advData RSSI:(NSNumber *)RSSI{
    CDataPheralInfo *data = [CDataPheralInfo dataPheral:pheral advData:advData RSSI:RSSI];
    return [self addPheral:data];
}


-(BOOL)addPheral:(CDataPheralInfo*)data{
    
    // 1、第一次扫描到的设备，添加进数组中
    if ( self.aryPheral.count == 0 ){
        [self.aryPheral addObject:data];
        
    } else {
        
        //2 - 遍历数组中的蓝牙模型，更新原有的数据（主要是更新信号强度）
        for (NSInteger i = 0; i < self.aryPheral.count; i++ ) {
            CDataPheralInfo *interData = [self.aryPheral objectAtIndex:i];
            if ( [data isSamePheral:interData.peripheral] ){
                [self.aryPheral replaceObjectAtIndex:i withObject:data];
                return NO;
            }
        }
        
        // 3 - 若未有包含过此设备，则将其添加进数组中
        if (![self.aryPheral containsObject:data]) {
            [self.aryPheral addObject:data];
        }
    }
    return YES;
}

@end
