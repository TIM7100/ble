//
//  CBLEMnger.m
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//

#import "CBLEDataParse.h"
#import "JCDataConvert.h"
#import "CBLEDataMsg.h"


static NSInteger stcBLELastCmd = 0;

#define IS_CMD_ACK_OK(nState)      ( 0x00 == nState )



@interface CBLEDataParse()
@end

@implementation CBLEDataParse
+(instancetype)dataParse{
    
    CBLEDataParse *parse = [[CBLEDataParse alloc] init];
    return parse;
}

-(instancetype)init{
    if ( self = [super init] ){
        _ackData = [[MsgDataWristAck alloc] init];
    }
    return self;
}


-(NSInteger)parseOTAAck:(CBCharacteristic*)chrtcs{
    NSData *data = chrtcs.value;
    if ( data == nil ) return 0 ;
    
    //NSString *strLog = [JCDataConvert dataToHexStringMac:data];
    //NSLog(@"-----OTA OTA ack log:%@\r\n",strLog);
    
    //获取第一个字节的数据
    NSUInteger respondType = 0;
    if (data.length>1) {
        //16进制转10进制
        respondType = [JCDataConvert twoBytesToDecimalUint:[data subdataWithRange:NSMakeRange(0, 2)]];
        stcBLELastCmd = respondType;
    } else if (data.length == 1) {
        //错误码 //16进制转10进制，
        NSUInteger respondType = [JCDataConvert oneByteToDecimalUint:[data subdataWithRange:NSMakeRange(0, 1)]];
        stcBLELastCmd = respondType;
    }
    
    _ackData.srcCmd = respondType;
    switch ( respondType ) {
        case OTA_RSP_START_OTA: [self parseOTACmdStartOTAAck:data]; break;
        case OTA_RSP_PARITION_COMPLETE: [self parseOTACmdPartitionCompleteAck:data];break;
        case OTA_RSP_BLOCK_COMPLETE:[self parseOTACmdBlockCompleteAck:data];break;
        case OTA_RSP_BLOCK_INFO: [self parseOTACmdBlockInfoAck:data]; break;
        case OTA_RSP_PARTITION_INFO: [self parseOTACmdPartitionInfoAck:data]; break;
            
        default: break;
    }
    stcBLELastCmd = 0;
    
    return respondType;
}

-(NSInteger)parseOTACmdStartOTAAck:(NSData*)data{
   
    //NSLog(@"ota模式下:0x0081 启动OTA返回成功......");
    return 0;
}

-(NSInteger)parseOTACmdPartitionInfoAck:(NSData*)data{
    
    //NSLog(@"ota模式下:0x0083 所有ota数据发送成功......");
    return 0;
}

-(NSInteger)parseOTACmdPartitionCompleteAck:(NSData*)data{
    
    //NSLog(@"ota模式下:0x0084OTA地址发送成功......");
    return 0;
}

-(NSInteger)parseOTACmdBlockCompleteAck:(NSData*)data{
    
    //NSLog(@"ota模式下:0x0087 一组16*20 ota数据发送成功开始下一组......");
    return 0;
}

-(NSInteger)parseOTACmdBlockInfoAck:(NSData*)data{
    
    //NSLog(@"ota模式下:0x85 一个partition 数据发送成功，发送下一个partition命令......");
    return 0;
}





-(NSInteger)parseAppOTAAck:(CBCharacteristic*)chrtcs{
    
    NSData *data = chrtcs.value;
    if ( data == nil ) return 0 ;
    
    NSString *strLog = [JCDataConvert dataToHexStringMac:data];
    NSLog(@"-----CMD OTA ack log:%@\r\n",strLog);
    
    NSUInteger ackType = [JCDataConvert oneByteToDecimalUint:
                          [data subdataWithRange:NSMakeRange(0, 1)]];
    
    switch (ackType) {
        case eBLEWristOTACmdVersionAck:[self parseOTACmdVersionAck:data];break;
            
        default:
            break;
    }
    
    return 0;
}
    

-(NSInteger)parseOTACmdVersionAck:(NSData*)data{
    //00:11:26:96:d8:12:fc:56:31:2e:31:2e:31:38:66:00:00:00:00:00
    if ( data.length < 20 ) return -1;
    
    Byte *bt = (Byte*)data.bytes;
    NSString *strMac = @"";
    for (NSInteger i = 0; i <6; i++) {
        NSString *str = [NSString stringWithFormat:@"%02X:",bt[6-i]];
        strMac = [strMac stringByAppendingString:str];
    }
    if ( [strMac hasSuffix:@":"])
        strMac = [strMac substringToIndex:(strMac.length - 1)];
    
    NSString *bootVer = [NSString stringWithUTF8String:(bt+7)];
    self.ackData.strMacAddr = strMac;
    self.ackData.strBootVer = bootVer;
    //NSLog(@" new mac address = %@---%@\r\n", strMac,bootVer);
    return 0;
}







