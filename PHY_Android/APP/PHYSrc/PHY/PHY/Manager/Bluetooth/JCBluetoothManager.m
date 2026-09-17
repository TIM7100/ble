//
//  JCBluetoothManager.m
//  Zebra
//
//  Created by han on 2018/10/05.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "JCBluetoothManager.h"
#import "JCBluetoothData.h"
#import "JCDataConvert.h"
#import "Constants.h"

#import "FileManager.h"
#import "Partition.h"
#import "OTAUpgradeViewController.h"

#define     kLoopCheckTime      0.02
#define     kCheckHardInfoTime  1
static JCBluetoothManager *_manager;
static CBCentralManager *_myCentralManager;
NSUInteger EXECUTE_COMMAND  = 0;
NSUInteger csn = 0x00;

@interface JCBluetoothManager (){
    
}
@property (nonatomic, strong) CBCharacteristic *readCharacteristic;     //读取数据特性
@property (nonatomic, strong) CBCharacteristic *writeNotifyCharacteristic;    //写数据特性
@property (nonatomic, weak) JCBluetoothData *bluetoothData;             //数据模型
@property (nonatomic, strong) NSMutableArray *commandBuffer;            //指令缓存
@property (nonatomic, strong) NSTimer *sendCommandLoop;                 //发送指令定时器

@property(strong,nonatomic) NSMutableArray *messageList;//推送消息,message数组
@property(assign,nonatomic) NSUInteger messageType;
@property(strong,nonatomic) NSString *commandDateStr;//推送消息的数据

@property (nonatomic, strong) CBCharacteristic *writeOTAWithRespCharac;    //OTA写数据特性 有返回值
@property (nonatomic, strong) CBCharacteristic *writeOTAWithoutRespCharac;    //OTA写数据特性 无返回值


//OTA相关的变量
@property(nonatomic,strong)FileManager *fileManager;
@property (nonatomic, strong) NSArray *partitionArray;
@property (nonatomic, strong) NSString *filePath;
@property(assign,nonatomic) int partitionIndex;
@property(assign,nonatomic) int blockIndex;
@property(assign,nonatomic) int cmdIndex;
@property(assign,nonatomic) int flash_addr;
@property(assign,nonatomic) float totalSize;
@property(assign,nonatomic) float finshSize;
@property(assign,nonatomic) int retryTimes;
@property(assign,nonatomic) int errorTimes;
@property(nonatomic) BOOL isCancle;
@property(nonatomic) BOOL isOTACmd;//区分是否为OTA命令
@property(nonatomic) BOOL isOTACmdWithResponse;//区分是否为OTA的有返回值命令
@property (nonatomic, strong) NSString *originalMacAddress;//原始mac地址,用于OTA模式重连
@property (nonatomic, weak) OTAManager *otaManager;
@end

@implementation JCBluetoothManager

#pragma mark 【1】创建单例蓝牙管理中心
+ (JCBluetoothManager *)shareCBCentralManager{
    @synchronized(self) {
        if (!_manager) {
            _manager = [[JCBluetoothManager alloc]init];
            _myCentralManager = [[CBCentralManager alloc] initWithDelegate:_manager queue:nil];//如果设置为nil，默认在主线程中跑
            _manager.bluetoothData = [JCBluetoothData shareBluetoothData];
            _manager.commandBuffer = [NSMutableArray array];

            //新增的遵循其他协议
            _manager.otaManager = [OTAManager shareOTAManager];
            _manager.otaManager.delegate = _manager;
        }
    }
    return _manager;
}

