//
//  UpgradeModeViewController.m
//  OTASDKDemo
//
//  Created by Yang on 2018/10/28.
//  Copyright © 2018 phy. All rights reserved.
//

#import "UpgradeModeViewController.h"
#import "OTAManualViewController.h"
#import "ProgressView.h"
#import "OTCModel.h"

@interface UpgradeModeViewController ()<JCBluetoothManagerDelegate,MBProgressHUDDelegate>{
    NSTimer *_timer;
    NSInteger _count;
}
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *filePathLabel;
@property (nonatomic, strong) NSArray *partitionArray;//段落数组，元素为16*20个字节，每小段又有16段20个字节 的数据
@property (nonatomic, weak) JCBluetoothManager *bluetoothManager;
@property (strong, nonatomic)  ProgressView *progressView;
@property(strong,nonatomic)NSString *OTAOrAPPType;//重新连接蓝牙时是OTA模式还是应用模式
@property(assign,nonatomic)BOOL isFirstConnectionOTA;//判断首次连接的网络是否是OTA
@property(assign,nonatomic)float progressValue;//完成进度

@end

@implementation UpgradeModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
    self.isFirstConnectionOTA = false;
    [self setUpBluetooth];
    //    NSString *dateStr = [self getDate];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.barTintColor = Color_navPageButton_Green;
    self.progressValue = 0;
    [[OTAManager shareOTAManager] isInOTAPageUpdate:YES];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (self.progressView != nil) {
        [self.progressView remove];
        self.progressView = nil;
    }
    //OTA取消升级
    if (self.progressValue>0 && self.progressValue < 100 ) {
        [[OTAManager shareOTAManager] cacelOTAUpdate:YES];
    }
}

- (void)setUpView {
    self.navigationItem.title = @"模式选择";
    [self baseSetup:PageGobackTypePop];
    self.view.backgroundColor = [UIColor whiteColor];

    const char *pConstChar = [self.mscAddress UTF8String];
    NSString *oldMacStr = [self getMacStr:pConstChar];
    oldMacStr = [self getOldMacStr:oldMacStr];

    self.macAddressLabel.text = [NSString stringWithFormat:@"mac地址：%@",oldMacStr];

    OTCModel *model = [self.fileList objectAtIndex:self.selectedRow];
    self.filePathLabel.text = [NSString stringWithFormat:@"文件：%@",model.fileAbsolutePath];
}

- (IBAction)Manual:(id)sender {
    UIStoryboard *mainS = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    OTAManualViewController *selfdetailVC = [mainS instantiateViewControllerWithIdentifier:@"OTAManualViewController"];
    selfdetailVC.mscAddress = self.mscAddress;
    selfdetailVC.originalUUID = self.originalUUID;
    selfdetailVC.selectedRow = self.selectedRow;
    selfdetailVC.fileList = self.fileList;
    [self.navigationController pushViewController:selfdetailVC animated:YES];
}

- (IBAction)autoUpdate:(id)sender {

    self.progressView = [[ProgressView alloc] init];
    [self.progressView setState:KMProgressView_Begin withProgress:0];
    [self.progressView showAt:self.view];
    
    //如果OTA中途断掉，再次升级直接上传文件
    if([_bluetoothManager.currentPeripheral.name isEqualToString:@"PPlusOTA"]) {
        //连接的蓝牙已经是OTA模式下的，直接省去前4个步骤，直接进行第5步，上传文件
        self.isFirstConnectionOTA = true;
        OTCModel *model = [self.fileList objectAtIndex:self.selectedRow];
        //发送文件确认命令
        [self updateFirmwareConfirmOrderWithPath:model.fileAbsolutePath];
        NSLog(@"fileArray截取的数据：%@",self.partitionArray);
    } else {
        //从应用模式进入OTA模式，全自动升级
        [_bluetoothManager startOTA];//开始OTA
    }
    //NSFileManager-读取内容
    OTCModel *model = [self.fileList objectAtIndex:self.selectedRow];
    if (model.fileAbsolutePath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSData *fileData = [fileManager contentsAtPath:model.fileAbsolutePath];
        self.partitionArray = [NSMutableArray arrayWithCapacity:0];
        self.partitionArray = [[Partition alloc] analyzePartition:[JCDataConvert ConvertHexToString:fileData]];
    }
}

//发送OTA文件确认命令
-(void)updateFirmwareConfirmOrderWithPath:(NSString *)path {
    [_bluetoothManager updateOTAFirmwareConfirmOrder:self.partitionArray andPath:path];
}

#pragma mark - 蓝牙及相关设置初始化
- (void)setUpBluetooth {
    _bluetoothManager = [JCBluetoothManager shareCBCentralManager];
    _bluetoothManager.delegate = self;
    [_bluetoothManager setUpdateMode:true];
}