-(NSInteger)parseCmdAck:(CBCharacteristic*)chrtcs{
    
    NSData *data = chrtcs.value;
    if ( data == nil ) return 0 ;
    
   // @autoreleasepool {
   //     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            //16进制转10进制
            NSUInteger ackType = [JCDataConvert oneByteToDecimalUint:
                                  [data subdataWithRange:NSMakeRange(0, 1)]];
            stcBLELastCmd   = ackType;
            _ackData.srcCmd = ackType;
            //NSString *strLog = [JCDataConvert dataToHexStringMac:data];
            //NSLog(@"-----respondType----sys ble info = %@\r\n",strLog);
            
            switch (ackType) {
                //case eBLEWristCmdVerInfo: [self parseCmdAckVerInfo:data];break;
                case eBLEWristCmdConfig:  [self parseCmdAckConfig:data]; break;
                case eBLEWristHRStart:    [self parseCmdAckHRStart:data]; break;
                case eBLEWristHRStop:     [self parseCmdAckHRStop:data]; break;
                case eBLEWristAccStart:   [self parseCmdAckAccStart:data]; break;
                case eBLEWristAccStop:    [self parseCmdAckAccStop:data]; break;
                case eBLEWristSetLED:     [self parseCmdAckSetLED:data]; break;
                case eBLEWristSendMsg:    [self parseCmdAckSendMsg:data]; break;
                case eBLEWristHRLast:     [self parseCmdAckHRLast:data]; break;
                case eBLEWristHRRaw:      [self parseCmdAckHRRaw:data]; break;
                case eBLEWristACCRaw:     [self parseCmdAckAccRaw:data]; break;
                default:break;
            }
        //});
    //}
    return ackType;
}


-(NSInteger)checkCmdAckState:(NSData*)readData{
    
    NSData *dataAck     = [readData subdataWithRange:NSMakeRange(2, 1)];
    NSUInteger ackState = [JCDataConvert oneByteToDecimalUint:dataAck];
    return ackState;
}