#pragma mark 【2】监测蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state){
        case CBManagerStateUnknown:
            break;
        case CBManagerStateUnsupported:
            NSLog(@"模拟器不支持蓝牙调试");
            break;
        case CBManagerStateUnauthorized:
            break;
        case CBManagerStatePoweredOff:{
            NSLog(@"蓝牙处于关闭状态");
            self.bluetoothState = BluetoothOpenStateIsClosed;
            _currentPeripheral  = nil;
            _readCharacteristic = nil;
            _writeNotifyCharacteristic = nil;

            _writeOTAWithRespCharac = nil;
            _writeOTAWithoutRespCharac = nil;

            [UserDefaults setObject:@"0" forKey:IsConnectToPeripheral];
            [UserDefaults synchronize];
            if ([self.delegate respondsToSelector:@selector(bluetoothStateChange:state:)]) {
                [self.delegate bluetoothStateChange:self state:BluetoothOpenStateIsClosed];
            }
        }
            break;
        case CBManagerStateResetting:
            break;
        case CBManagerStatePoweredOn:
        {
            self.bluetoothState = BluetoothOpenStateIsOpen;
            if ([self.delegate respondsToSelector:@selector(bluetoothStateChange:state:)]) {
                [self.delegate bluetoothStateChange:self state:BluetoothOpenStateIsOpen];
            }
            NSLog(@"蓝牙已开启");
        }
            break;
    }
}

#pragma mark 【3】发现外部设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (![peripheral.name isEqual:[NSNull null]]) {
        if ([self.delegate respondsToSelector:@selector(foundPeripheral:peripheral:advertisementData:RSSI:)]) {
            [self.delegate foundPeripheral:self peripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
        }
    }
}

#pragma mark 【4】连接外部蓝牙设备
- (void)connectToPeripheral:(CBPeripheral *)peripheral {
    if (!peripheral) {
        return;
    }
    [_myCentralManager connectPeripheral:peripheral options:nil];//连接蓝牙
    _currentPeripheral = peripheral;
}

#pragma mark 【5】连接外部蓝牙设备成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    _currentPeripheral = peripheral;
    peripheral.delegate = self;
    NSLog(@"连接成功，开始寻找服务和特征");
    //外围设备开始寻找服务
    [peripheral discoverServices:nil];
    NSLog(@"\n\n连接成功：%@\n\n",self.currentPeripheral);

    [UserDefaults setObject:@"1" forKey:IsConnectToPeripheral];
    [UserDefaults synchronize];
    if ([self.delegate respondsToSelector:@selector(bluetoothManager:didSucceedConectPeripheral:)]) {
        [self.delegate bluetoothManager:self didSucceedConectPeripheral:peripheral];
    }
    [self startLoopCheckCommandBuffer];
}

#pragma mark 连接外部蓝牙设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(bluetoothManager:didFailConectPeripheral:)]) {
        [self.delegate bluetoothManager:self didFailConectPeripheral:peripheral];
    }
    _currentPeripheral = nil;
}

#pragma mark 【6】寻找蓝牙服务
//外围设备寻找到服务后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if(error){
        NSLog(@"外围设备寻找服务过程中发生错误，错误信息：%@",error.localizedDescription);
    }
    //遍历查找到的服务
    CBUUID *serviceUUID=[CBUUID UUIDWithString:SERVICE_UUID];        //指定服务
    CBUUID *serviceOTAUUID=[CBUUID UUIDWithString:SERVICE_OTA_UUID];  //指定服务
    
    for (CBService *service in peripheral.services) {
        
        NSLog(@"----------------%@\r\n",service.UUID.UUIDString);
        if([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID]]){

        }
        
        //服务：------ 电量
        if([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_BATTERY_UUID]]){
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_BATTERY_READ_UUID]] forService:service];
        }
        
        //mac 地址
        if([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_DEVICE_INFO_UUID]]){
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_MAC_READ_UUID]] forService:service];
        }
        
        
        if([service.UUID isEqual:serviceUUID]){
            //外围设备查找指定服务中的特征
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_MAC_READ_UUID],[CBUUID UUIDWithString:CHARACTERISTIC_WRITE_UUID]] forService:service];
        }

        //OTA
        if([service.UUID isEqual:serviceOTAUUID]){
            //外围设备查找指定服务中的特征
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_OTA_WRITE_UUID],[CBUUID UUIDWithString:CHARACTERISTIC_OTA_INDICATE_UUID],[CBUUID UUIDWithString:CHARACTERISTIC_OTA_DATA_WRITE_UUID]] forService:service];
        }
    }
}