-(void)updateOTAProgressDataback:(JCBluetoothManager *)manager feedBackInfo:(float)progressValue {
    NSLog(@"进度条的值，progressValue：%.2f",progressValue);
    self.progressValue = progressValue;
    if (progressValue > 99.99) {
        return;
    }
    if (progressValue >= 100.0) {
        if (progressValue > 100.0) {
            return;
        }
    } else {
        NSLog(@"进度条，progressValue：%.2f",progressValue);
        [self.progressView setState:KMProgressView_Uploading withProgress:progressValue/100];
    }
}

-(void)updateOTAProgressDataback:(JCBluetoothManager *)manager isComplete:(BOOL)isComplete {
    [self.progressView setState:KMProgressView_Completed withProgress:1.0];
    [self.progressView remove];
    self.progressView = nil;
}

#pragma mark - JCBluetoothManagerDelegate

-(void)startOTASuccess:(JCBluetoothManager *)manager feedBackInfo:(BOOL)result reconnectBluetoothType:(NSString *)OTAOrAPPType {
    if (result) {
        self.OTAOrAPPType = OTAOrAPPType;
        [_bluetoothManager disConnectToPeripheral:_bluetoothManager.currentPeripheral];//断开蓝牙
        //扫描设备
        if (_bluetoothManager.bluetoothState == BluetoothOpenStateIsOpen && _bluetoothManager.currentPeripheral == nil) {
            [_bluetoothManager reScan];
        }
    }
}

//reboot成功之后
-(void)reBootOTASuccess:(JCBluetoothManager *)manager feedBackInfo:(BOOL)result reconnectBluetoothType:(NSString *)OTAOrAPPType {
    if (result) {
        self.OTAOrAPPType = OTAOrAPPType;
        [_bluetoothManager disConnectToPeripheral:_bluetoothManager.currentPeripheral];//断开蓝牙
        //扫描设备
        if (_bluetoothManager.bluetoothState == BluetoothOpenStateIsOpen && _bluetoothManager.currentPeripheral == nil) {
            [_bluetoothManager reScan];
        }
    }
}

//升级错误码处理
- (void)updateOTAErrorCallBack:(nullable JCBluetoothManager *) manager
                     errorCode:(NSUInteger)errorCode {

    if (self.progressView != nil) {
        [self.progressView remove];
        self.progressView = nil;
    }
    
    switch (errorCode) {
        case 0x64: {
            NSString *tip = [NSString stringWithFormat:@"文件解析错误"];
            [self hudSetting:tip];
        }
            break;
        case 0x65: {
            NSString *tip = [NSString stringWithFormat:@"进入OTA状态后连接错误"];
            [self hudSetting:tip];
        }
            break;
        case 0x66: {
            NSString *tip = [NSString stringWithFormat:@"OTA数据发送service未找到"];
            [self hudSetting:tip];
        }
            break;
        case 0x67: {
            NSString *tip = [NSString stringWithFormat:@"OTA命令发送service未找到"];
            [self hudSetting:tip];
        }
            break;
        case 0x68: {
            NSString *tip = [NSString stringWithFormat:@"OTA数据写入错误"];
            [self hudSetting:tip];
        }
            break;
        case 0x69: {
            NSString *tip = [NSString stringWithFormat:@"OTA响应错误"];
            [self hudSetting:tip];
        }
            break;
        case 0x6a: {
            NSString *tip = [NSString stringWithFormat:@"断开连接"];
            [self hudSetting:tip];
        }
            break;
        case 0x6b: {
            NSString *tip = [NSString stringWithFormat:@"设备未连接"];
            [self hudSetting:tip];
        }
            break;
        case 0x6c: {
            NSString *tip = [NSString stringWithFormat:@"设备不在OTA状态"];
            [self hudSetting:tip];
        }
            break;
        default:{
            NSString *tip = [NSString stringWithFormat:@"OTA升级失败，请重试"];
            [self hudSetting:tip];
        }
            break;

    }
}