-(NSString*)parseMacAddr:(CBCharacteristic*)chrtcs{
    
    NSString*value = [NSString stringWithFormat:@"%@",chrtcs.value];
    NSMutableString*macString = [[NSMutableString alloc]init];
    [macString appendString:[[value substringWithRange:NSMakeRange(16,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(14,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(12,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(5,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(3,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(1,2)]uppercaseString]];
    return [NSString stringWithFormat:@"%@",macString];
#if 0
    //self.originalMacAddress = value;
    //NSString *uuid = _currentPeripheral.identifier.UUIDString;
    NSDictionary *classDic = @{
                               @"macAddress"     : macString,
                               @"originalMacAddr": value,
                               @"originalUUID"   : uuid
                               };
#endif
}

-(void)parseCmdAckConfig:(NSData*)data{
    
    if( eBLEWristCmdConfig != stcBLELastCmd ){
        NSLog(@"--->set config command has been update!");
        return;
    }

    NSInteger nState = [self checkCmdAckState:data];
    if ( IS_CMD_ACK_OK(nState)){
        NSLog(@"  ---------->set config cmd is success!");
    } else {
        NSLog(@"  xxxxxxxxxx>set config cmd is error[]!");
    }
    stcBLELastCmd = 0;
}

-(void)parseCmdAckHRStart:(NSData*)data{
    
    if( eBLEWristHRStart != stcBLELastCmd ){
        NSLog(@"------>heart rate start command has been update!");
        return;
    }
    
    NSInteger nState = [self checkCmdAckState:data];
    if ( IS_CMD_ACK_OK(nState)){
        NSLog(@"  ---------->heart rate start cmd is success!");
    } else {
        NSLog(@"  xxxxxxxxxx>heart rate start cmd is error[%ld]!",nState);
    }
    stcBLELastCmd = 0;
}

-(void)parseCmdAckHRStop:(NSData*)data{
    
    if( eBLEWristHRStop != stcBLELastCmd ){
        NSLog(@"------>heart rate stop command has been update!");
        return;
    }
    
    NSInteger nState = [self checkCmdAckState:data];
    if ( IS_CMD_ACK_OK(nState)){
        NSLog(@"  ---------->heart rate stop cmd is success!");
    } else {
        NSLog(@"  xxxxxxxxxx>heart rate stop cmd is error!");
    }
    stcBLELastCmd = 0;
}

-(void)parseCmdAckAccStart:(NSData*)data{
    
    if( eBLEWristAccStart != stcBLELastCmd ){
        NSLog(@"------>acc start command has been update!");
        return;
    }
    
    NSInteger nState = [self checkCmdAckState:data];
    if ( IS_CMD_ACK_OK(nState)){
        NSLog(@"  ---------->acc start cmd is success!");
    } else {
        NSLog(@"  xxxxxxxxxx>acc start cmd is error!");
    }
    stcBLELastCmd = 0;
}

-(void)parseCmdAckAccStop:(NSData*)data{
    
    if( eBLEWristAccStart != stcBLELastCmd ){
        NSLog(@"------>acc stop command has been update!");
        return;
    }
    
    NSInteger nState = [self checkCmdAckState:data];
    if ( IS_CMD_ACK_OK(nState)){
        NSLog(@"  ---------->acc stop cmd is success!");
    } else {
        NSLog(@"  xxxxxxxxxx>acc stop cmd is error!");
    }
    stcBLELastCmd = 0;
}

-(void)parseCmdAckSetLED:(NSData*)data{
    
    if( eBLEWristSetLED != stcBLELastCmd ){
        NSLog(@"------>set led command has been update!");
        return;
    }
    
    NSInteger nState = [self checkCmdAckState:data];
    if ( IS_CMD_ACK_OK(nState)){
        NSLog(@"  ---------->set led cmd is success!");
    } else {
        NSLog(@"  xxxxxxxxxx>set led cmd is error!");
    }
    stcBLELastCmd = 0;
}

-(void)parseCmdAckSendMsg:(NSData*)data{
    
    _ackData.msgAck = 0;
    if ( stcBLELastCmd != eBLEWristSendMsg ){
        NSLog(@"   --->发送消息命令已经被更新......");
        return;
    }
    
    NSData *ackData = [data subdataWithRange:NSMakeRange(2, 1)];
    _ackData.msgAck = [JCDataConvert oneByteToDecimalUint:ackData];
    NSLog(@"   --->send msg data[%ld] update......",_ackData.msgAck);
    stcBLELastCmd = 0;
}

-(void)parseCmdAckHRLast:(NSData*)data{
    
    if ( stcBLELastCmd != eBLEWristHRLast ){
        NSLog(@"   --->命令已经被更新......");
        return;
    }
   
    NSData *heartRateLastValue = [data subdataWithRange:NSMakeRange(2, 1)];
    _ackData.HRLastValue = [JCDataConvert oneByteToDecimalUint:heartRateLastValue];
     NSLog(@"   --->Heart rate last data[%ld] update......",_ackData.HRLastValue);
    POST_MSG_WITHOBJ(BLEMSG_PHERAL_HR_LAST, _ackData);
    stcBLELastCmd = 0;
    
}
-(void)parseCmdAckHRRaw:(NSData*)data{
    
    if ( stcBLELastCmd != eBLEWristHRRaw ){
        NSLog(@"   --->命令已经被更新......");
        return;
    }
    
    //NSLog(@"   --->Heart rate raw data update......");
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0;i<16;i++) {
        NSData *heartRateLastValue = [data subdataWithRange:NSMakeRange(i+2, 1)];
        [arr addObject:heartRateLastValue];
    }
    _ackData.HRRawDataArr = arr;
    POST_MSG_WITHOBJ(BLEMSG_PHERAL_HR_RAW, _ackData);
    
    stcBLELastCmd = 0;
}
-(void)parseCmdAckAccRaw:(NSData*)data{
    
    if ( stcBLELastCmd != eBLEWristACCRaw ){
        NSLog(@"   --->命令已经被更新......");
        return;
    }
    
    if ( data.length < 15 ){
        NSLog(@"   --->加速度返回数据异常[%ld != 15]......", data.length );
        return;
    }
    
    NSData *XValue = [data subdataWithRange:NSMakeRange(2, 4)];
    int XIntValue  = [JCDataConvert dataToInt4:XValue];
    
    NSData *YValue = [data subdataWithRange:NSMakeRange(6, 4)];
    int ZIntValue  = [JCDataConvert dataToInt4:YValue];
    
    NSData *ZValue = [data subdataWithRange:NSMakeRange(10, 4)];
    int YIntValue = [JCDataConvert dataToInt4:ZValue];
    
    _ackData.X = XIntValue;
    _ackData.Y = YIntValue;
    _ackData.Z = ZIntValue;
    stcBLELastCmd = 0;
}

    
#if 0

                        
                        //LED灯的设定结果获得
                    case 0x30:{
                        if (EXECUTE_COMMAND != 0x30) {
                            break;
                        }
                        NSData *LEDResult = [data subdataWithRange:NSMakeRange(2, 1)];
                        NSUInteger result = [JCDataConvert oneByteToDecimalUint:LEDResult];
                        NSLog(@"LED灯设定返回的结果：%lu",(unsigned long)result);
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //推送消息
                    case 0x38:{
                        if (EXECUTE_COMMAND != 0x38) {
                            break;
                        }
                        NSData *sendMessage = [data subdataWithRange:NSMakeRange(2, 1)];
                        NSUInteger result = [JCDataConvert oneByteToDecimalUint:sendMessage];
                        NSLog(@"推送消息返回的结果：%lu",(unsigned long)result);
                        EXECUTE_COMMAND = 0;
                        
                        if (self.messageList.count > 0) {
                            [self.messageList removeObjectAtIndex:0];
                        }
                        
                        if (result == 0) {
                            if (self.messageList.count > 0) {
                                [self.messageList removeAllObjects];
                            }
                            self.commandDateStr = nil;
                        } else if (result == 1) {
                            if (self.messageList.count >1) {
                                self.commandDateStr = [self getCommandDateStr:3];
                                [self sendDataUseCommand:SEND_MESSAGE dataStr:self.commandDateStr];
                            } else if (self.messageList.count == 1) {
                                self.commandDateStr = [self getCommandDateStr:2];
                                [self sendDataUseCommand:SEND_MESSAGE dataStr:self.commandDateStr];
                            }
                        }
                    }
                        break;
                        
                        //获取心率数据最后的测量值
                    case 0x81:{
                        if (EXECUTE_COMMAND != 0x81) {
                            break;
                        }
                        NSData *heartRateLastValue = [data subdataWithRange:NSMakeRange(2, 1)];
                        NSUInteger heartRateLastIntValue = [JCDataConvert oneByteToDecimalUint:heartRateLastValue];
                        HeartRateModel *heartRateModel = [[HeartRateModel alloc] init];
                        heartRateModel.heartRateLastValue = heartRateLastIntValue;
                        if ([self.delegate respondsToSelector:@selector(updateHeartRateback:feedBackInfo:)]) {
                            [self.delegate updateHeartRateback:self feedBackInfo:heartRateModel];
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //获取心率原始数据
                    case 0x85:{
                        if (EXECUTE_COMMAND != 0x85) {
                            break;
                        }
                        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:0];
                        for (int i = 0;i<16;i++) {
                            NSData *heartRateLastValue = [data subdataWithRange:NSMakeRange(i+2, 1)];
                            [arr addObject:heartRateLastValue];
                        }
                        HeartRateModel *heartRateModel = [[HeartRateModel alloc] init];
                        heartRateModel.heartRateOriginalDataArr = arr;
                        if ([self.delegate respondsToSelector:@selector(updateHeartRateOriginalDataback:feedBackInfo:)]) {
                            [self.delegate updateHeartRateOriginalDataback:self feedBackInfo:heartRateModel];
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //获取加速度传感器原始数据
                    case 0x86:{
                        if (EXECUTE_COMMAND != 0x86) {
                            break;
                        }
                        NSData *acceleratedXValue = [data subdataWithRange:NSMakeRange(2, 4)];
                        int acceleratedXIntValue = [JCDataConvert dataToInt4:acceleratedXValue];
                        
                        NSData *acceleratedYValue = [data subdataWithRange:NSMakeRange(6, 4)];
                        int acceleratedZIntValue = [JCDataConvert dataToInt4:acceleratedYValue];
                        
                        NSData *acceleratedZValue = [data subdataWithRange:NSMakeRange(10, 4)];
                        int acceleratedYIntValue = [JCDataConvert dataToInt4:acceleratedZValue];
                        
                        AcceleratedSensorModel *acceleratedSensorModel = [[AcceleratedSensorModel alloc] init];
                        acceleratedSensorModel.acceleratedXValue = acceleratedXIntValue;
                        acceleratedSensorModel.acceleratedYValue = acceleratedYIntValue;
                        acceleratedSensorModel.acceleratedZValue = acceleratedZIntValue;
                        
                        if ([self.delegate respondsToSelector:@selector(updateAcceleratedSensorDataback:feedBackInfo:)]) {
                            [self.delegate updateAcceleratedSensorDataback:self feedBackInfo:acceleratedSensorModel];
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                    default:
                        break;
                }
#endif



#if 0

//获取MAC地址

if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_OTA_INDICATE_UUID]]){
    if (characteristic.value) {
        NSData *data = characteristic.value;
        //NSLog(@"ota服务特征值(读取到的)data: %@", characteristic);
        @autoreleasepool {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                //获取第一个字节的数据
                NSUInteger respondType = 0;
                if (data.length>1) {
                    respondType = [JCDataConvert twoBytesToDecimalUint:[data subdataWithRange:NSMakeRange(0, 2)]];//16进制转10进制，
                    EXECUTE_COMMAND = respondType;
                } else if (data.length == 1) {
                    //错误码
                    NSUInteger respondType = [JCDataConvert oneByteToDecimalUint:[data subdataWithRange:NSMakeRange(0, 1)]];//16进制转10进制，
                    EXECUTE_COMMAND = respondType;
                }
                NSLog(@" OTA Response = %04X\r\n",respondType);
                switch (respondType) {
                        //设置设备 OTA 状态//启动OTA模式，可以搜到OTA信号
                    case 0x0081:{
                        if (EXECUTE_COMMAND != 0x0081) {
                            break;
                        }
                        NSLog(@"ota模式下启动OTA返回成功：%@",[JCDataConvert ToHex:respondType]);
                        Partition *partition = self.fileManager.list[self.partitionIndex];
                        int checsum =[self getPartitionCheckSum:partition];
                        NSString *cmd = [self make_part_cmd:self.partitionIndex flash_addr:self.flash_addr run_addr:partition.address size:partition.partitionLength checksum:checsum];
                        if (self->_currentPeripheral) {
                            self.isOTACmdWithResponse = YES;
                            self.isOTACmd = YES;
                            [self->_commandBuffer addObject:[JCDataConvert hexToBytes:cmd]];
                        }
                        
                        self.blockIndex = 0;
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //OTA地址发送成功
                    case 0x0084:{
                        if (EXECUTE_COMMAND != 0x0084) {
                            break;
                        }
                        EXECUTE_COMMAND = 0;
                        NSLog(@"ota地址正确：%@",[JCDataConvert ToHex:respondType]);
                        self.cmdIndex = 0;
                        Partition *partition = self.fileManager.list[self.partitionIndex];
                        NSArray *partitionArray = partition.partitionArray;
                        if (self->_currentPeripheral) {
                            while (self.blockIndex < partitionArray.count) {
                                if(self.errorTimes > 0){
                                    self.errorTimes = 0;
                                }
                                if(self.blockIndex < partitionArray.count){
                                    NSInteger cmdIndex = 0;
                                    NSArray *cmdList = partitionArray[self.blockIndex];
                                    NSLog(@"下标%d,partitionArray个数%lu",self.blockIndex,(unsigned long)partitionArray.count);
                                    cmdIndex = 0;
                                    while (cmdIndex < cmdList.count) {
                                        
                                        if(self.errorTimes > 0){
                                            self.errorTimes = 0;
                                        }
                                        
                                        if(cmdIndex < cmdList.count){
                                            self.isOTACmdWithResponse = NO;
                                            self.isOTACmd = YES;
                                            [self->_commandBuffer addObject:[JCDataConvert hexToBytes:cmdList[cmdIndex]]];
                                        }
                                        cmdIndex ++;
                                    }
                                }
                                self.blockIndex ++;
                            }
                        }
                    }
                        break;
                        
                        //0087  一组16*20 ota数据发送成功，开始下一组
                    case 0x0087:{
                        if (EXECUTE_COMMAND != 0x0087) {
                            break;
                        }
                        NSLog(@"一组数据发送成功：%@",[JCDataConvert ToHex:respondType]);
                        Partition *partition = self.fileManager.list[self.partitionIndex];
                        NSArray *partitionArray = partition.partitionArray;
                        if (self->_currentPeripheral) {
                            while (self.blockIndex < partitionArray.count) {
                                if(self.errorTimes > 0){
                                    self.errorTimes = 0;
                                }
                                if(self.blockIndex < partitionArray.count){
                                    NSInteger cmdIndex = 0;
                                    NSArray *cmdList = partitionArray[self.blockIndex];
                                    NSLog(@"下标%d,partitionArray个数%lu",self.blockIndex,(unsigned long)partitionArray.count);
                                    
                                    while (cmdIndex < cmdList.count) {
                                        if(self.errorTimes > 0){
                                            self.errorTimes = 0;
                                        }
                                        if(cmdIndex < cmdList.count){
                                            self.isOTACmdWithResponse = NO;
                                            self.isOTACmd = YES;
                                            [self->_commandBuffer addObject:[JCDataConvert hexToBytes:cmdList[cmdIndex]]];
                                        }
                                        cmdIndex ++;
                                    }
                                }
                                self.blockIndex ++;
                            }
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //0085  一个partition 数据发送成功，发送下一个partition命令
                    case 0x0085:{
                        if (EXECUTE_COMMAND != 0x0085) {
                            break;
                        }
                        //                            [self->_commandBuffer removeAllObjects];
                        NSLog(@"一组partition发送成功：%@",[JCDataConvert ToHex:respondType]);
                        self.partitionIndex++;
                        self.blockIndex = 0;
                        if(self.partitionIndex < self.fileManager.list.count){
                            //后面地址由前一个长度决定
                            Partition *prePartition = self.fileManager.list[self.partitionIndex-1];
                            self.flash_addr = self.flash_addr + prePartition.partitionLength + 16 - (prePartition.partitionLength+4)%4;
                            Partition *partition = self.fileManager.list[self.partitionIndex];
                            int checsum =[self getPartitionCheckSum:partition];
                            NSString *cmd = [self make_part_cmd:self.partitionIndex flash_addr:self.flash_addr run_addr:partition.address size:partition.partitionLength checksum:checsum];
                            self.isOTACmdWithResponse = YES;
                            self.isOTACmd = YES;
                            if (self->_currentPeripheral) {
                                [self->_commandBuffer addObject:[JCDataConvert hexToBytes:cmd]];
                            }
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //0083 所有ota数据发送成功
                    case 0x0083:{
                        if (EXECUTE_COMMAND != 0x0083) {
                            break;
                        }
                        self.isOTACmdWithResponse = YES;
                        self.isOTACmd = YES;
                        NSLog(@"发送数据成功：%@",[JCDataConvert ToHex:respondType]);
                        if ([self.delegate respondsToSelector:@selector(updateOTAProgressDataback:isComplete:)]) {
                            [self.delegate updateOTAProgressDataback:self isComplete:true];
                        }
                        [self onOTAFinish];
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //68 PPlus_ERR_OTA_DATA
                    case 0x68:{
                        if (EXECUTE_COMMAND != 0x68) {
                            break;
                        }
                        if(!self.isCancle){
                            if(self.errorTimes < self.retryTimes){
                                Partition *partition = self.fileManager.list[self.partitionIndex];
                                NSArray *partitionArray = partition.partitionArray;
                                
                                NSArray *cmdList;
                                if (self.blockIndex<1) {
                                    //                                        cmdList = partitionArray[0];
                                    break;
                                } else {
                                    cmdList = partitionArray[self.blockIndex-1];
                                }
                                
                                //                                    NSLog(@"下标%d,partitionArray个数%lu",self.blockIndex-1,(unsigned long)partitionArray.count);
                                NSInteger cmdIndex = 0;
                                while (cmdIndex < cmdList.count) {
                                    if(cmdIndex < cmdList.count){
                                        NSLog(@"cmdIndex:%ld",(long)cmdIndex);
                                        self.isOTACmdWithResponse = NO;
                                        self.isOTACmd = YES;
                                        [self->_commandBuffer addObject:[JCDataConvert hexToBytes:cmdList[cmdIndex]]];
                                    }else{
                                        
                                    }
                                    cmdIndex ++;
                                }
                                self.errorTimes++;
                            }
                            else{
                                //通知报错，发送没一段的信息错误
                                if ([self.delegate respondsToSelector:@selector(updateOTAErrorCallBack:errorCode:)]) {
                                    [self.delegate updateOTAErrorCallBack:self errorCode:EXECUTE_COMMAND];
                                }
                            }
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                    default: {
                        //其他错误码，报错
                        if ([self.delegate respondsToSelector:@selector(updateOTAErrorCallBack:errorCode:)]) {
                            [self.delegate updateOTAErrorCallBack:self errorCode:EXECUTE_COMMAND];
                        }
                    }
                        break;
                }
            });
        }
    }else{
        NSLog(@"未发现特征值.");
    }
}

if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_WRITE_UUID]]){
    
                
            });
        }
    }else{
        NSLog(@"未发现特征值.");
    }
}
//获取电量
if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_BATTERY_READ_UUID]]) {
    NSData *data = characteristic.value;
    NSInteger value = [JCDataConvert ToInteger:data];
    NSDictionary *classDic = @{
                               @"batteryLeve" : data
                               };
    [NotificationCenter postNotificationName:BluetoothGetBatteryLeve object:nil userInfo:classDic];
    NSLog(@"characteristic(读取到的) : %@, data : %@, \n\n电量为value : %ld%%", characteristic, data, (long)value);
}

//获取MAC地址
if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_MAC_READ_UUID]]){
    NSString*value = [NSString stringWithFormat:@"%@",characteristic.value];
    NSMutableString*macString = [[NSMutableString alloc]init];
    [macString appendString:[[value substringWithRange:NSMakeRange(16,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(14,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(12,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(5,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(3,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(1,2)]uppercaseString]];
    self.originalMacAddress = value;
    NSString *uuid = _currentPeripheral.identifier.UUIDString;
    NSDictionary *classDic = @{
                               @"macAddress" : macString,@"originalMacAddress":value,@"originalUUID":uuid
                               };
    [NotificationCenter postNotificationName:BluetoothGetMacAddress object:nil userInfo:classDic];
    NSLog(@"mac(读取到的)data : %@, \n\n------------mac地址为value : %@", characteristic, macString);
}

if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_OTA_INDICATE_UUID]]){
    if (characteristic.value) {
        NSData *data = characteristic.value;
        //NSLog(@"ota服务特征值(读取到的)data: %@", characteristic);
        @autoreleasepool {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                //获取第一个字节的数据
                NSUInteger respondType = 0;
                if (data.length>1) {
                    respondType = [JCDataConvert twoBytesToDecimalUint:[data subdataWithRange:NSMakeRange(0, 2)]];//16进制转10进制，
                    EXECUTE_COMMAND = respondType;
                } else if (data.length == 1) {
                    //错误码
                    NSUInteger respondType = [JCDataConvert oneByteToDecimalUint:[data subdataWithRange:NSMakeRange(0, 1)]];//16进制转10进制，
                    EXECUTE_COMMAND = respondType;
                }
                NSLog(@" OTA Response = %04X\r\n",respondType);
                switch (respondType) {
                        //设置设备 OTA 状态//启动OTA模式，可以搜到OTA信号
                    case 0x0081:{
                        if (EXECUTE_COMMAND != 0x0081) {
                            break;
                        }
                        NSLog(@"ota模式下启动OTA返回成功：%@",[JCDataConvert ToHex:respondType]);
                        Partition *partition = self.fileManager.list[self.partitionIndex];
                        int checsum =[self getPartitionCheckSum:partition];
                        NSString *cmd = [self make_part_cmd:self.partitionIndex flash_addr:self.flash_addr run_addr:partition.address size:partition.partitionLength checksum:checsum];
                        if (self->_currentPeripheral) {
                            self.isOTACmdWithResponse = YES;
                            self.isOTACmd = YES;
                            [self->_commandBuffer addObject:[JCDataConvert hexToBytes:cmd]];
                        }
                        
                        self.blockIndex = 0;
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //OTA地址发送成功
                    case 0x0084:{
                        if (EXECUTE_COMMAND != 0x0084) {
                            break;
                        }
                        EXECUTE_COMMAND = 0;
                        NSLog(@"ota地址正确：%@",[JCDataConvert ToHex:respondType]);
                        self.cmdIndex = 0;
                        Partition *partition = self.fileManager.list[self.partitionIndex];
                        NSArray *partitionArray = partition.partitionArray;
                        if (self->_currentPeripheral) {
                            while (self.blockIndex < partitionArray.count) {
                                if(self.errorTimes > 0){
                                    self.errorTimes = 0;
                                }
                                if(self.blockIndex < partitionArray.count){
                                    NSInteger cmdIndex = 0;
                                    NSArray *cmdList = partitionArray[self.blockIndex];
                                    NSLog(@"下标%d,partitionArray个数%lu",self.blockIndex,(unsigned long)partitionArray.count);
                                    cmdIndex = 0;
                                    while (cmdIndex < cmdList.count) {
                                        
                                        if(self.errorTimes > 0){
                                            self.errorTimes = 0;
                                        }
                                        
                                        if(cmdIndex < cmdList.count){
                                            self.isOTACmdWithResponse = NO;
                                            self.isOTACmd = YES;
                                            [self->_commandBuffer addObject:[JCDataConvert hexToBytes:cmdList[cmdIndex]]];
                                        }
                                        cmdIndex ++;
                                    }
                                }
                                self.blockIndex ++;
                            }
                        }
                    }
                        break;
                        
                        //0087  一组16*20 ota数据发送成功，开始下一组
                    case 0x0087:{
                        if (EXECUTE_COMMAND != 0x0087) {
                            break;
                        }
                        NSLog(@"一组数据发送成功：%@",[JCDataConvert ToHex:respondType]);
                        Partition *partition = self.fileManager.list[self.partitionIndex];
                        NSArray *partitionArray = partition.partitionArray;
                        if (self->_currentPeripheral) {
                            while (self.blockIndex < partitionArray.count) {
                                if(self.errorTimes > 0){
                                    self.errorTimes = 0;
                                }
                                if(self.blockIndex < partitionArray.count){
                                    NSInteger cmdIndex = 0;
                                    NSArray *cmdList = partitionArray[self.blockIndex];
                                    NSLog(@"下标%d,partitionArray个数%lu",self.blockIndex,(unsigned long)partitionArray.count);
                                    
                                    while (cmdIndex < cmdList.count) {
                                        if(self.errorTimes > 0){
                                            self.errorTimes = 0;
                                        }
                                        if(cmdIndex < cmdList.count){
                                            self.isOTACmdWithResponse = NO;
                                            self.isOTACmd = YES;
                                            [self->_commandBuffer addObject:[JCDataConvert hexToBytes:cmdList[cmdIndex]]];
                                        }
                                        cmdIndex ++;
                                    }
                                }
                                self.blockIndex ++;
                            }
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //0085  一个partition 数据发送成功，发送下一个partition命令
                    case 0x0085:{
                        if (EXECUTE_COMMAND != 0x0085) {
                            break;
                        }
                        //                            [self->_commandBuffer removeAllObjects];
                        NSLog(@"一组partition发送成功：%@",[JCDataConvert ToHex:respondType]);
                        self.partitionIndex++;
                        self.blockIndex = 0;
                        if(self.partitionIndex < self.fileManager.list.count){
                            //后面地址由前一个长度决定
                            Partition *prePartition = self.fileManager.list[self.partitionIndex-1];
                            self.flash_addr = self.flash_addr + prePartition.partitionLength + 16 - (prePartition.partitionLength+4)%4;
                            Partition *partition = self.fileManager.list[self.partitionIndex];
                            int checsum =[self getPartitionCheckSum:partition];
                            NSString *cmd = [self make_part_cmd:self.partitionIndex flash_addr:self.flash_addr run_addr:partition.address size:partition.partitionLength checksum:checsum];
                            self.isOTACmdWithResponse = YES;
                            self.isOTACmd = YES;
                            if (self->_currentPeripheral) {
                                [self->_commandBuffer addObject:[JCDataConvert hexToBytes:cmd]];
                            }
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //0083 所有ota数据发送成功
                    case 0x0083:{
                        if (EXECUTE_COMMAND != 0x0083) {
                            break;
                        }
                        self.isOTACmdWithResponse = YES;
                        self.isOTACmd = YES;
                        NSLog(@"发送数据成功：%@",[JCDataConvert ToHex:respondType]);
                        if ([self.delegate respondsToSelector:@selector(updateOTAProgressDataback:isComplete:)]) {
                            [self.delegate updateOTAProgressDataback:self isComplete:true];
                        }
                        [self onOTAFinish];
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //68 PPlus_ERR_OTA_DATA
                    case 0x68:{
                        if (EXECUTE_COMMAND != 0x68) {
                            break;
                        }
                        if(!self.isCancle){
                            if(self.errorTimes < self.retryTimes){
                                Partition *partition = self.fileManager.list[self.partitionIndex];
                                NSArray *partitionArray = partition.partitionArray;
                                
                                NSArray *cmdList;
                                if (self.blockIndex<1) {
                                    //                                        cmdList = partitionArray[0];
                                    break;
                                } else {
                                    cmdList = partitionArray[self.blockIndex-1];
                                }
                                
                                //                                    NSLog(@"下标%d,partitionArray个数%lu",self.blockIndex-1,(unsigned long)partitionArray.count);
                                NSInteger cmdIndex = 0;
                                while (cmdIndex < cmdList.count) {
                                    if(cmdIndex < cmdList.count){
                                        NSLog(@"cmdIndex:%ld",(long)cmdIndex);
                                        self.isOTACmdWithResponse = NO;
                                        self.isOTACmd = YES;
                                        [self->_commandBuffer addObject:[JCDataConvert hexToBytes:cmdList[cmdIndex]]];
                                    }else{
                                        
                                    }
                                    cmdIndex ++;
                                }
                                self.errorTimes++;
                            }
                            else{
                                //通知报错，发送没一段的信息错误
                                if ([self.delegate respondsToSelector:@selector(updateOTAErrorCallBack:errorCode:)]) {
                                    [self.delegate updateOTAErrorCallBack:self errorCode:EXECUTE_COMMAND];
                                }
                            }
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                    default: {
                        //其他错误码，报错
                        if ([self.delegate respondsToSelector:@selector(updateOTAErrorCallBack:errorCode:)]) {
                            [self.delegate updateOTAErrorCallBack:self errorCode:EXECUTE_COMMAND];
                        }
                    }
                        break;
                }
            });
        }
    }else{
        NSLog(@"未发现特征值.");
    }
}

if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_WRITE_UUID]]){
    if (characteristic.value) {
        NSData *data = characteristic.value;
        //开线程处理传输回来的数据
        @autoreleasepool {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                //获取第一个字节的数据
                NSUInteger respondType = [JCDataConvert oneByteToDecimalUint:[data subdataWithRange:NSMakeRange(0, 1)]];//16进制转10进制，
                EXECUTE_COMMAND = respondType;
                
                NSString *strLog = [JCDataConvert dataToHexStringMac:data];
                NSLog(@"-----respondType----sys ble info = %@\r\n",strLog);
                switch (respondType) {
                    case 0x01:{
                        NSInteger nLen = data.length;
                        // 2
                        // 3 手环固件版本
                        // 2 蓝牙协议栈版本
                        // 2 Wrist通信协议版本
                        // 2 硬件版本
                    }break;
                        //更新系统时间
                    case 0x02:{
                        if (EXECUTE_COMMAND != 0x02) {
                            break;
                        }
                        NSData *startHeartRate = [data subdataWithRange:NSMakeRange(2, 1)];
                        NSUInteger result = [JCDataConvert oneByteToDecimalUint:startHeartRate];
                        NSLog(@"更新系统时间返回的结果：%lu",(unsigned long)result);
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        //启动血压检测
                    case 0x21:{
                        if (EXECUTE_COMMAND != 0x21) {
                            break;
                        }
                        NSData *startHeartRate = [data subdataWithRange:NSMakeRange(2, 1)];
                        NSUInteger result = [JCDataConvert oneByteToDecimalUint:startHeartRate];
                        NSLog(@"启动血压检测返回的结果：%lu",(unsigned long)result);
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //停止血压检测
                    case 0x22:{
                        if (EXECUTE_COMMAND != 0x22) {
                            break;
                        }
                        NSData *stopHeartRate = [data subdataWithRange:NSMakeRange(2, 1)];
                        NSUInteger result = [JCDataConvert oneByteToDecimalUint:stopHeartRate];
                        NSLog(@"启动血压检测返回的结果：%lu",(unsigned long)result);
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //启动加速传感器
                    case 0x23:{
                        if (EXECUTE_COMMAND != 0x23) {
                            break;
                        }
                        NSData *startGsensorResult = [data subdataWithRange:NSMakeRange(2, 1)];
                        NSUInteger result = [JCDataConvert oneByteToDecimalUint:startGsensorResult];
                        NSLog(@"启动加速传感器返回的结果：%lu",(unsigned long)result);
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //停止加速传感器
                    case 0x24:{
                        if (EXECUTE_COMMAND != 0x24) {
                            break;
                        }
                        NSData *stopGsensorResult = [data subdataWithRange:NSMakeRange(2, 1)];
                        NSUInteger result = [JCDataConvert oneByteToDecimalUint:stopGsensorResult];
                        NSLog(@"停止加速传感器返回的结果：%lu",(unsigned long)result);
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //LED灯的设定结果获得
                    case 0x30:{
                        if (EXECUTE_COMMAND != 0x30) {
                            break;
                        }
                        NSData *LEDResult = [data subdataWithRange:NSMakeRange(2, 1)];
                        NSUInteger result = [JCDataConvert oneByteToDecimalUint:LEDResult];
                        NSLog(@"LED灯设定返回的结果：%lu",(unsigned long)result);
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //推送消息
                    case 0x38:{
                        if (EXECUTE_COMMAND != 0x38) {
                            break;
                        }
                        NSData *sendMessage = [data subdataWithRange:NSMakeRange(2, 1)];
                        NSUInteger result = [JCDataConvert oneByteToDecimalUint:sendMessage];
                        NSLog(@"推送消息返回的结果：%lu",(unsigned long)result);
                        EXECUTE_COMMAND = 0;
                        
                        if (self.messageList.count > 0) {
                            [self.messageList removeObjectAtIndex:0];
                        }
                        
                        if (result == 0) {
                            if (self.messageList.count > 0) {
                                [self.messageList removeAllObjects];
                            }
                            self.commandDateStr = nil;
                        } else if (result == 1) {
                            if (self.messageList.count >1) {
                                self.commandDateStr = [self getCommandDateStr:3];
                                [self sendDataUseCommand:SEND_MESSAGE dataStr:self.commandDateStr];
                            } else if (self.messageList.count == 1) {
                                self.commandDateStr = [self getCommandDateStr:2];
                                [self sendDataUseCommand:SEND_MESSAGE dataStr:self.commandDateStr];
                            }
                        }
                    }
                        break;
                        
                        //获取心率数据最后的测量值
                    case 0x81:{
                        if (EXECUTE_COMMAND != 0x81) {
                            break;
                        }
                        NSData *heartRateLastValue = [data subdataWithRange:NSMakeRange(2, 1)];
                        NSUInteger heartRateLastIntValue = [JCDataConvert oneByteToDecimalUint:heartRateLastValue];
                        HeartRateModel *heartRateModel = [[HeartRateModel alloc] init];
                        heartRateModel.heartRateLastValue = heartRateLastIntValue;
                        if ([self.delegate respondsToSelector:@selector(updateHeartRateback:feedBackInfo:)]) {
                            [self.delegate updateHeartRateback:self feedBackInfo:heartRateModel];
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //获取心率原始数据
                    case 0x85:{
                        if (EXECUTE_COMMAND != 0x85) {
                            break;
                        }
                        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:0];
                        for (int i = 0;i<16;i++) {
                            NSData *heartRateLastValue = [data subdataWithRange:NSMakeRange(i+2, 1)];
                            [arr addObject:heartRateLastValue];
                        }
                        HeartRateModel *heartRateModel = [[HeartRateModel alloc] init];
                        heartRateModel.heartRateOriginalDataArr = arr;
                        if ([self.delegate respondsToSelector:@selector(updateHeartRateOriginalDataback:feedBackInfo:)]) {
                            [self.delegate updateHeartRateOriginalDataback:self feedBackInfo:heartRateModel];
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                        //获取加速度传感器原始数据
                    case 0x86:{
                        if (EXECUTE_COMMAND != 0x86) {
                            break;
                        }
                        NSData *acceleratedXValue = [data subdataWithRange:NSMakeRange(2, 4)];
                        int acceleratedXIntValue = [JCDataConvert dataToInt4:acceleratedXValue];
                        
                        NSData *acceleratedYValue = [data subdataWithRange:NSMakeRange(6, 4)];
                        int acceleratedZIntValue = [JCDataConvert dataToInt4:acceleratedYValue];
                        
                        NSData *acceleratedZValue = [data subdataWithRange:NSMakeRange(10, 4)];
                        int acceleratedYIntValue = [JCDataConvert dataToInt4:acceleratedZValue];
                        
                        AcceleratedSensorModel *acceleratedSensorModel = [[AcceleratedSensorModel alloc] init];
                        acceleratedSensorModel.acceleratedXValue = acceleratedXIntValue;
                        acceleratedSensorModel.acceleratedYValue = acceleratedYIntValue;
                        acceleratedSensorModel.acceleratedZValue = acceleratedZIntValue;
                        
                        if ([self.delegate respondsToSelector:@selector(updateAcceleratedSensorDataback:feedBackInfo:)]) {
                            [self.delegate updateAcceleratedSensorDataback:self feedBackInfo:acceleratedSensorModel];
                        }
                        EXECUTE_COMMAND = 0;
                    }
                        break;
                        
                    default:
                        break;
                }
                
            });
        }
    }else{
        NSLog(@"未发现特征值.");
    }
}
#endif
@end