#pragma mark 【7】寻找蓝牙服务中的特性
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {//报错直接返回退出
        NSLog(@"didDiscoverCharacteristicsForService error : %@", [error localizedDescription]);
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics) {//遍历服务中的所有特性
        //获取设置时间服务特征
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID]]) {
            NSData *data = characteristic.value;
            NSInteger value = [JCDataConvert ToInteger:data];
            NSLog(@"-----002----准备设置时间 : %@, data : %@, \n\n 设置时间命令value : %ld%%", characteristic, data, (long)value);
        }
        
        //获取电量
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_BATTERY_READ_UUID]]) {
            [peripheral readValueForCharacteristic:characteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        
        //mac地址
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_MAC_READ_UUID]]) {
            [peripheral readValueForCharacteristic:characteristic];
        }

        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_WRITE_UUID]]){//找到收数据特性
            // 订阅, 实时接收
            [peripheral readValueForCharacteristic:characteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];//订阅其特性（这个特性只有订阅方式）
            _writeNotifyCharacteristic = characteristic;
        }

        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_READ_UUID]]) {//找到发数据特性
            [peripheral readValueForCharacteristic:characteristic];
        }
        
        if (_writeNotifyCharacteristic) {
            NSLog(@"连接成功");///此时才算真正连接成功，因为此时才有读、写特征，可以正常进行数据交互
        }

        //OTA
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_OTA_INDICATE_UUID]]) {
            [peripheral readValueForCharacteristic:characteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];

        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_OTA_WRITE_UUID]]) {
            _writeOTAWithRespCharac = characteristic;

        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_OTA_DATA_WRITE_UUID]]) {
            _writeOTAWithoutRespCharac = characteristic;
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
    
    //获取设置时间服务特征
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID]]) {
        NSData *data = characteristic.value;
        NSInteger value = [JCDataConvert ToInteger:data];
        NSLog(@"-----003----准备设置时间 : %@, data : %@, \n\n 设置时间命令value : %ld%%", characteristic, data, (long)value);
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
                    
                    //NSString *strLog = [JCDataConvert dataToHexStringMac:data];
                    //NSLog(@"-----respondType----sys ble info = %@\r\n",strLog);
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
}

#pragma mark 蓝牙外设连接断开，自动重连
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self stopLoopCheckCommandBuffer];//停止轮询发送指令

    [UserDefaults setObject:@"0" forKey:IsConnectToPeripheral];
    [UserDefaults synchronize];

    if ([self.delegate respondsToSelector:@selector(bluetoothManager:didDisconnectPeripheral:error:)]) {
        [self.delegate bluetoothManager:self didDisconnectPeripheral:peripheral error:error];
    }

    if (peripheral) {
        NSLog(@"\n\n断开与%@的连接，正在重连...\n\n",self.currentPeripheral);
        [_manager connectToPeripheral:_currentPeripheral];
    }
}

/*!
 *  通过蓝牙发送data数据到外设
 *
 *  @param data -[in] 要发送的字符串
 */
- (void)sendData:(nullable NSData *)data {
    [self.currentPeripheral writeValue:data
                     forCharacteristic:_writeNotifyCharacteristic
                                  type:CBCharacteristicWriteWithResponse];
}

// 发送数据 string类型转成data发送
-(void)sendString:(NSString *)string {
    if (_currentPeripheral.state == CBPeripheralStateConnected){
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [_currentPeripheral writeValue:data
                     forCharacteristic:_writeNotifyCharacteristic
                                  type:CBCharacteristicWriteWithResponse];
    }
}