//发现设备
- (void)foundPeripheral:(JCBluetoothManager *)manager peripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    MLDLog(@"发现的设备广播中：%@ %@",peripheral.identifier.UUIDString,peripheral.name);
#warning  -- 找不到就报连接设备失败错误

    //应用模式下根据UUID自动连接
    if ([self.OTAOrAPPType isEqualToString:@"APP"]) {
        if (self.isFirstConnectionOTA) {
            //首次进入已经连接了OTA模式的蓝牙，提醒手动连接
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"请手动连接设备" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
            [alertC addAction:action];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:nil];
            return;
        }
        if ([self.originalUUID isEqualToString:peripheral.identifier.UUIDString]) {
            [_bluetoothManager connectToPeripheral:peripheral];
        }

    } else if ([self.OTAOrAPPType isEqualToString:@"OTA"]) {
        // 2 -解析广播数据
        NSObject *value = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
        NSString *macStr = nil;
        if (![value isKindOfClass: [NSArray class]]){
            const char *valueString = [[value description] cStringUsingEncoding: NSUTF8StringEncoding];
            if (valueString != NULL) {
                macStr = [self getMacStr:valueString]; //获取到的mac地址
                if (macStr.length < 16) {
                    return;
                }

                macStr = [self getPeripheralMac:macStr];
                const char *pConstChar = [self.mscAddress UTF8String];
                NSString *oldMacStr = [self getMacStr:pConstChar]; //获得应用模式下的Mac地址

                if (oldMacStr.length < 16) {
                    return;
                }

                NSData *macd = [JCDataConvert hexToBytes:oldMacStr];
                //取前两位转十进制
                NSUInteger respond = [JCDataConvert oneByteToDecimalUint:[macd subdataWithRange:NSMakeRange(0, 1)]];//16进制转10进制

                if ([self.OTAOrAPPType isEqualToString:@"OTA"]) {
                    respond ++;
                }

                //转十六进制
                NSString *firstStr = [JCDataConvert ToHex:respond];
                //替换
                NSString *bStr = [oldMacStr substringWithRange:NSMakeRange(0,2)];
                NSString *replacedStr = [oldMacStr stringByReplacingOccurrencesOfString:bStr withString:firstStr];
                replacedStr = [self getOldMacStr:replacedStr];

                if ([replacedStr isEqualToString:macStr]) {
                    NSLog(@"重新连接APP模式首位地址前：%@",macStr);
                    [_bluetoothManager connectToPeripheral:peripheral];
                }
            }
        }
    }
}

//连接蓝牙成功调用
- (void)bluetoothManager:(JCBluetoothManager *)manager didSucceedConectPeripheral:(CBPeripheral *)peripheral {
    [_bluetoothManager stopScan];

    //更新系统时间
    if ([self.OTAOrAPPType isEqualToString:@"APP"]) {
        NSString *currentDate = [self getDate];
        [_bluetoothManager updateSystemTime:currentDate];
    }
    //开始上传文件
    if ([self.OTAOrAPPType isEqualToString:@"OTA"]) {
        OTCModel *model = [self.fileList objectAtIndex:self.selectedRow];
        //发送文件确认命令
        [self updateFirmwareConfirmOrderWithPath:model.fileAbsolutePath];
        NSLog(@"fileArray截取的数据：%@",self.partitionArray);
    }
}

-(NSString *)getMacStr:(const char *)optinalMacAddress {
    NSString *value = [NSString stringWithFormat:@"%s",optinalMacAddress];
    value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
    value = [value stringByReplacingOccurrencesOfString:@"<" withString:@""];
    value = [value stringByReplacingOccurrencesOfString:@">" withString:@""];
    return value;
}

-(NSString *)getPeripheralMac:(NSString *)macStr {
    NSMutableString*macString = [[NSMutableString alloc]init];
    [macString appendString:[[macStr substringWithRange:NSMakeRange(14,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[macStr substringWithRange:NSMakeRange(12,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[macStr substringWithRange:NSMakeRange(10,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[macStr substringWithRange:NSMakeRange(8,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[macStr substringWithRange:NSMakeRange(6,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[macStr substringWithRange:NSMakeRange(4,2)]uppercaseString]];
    return macString;
}

-(NSString *)getOldMacStr:(NSString *)value {
    NSMutableString*macString = [[NSMutableString alloc]init];
    [macString appendString:[[value substringWithRange:NSMakeRange(14,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(12,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(10,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(4,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(2,2)]uppercaseString]];
    [macString appendString:@":"];
    [macString appendString:[[value substringWithRange:NSMakeRange(0,2)]uppercaseString]];
    return macString;
}

-(NSString *)getDate {
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYMMddhhmmss"];
    NSString *DateTime = [formatter stringFromDate:date];

    NSString *yearStr = [DateTime substringWithRange:NSMakeRange(0,2)];
    NSString *monthStr = [DateTime substringWithRange:NSMakeRange(2,2)];
    NSString *dayStr = [DateTime substringWithRange:NSMakeRange(4,2)];
    NSString *hourStr = [DateTime substringWithRange:NSMakeRange(6,2)];
    NSString *miniteStr = [DateTime substringWithRange:NSMakeRange(8,2)];
    NSString *secStr = [DateTime substringWithRange:NSMakeRange(10,2)];

    NSString *data = [NSString stringWithFormat:@"%@%@%@%@%@%@",[JCDataConvert ToHex:[yearStr intValue]],[JCDataConvert ToHex:[monthStr intValue]],[JCDataConvert ToHex:[dayStr intValue]],[JCDataConvert ToHex:[hourStr intValue]],[JCDataConvert ToHex:[miniteStr intValue]],[JCDataConvert ToHex:[secStr intValue]]];
    NSLog(@"%@============年-月-日  时：分：秒=====================",data);
    return data;
}

-(void)hudSetting:(NSString *)tip {
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = tip;
        hud.label.numberOfLines = 0;
        hud.delegate = self;
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:YES afterDelay:0.5];
    });
}

@end