#pragma mark 发送数据 ota
-(void)sendOTAData:(nullable NSData *)data {
    [self.currentPeripheral writeValue:data
                     forCharacteristic:_writeOTAWithoutRespCharac
                                  type:CBCharacteristicWriteWithoutResponse];
}

#pragma mark - 轮询发送指令机制
/*
 *@开始轮询发送指令
 */
- (void)startLoopCheckCommandBuffer{
    NSLog(@"开启轮询发送指令");
    _sendCommandLoop = [NSTimer scheduledTimerWithTimeInterval:kLoopCheckTime target:self selector:@selector(loopCheckCommandBufferToSend) userInfo:nil repeats:YES];
}

/*
 *@关闭轮询发送指令
 */
- (void)stopLoopCheckCommandBuffer{
    NSLog(@"关闭轮询发送指令");
    [_sendCommandLoop invalidate];
    _sendCommandLoop = nil;
    [_commandBuffer removeAllObjects];//清空指令缓存区
}

/*
 *@轮询发送指令  定时发送，每隔一段时间就发送
 */
- (void)loopCheckCommandBufferToSend{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        if (self->_commandBuffer.count > 0) { //如果有命令码存在就发送，如果没有就跳过
            //  如果是OTA命令 这里指的是无返回的一部分
            if ([[self->_commandBuffer firstObject] isKindOfClass:[NSNull class]]) {
                return;
            }
            if (self.isOTACmd) {
                //取消上传 //
                if(self.isCancle || self->_commandBuffer.count == 0 || self->_commandBuffer == nil){
                    return;
                }

                //有返回值
                if (self.isOTACmdWithResponse) {
                    if (!self->_writeOTAWithRespCharac) {
                        return ;
                    }
                    //将缓冲区第一个指令发出去
                    [self->_currentPeripheral writeValue:[self->_commandBuffer firstObject]
                                       forCharacteristic:self->_writeOTAWithRespCharac
                                                    type:CBCharacteristicWriteWithResponse];
                    //没有返回值，设计垃圾，用延时
                    //判断是不是开始OTA命令 应用模式
                    if ([[JCDataConvert convertDataToHexStr:[self->_commandBuffer firstObject]] isEqualToString:[JCDataConvert ToHex:START_OTA]]) {

                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            if ([self.delegate respondsToSelector:@selector(startOTASuccess:feedBackInfo:reconnectBluetoothType:)]){
                                [self.delegate startOTASuccess:self feedBackInfo:self->_currentPeripheral?true:false reconnectBluetoothType:@"OTA"];
                            }
                        });
                    }

                    //reboot成功之后自动重连
                    if ([[JCDataConvert convertDataToHexStr:[self->_commandBuffer firstObject]] isEqualToString:[JCDataConvert ToHex:REROOT]]) {

                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            if ([self.delegate respondsToSelector:@selector(reBootOTASuccess:feedBackInfo:reconnectBluetoothType:)]){
                                [self.delegate reBootOTASuccess:self feedBackInfo:self->_currentPeripheral?true:false reconnectBluetoothType:@"APP"];
                            }
                        });
                    }
                } else {
                    if (!self->_writeOTAWithoutRespCharac || self->_commandBuffer == nil) {
                        return ;
                    }
                    //将缓冲区第一个指令发出去
                    [self->_currentPeripheral writeValue:[self->_commandBuffer firstObject]
                                       forCharacteristic:self->_writeOTAWithoutRespCharac
                                                    type:CBCharacteristicWriteWithoutResponse];
                    //实时更新进度条
                    NSData *cmd = [self->_commandBuffer firstObject];
                    NSString *strcmd = [JCDataConvert convertDataToHexStr:cmd];
                    self.finshSize += strcmd.length;
                    float num = self.finshSize *100/2/self.totalSize;
                    dispatch_async(dispatch_get_main_queue(), ^{  //更新页面回到主线程
                        if ([self.delegate respondsToSelector:@selector(updateOTAProgressDataback:feedBackInfo:)]){
                            [self.delegate updateOTAProgressDataback:self feedBackInfo:num];
                        }
                    });
                }

            //其他非OTA得命令
            } else {
                if (!self->_writeNotifyCharacteristic) {
                    return ;
                }
                //将缓冲区第一个指令发出去
                [self->_currentPeripheral writeValue:[self->_commandBuffer firstObject]
                                   forCharacteristic:self->_writeNotifyCharacteristic
                                                type:CBCharacteristicWriteWithResponse];
            }
            //NSLog(@"发送的指令为：===> %@",[self->_commandBuffer firstObject]);
            if (self->_commandBuffer.count == 0) {
                return ;
            }
            //删除已发送指令
            [self->_commandBuffer removeObjectAtIndex:0];
        }
        
    });
}

#pragma mark 重新扫描外设
- (void)reScan{
    if (_currentPeripheral) {
        [_myCentralManager cancelPeripheralConnection:_currentPeripheral];//断开连接
        _currentPeripheral = nil;
        _readCharacteristic = nil;
        _writeNotifyCharacteristic = nil;

        _writeOTAWithRespCharac = nil;
        _writeOTAWithoutRespCharac = nil;
    }
//-------- TODO:设置 SERVICE_UUID
    //连接指定外设，就是通过UUID连接的，这个UUID被连接的设备要广播出来，这样BLE才能搜索到并且连接。
    //其中的uuid就是被连接设备广播出来的UUID字符串。
    //services为nil时是全扫描
    [_myCentralManager scanForPeripheralsWithServices:nil//@[[CBUUID UUIDWithString:SERVICE_UUID]]
                                              options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];


//已经被系统或者其他APP连接上的设备数组
//    NSArray *arr = [_myCentralManager retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]]; //UUID是外设的服务UUID，满足UUID 的外设就会放在数组中
//    [arr enumerateObjectsUsingBlock:^(CBPeripheral *obj, NSUInteger idx, BOOL *stop) {
//        NSLog(@"连接=====%@ %lu   /n%@",obj,(unsigned long)idx,obj.services);
//        [self discoverANCS:obj];
//    }];
//
////    NSArray *arr = [_myCentralManager retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_OTA_UUID]]];
//
//    if(arr.count>0) {
//        for (CBPeripheral* peripheral in arr) {
//            if (peripheral != nil) {
//                peripheral.delegate = self;
//                //manager 获取到的Peripheral会自动释放，要重新创建一个Peripheral对象等于获取到的Peripheral
//                _currentPeripheral = peripheral;
//                [_myCentralManager connectPeripheral:_currentPeripheral options:nil];
//            }
//        }
//    } else {
//        [_myCentralManager scanForPeripheralsWithServices:nil//@[[CBUUID UUIDWithString:SERVICE_UUID]]
//                                                  options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
////        [_myCentralManager scanForPeripheralsWithServices:nil options:nil];
//    }

}

- (void)discoverANCS:(CBPeripheral *)peripheral{
    [self centralManager:_myCentralManager didDiscoverPeripheral:peripheral advertisementData:[NSDictionary dictionary] RSSI:@(0)];
}


#pragma mark 停止扫描外设
- (void)stopScan{
    [_myCentralManager stopScan];
}

#pragma mark 正在扫描外设
- (BOOL)isScanning{
    if([_myCentralManager isScanning]){
        return YES;
    }
    return NO;
}

#pragma mark 断开外设连接
- (void)disConnectToPeripheral:(CBPeripheral *)peripheral{
    if (_currentPeripheral) {
        [_myCentralManager cancelPeripheralConnection:peripheral];
        _currentPeripheral = nil;
        _readCharacteristic = nil;
        _writeNotifyCharacteristic = nil;

        _writeOTAWithRespCharac = nil;
        _writeOTAWithoutRespCharac = nil;
    }
}

#pragma APP发送指令数据   **********写数据*********

//Byte 字节 Byte() 字节数组
- (NSUInteger)getCSN{
    if(csn < 0xff){
        csn += 1;
    }else{
        csn = 0x00;
    }
    return csn;
}

- (NSUInteger)getVerifyByte:(NSUInteger)command csn:(NSUInteger)csn {
    return command ^ csn;
}

- (NSUInteger)getVerifyByte:(NSUInteger)command csn:(NSUInteger)csn data:(NSData *)data {
    NSUInteger t = command ^ csn;
    Byte *otherCommand = (Byte *)[data bytes];
    for (int i=0 ; i<[data length]; i++) {
        NSLog(@"byte = %d",otherCommand[i]);
        t = t ^ otherCommand[i];
    }
    return t;
}

- (void) sendDataUseCommand:(NSUInteger)command
                   dataStr:(NSString *)dataStr{

    self.isOTACmd = NO;
    //开线程处理发送数据
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUInteger csn = self.getCSN;
        NSString *sendStr;
        if(dataStr == nil){
            //指令+CSN+校验码
            NSString *commandStr = [JCDataConvert ToHex:command];
            NSUInteger verify = [self getVerifyByte:command csn:csn];
            sendStr = [commandStr stringByAppendingFormat:@"%@%@",[JCDataConvert ToHex:csn],[JCDataConvert ToHex:verify]];
        }else {
            //指令+ CSN+ 其他命令+ 校验码
            NSString *commandStr = [JCDataConvert ToHex:command];
            NSUInteger verify = [self getVerifyByte:command csn:csn data:[JCDataConvert stringToHexData:dataStr]];
            sendStr = [commandStr stringByAppendingFormat:@"%@%@%@",[JCDataConvert ToHex:csn],dataStr,[JCDataConvert ToHex:verify]];
        }
        //打印出来看
        NSLog(@"---------------发送命令转换转换前的结果：%@ ....转换后的结果：%@",sendStr,[JCDataConvert hexToBytes:sendStr]);
        //指令已转换成data数据，将其填装进缓冲区待发送
        if (self->_currentPeripheral) {
            [self->_commandBuffer addObject:[JCDataConvert hexToBytes:sendStr]];
        }
        
    });
}

/*
 *  启动血压检测
 *
 */
- (void)startHeartRate {
    self.isOTACmd = NO;
    [self sendDataUseCommand:START_HEART_RATE dataStr:nil];
}

/*
 *  停止血压检测
 *
 */
- (void)stopHeartRate {
    self.isOTACmd = NO;
    [self sendDataUseCommand:STOP_HEART_RATE dataStr:nil];
}

/*
 *  启动加速器传感器
 *
 */
- (void)startAcceleratorSensor {
    self.isOTACmd = NO;
    [self sendDataUseCommand:START_GSENSOR dataStr:nil];
//    NSData *data = [JCDataConvert hexToBytes:@"230122"];
//    [self sendData:data];
}
/*
 *  停止加速器传感器
 *
 */
- (void)stopAcceleratorSensor {
    self.isOTACmd = NO;
    [self sendDataUseCommand:STOP_GSENSOR dataStr:nil];
}
/*
 * LED灯设定
 *
 */
- (void)startLedSetting:(NSString *)dataStr{
    self.isOTACmd = NO;
    [self sendDataUseCommand:LED_SETTING dataStr:dataStr];
}
/**
 消息推送
 @param dataStr 设置推送类型和内容
 */
- (void)sendMessage:(NSString *)dataStr{
    self.isOTACmd = NO;
    [self sendDataUseCommand:SEND_MESSAGE dataStr:dataStr];
}

/**
 消息推送
 @param messageArr 推送的标题和内容 phoneType:推送的类型
 */
- (void)sendMessage:(NSArray *)messageArr phoneType:(SendMessageType)messageType {
    [self.messageList removeAllObjects];
    self.messageType = (int)messageType;
    self.messageList = [messageArr mutableCopy];
    NSString *commandDateStr; //SendMessageType.phoneReminding SendMessageType.phoneRemindingEnd

    if (self.messageType == 1   || self.messageType == 2) {
        commandDateStr = [self getCommandDateStr:0];
    } else {
        commandDateStr = [self getCommandDateStr:1];
    }
    self.isOTACmd = NO;
    [self sendDataUseCommand:SEND_MESSAGE dataStr:commandDateStr];
}

-(NSMutableArray *)messageList{
    if (!_messageList) {
        _messageList = [NSMutableArray array];
    }
    return _messageList;
}

-(void)sedMsg:(NSArray *)messageArr phoneType:(SendMessageType)messageType {

}

-(NSString *)getCommandDateStr:(NSUInteger)status {
    NSData *firstMessageData = self.messageList.firstObject;
    Byte *firstMessageByte = (Byte *)[firstMessageData bytes];
    NSUInteger size = firstMessageData.length + 1;
    Byte *commandByte= malloc(sizeof(Byte)*(size));
    for (int j = 0; j < size ; j++) {
        if (j == 0) {
            commandByte[0] = (Byte)(self.messageType | status << 6);
        }else {
            NSUInteger int1 = firstMessageByte[j-1];
            Byte bytes = int1 & 0xff;
            commandByte[j] = bytes;
        }
    }
    NSData *commandData = [[NSData alloc] initWithBytes:commandByte length:size];
    NSLog(@"commandData:%@",commandData);
    return [JCDataConvert ConvertHexToString:commandData];
}

#pragma mark --- OTA
//第一步，连接蓝牙设备 应用模式下的蓝牙

/**
 OTA 第二步  设置设备 OTA 状态  发送命令0102  已连接的设备名称改变，Mac地址+1
 */
- (void)startOTA{
    NSString *commandStr = [JCDataConvert ToHex:START_OTA];
    self.isOTACmdWithResponse = YES;
    self.isOTACmd = YES;
    [self sendDataUseCommand:commandStr];
}

// 第三步 断开应用蓝牙，连接OTA蓝牙

/**
 OTA 第四步  发送OTA文件发送确认命令  发送命令01xx00 xx为文件分成的段数
 */
- (void)updateOTAFirmwareConfirmOrder:(NSArray *)partitionArray andPath:(NSString *)path{
    self.fileManager = [[FileManager alloc] firmWareFile:path];
    self.totalSize = self.fileManager.length;
    [self initData];
    //01+位数+00
    NSString *commandStr = [JCDataConvert ToHex:01];
    self.partitionArray = partitionArray;
    self.filePath = path;
    NSString *sendStr = [commandStr stringByAppendingFormat:@"%@%@",[JCDataConvert ToHex:self.fileManager.list.count],[JCDataConvert ToHex:00]];
    if (self->_currentPeripheral) {
        self.isOTACmdWithResponse = YES;
        self.isOTACmd = YES;
        [self->_commandBuffer addObject:[JCDataConvert hexToBytes:sendStr]];
    }
}

//第五步  更新系统时间
/*
 *
 *OTA升级完成，重新连接设备成功，应用模式，更新系统时间
 */
- (void)updateSystemTime:(NSString *)date{
    self.isOTACmd = NO;
    [self sendDataUseCommand:UPDATE_SYSTEM_TIME dataStr:date];
}

- (void)getBLESysInfo{
    
    self.isOTACmd = NO;
    [self sendDataUseCommand:GET_BLE_SYSTEM_INFO dataStr:nil];
}


-(void)initData{
    //OTA相关
    self.partitionIndex = 0;
    self.blockIndex = 0;
    self.cmdIndex = 0;
    self.flash_addr = 0;
    self.finshSize = 0;
    self.retryTimes = 3;
    self.isCancle = false;
}

-(void)onOTAFinish{
    [self reRoot];
}

-(void)reRoot{
    NSString *commandStr = [JCDataConvert ToHex:REROOT];
    self.isOTACmdWithResponse = YES;
    self.isOTACmd = YES;
    self.isCancle = NO;
    [self->_commandBuffer addObject:[JCDataConvert hexToBytes:commandStr]];
}

-(int)getPartitionCheckSum:(Partition *)partition {
    NSData *data = [JCDataConvert hexToBytes:partition.dataStr];
    return [JCDataConvert checkSum:0 byte:data];
}

-(NSString *) make_part_cmd:(int)index flash_addr:(int)flash_addr run_addr:(NSString *)run_addr size:(int)size checksum:(int)checksum {
    NSString *fa = [self strAdd0:[NSString stringWithFormat:@"%@",[JCDataConvert ToHex:flash_addr]] length:4];
    NSString *ra = [self strAdd0:run_addr length:4];
    NSString *sz = [self strAdd0:[NSString stringWithFormat:@"%@",[JCDataConvert ToHex:size]] length:4];
    NSString *cs = [self strAdd0:[NSString stringWithFormat:@"%@",[JCDataConvert ToHex:checksum]] length:2];
    NSString *Idindex = [self strAdd0:[NSString stringWithFormat:@"%@",[JCDataConvert ToHex:index]] length:1];
    return [NSString stringWithFormat:@"%@%@%@%@%@%@",@"02",Idindex,fa,ra,sz,cs];
}

-(NSString *)strAdd0:(NSString *)str length:(int)lenth {
    //不足8位 ，高位补0
        int strLength = str.length;
        for (int i=0;i<lenth*2-strLength;i++){
            str = [NSString stringWithFormat:@"%@%@",@"0",str];
        }
    NSMutableData *mData = [NSMutableData data];
    for (int i = 0; i < lenth ; i++) {
        NSUInteger int1 = 0x00;
        Byte bytes = int1 & 0xff;
        [mData appendBytes:&bytes length:1];
    }
    //NSLog(@"转换前mData:%@",mData);
    NSData *contentData = [JCDataConvert hexToBytes:str];

    Byte *byte= malloc(sizeof(Byte)*(lenth));
    [mData getBytes:byte length:lenth];
    NSUInteger length = contentData.length;
    Byte *contentByte = (Byte *)[contentData bytes];
    for (int j = 0; j < lenth; j++) {
        NSUInteger int1 = contentByte[lenth-j-1];
        Byte bytes = int1 & 0xff;
        byte[j] = bytes;
    }

    NSData *data = [[NSData alloc] initWithBytes:byte length:lenth];
    //NSLog(@"转换后mData:%@",data);
    NSString *contentStr = [JCDataConvert ConvertHexToString:data];//data转string
    return contentStr;
}

- (void)sendDataUseCommand:(NSString *)commandStr {
    //开线程处理发送数据
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"转换前的结果：%@ \n 转换后的结果：%@",commandStr,[JCDataConvert hexToBytes:commandStr]);
        //指令已转换成data数据，将其填装进缓冲区待发送
        if (self->_currentPeripheral) {
            [self->_commandBuffer addObject:[JCDataConvert hexToBytes:commandStr]];
        }
    });
}

#pragma mark -- OTAManagerDelegate

-(void)cancelOTASuccess:(OTAManager *)manager feedBackInfo:(BOOL)result {
    self.isCancle = result;
    [self->_commandBuffer removeAllObjects];//OTA中断，清除所有要发送的数据
}

-(void)isInOTAPageUpdate:(OTAManager *)manager feedBackInfo:(BOOL)result {
    self.isCancle = NO;
    [self->_commandBuffer removeAllObjects];
}
@end
