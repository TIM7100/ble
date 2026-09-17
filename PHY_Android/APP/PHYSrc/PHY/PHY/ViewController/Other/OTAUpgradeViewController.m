//
//  OTAUpgradeViewController.m
//  PHY
//
//  Created by Han on 2018/10/9.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "OTAUpgradeViewController.h"
#import "ProgressView.h"
#import "OTAListCell.h"
#import "OTCModel.h"
#import "OTAManager.h"
#import "Partition.h"
#import "JCBluetoothManager.h"
#import "JCDataConvert.h"
#import "CBLECenterMnger.h"

#import "CBLEOTAMnger.h"
#import "CBLEOTAReboot.h"

@interface OTAUpgradeViewController ()<UITableViewDelegate,UITableViewDataSource,UIDocumentInteractionControllerDelegate,CBLEOTAMngerDelegate,CBLEOTARebootDelegate,MBProgressHUDDelegate> {
    NSMutableArray *fileList;
    UIDocumentInteractionController *_documentController; //文档交互控制器
    NSString *docDirs;
    NSTimer *_timer;
    NSInteger _count;
}
@property (strong, nonatomic)  UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *documentArr;
@property (nonatomic, weak) JCBluetoothManager *bluetoothManager;
@property (nonatomic, strong) NSArray *partitionArray;//段落数组，元素为16*20个字节，每小段又有16段20个字节 的数据
@property (strong, nonatomic)  ProgressView *progressView;
@property(assign,nonatomic)NSInteger selectedRow;//选取的行数
@property(strong,nonatomic)NSString *OTAOrAPPType;//重新连接蓝牙时是OTA模式还是应用模式
@property(assign,nonatomic)BOOL isFirstConnectionOTA;//判断首次连接的网络是否是OTA
@property(assign,nonatomic)float progressValue;//完成进度

@property(nonatomic,strong)CBLEOTAMnger    *otaMnger;
@property(nonatomic,strong)CBLEOTAReboot   *otaReboot;
@end

@implementation OTAUpgradeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _documentArr = [NSMutableArray array];
    [self setUpView];
    self.isFirstConnectionOTA = false;
    self.otaReboot = [[CBLEOTAReboot alloc] init];
    self.otaReboot.delegate = self;
}

-(CBLEOTAMnger*)otaMnger{
    if ( _otaMnger == nil ){
        _otaMnger = [[CBLEOTAMnger alloc] init];
        _otaMnger.delegate = self;
    }
    return _otaMnger;
}


- (void)setUpView{
    self.navigationItem.title = @"OTA固件升级";
    [self baseSetup:PageGobackTypePop];
    self.view.backgroundColor = [UIColor whiteColor];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // to do
        // 异步操作，耗时的操作
         [self setView];
        dispatch_async(dispatch_get_main_queue(), ^{
            // to do
            // 更新界面
           [self.tableView reloadData];
        });
    });
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.barTintColor = Color_navPageButton_Green;
    self.progressValue = 0;
}


- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (self.progressView != nil) {
        [self.progressView remove];
        self.progressView = nil;
    }
    _otaMnger = nil;
    _otaReboot = nil;
}

-(void)popVC{
    
    //OTA取消升级
    _otaMnger = nil;
    if (self.progressView != nil) {
        [self.progressView remove];
        self.progressView = nil;
    }
    if (self.progressValue >0 && self.progressValue < 100 ) {
        [[CBLECenterMnger shareMnger] cmdDisconnectCurPheral];
        [super popVC];
    } else {
        [super popVC];
    }
}

-(void)setView{
    // 文件管理器
    NSFileManager *manager = [NSFileManager defaultManager];
    // 总文件夹
    NSString *folderPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/Inbox/"]];
    docDirs = folderPath;
    NSError *error = nil;
    //_dataFileArray是包含有该文件夹下所有文件的文件名及文件夹名的数组
    _documentArr = [[manager contentsOfDirectoryAtPath:docDirs error:&error] copy];
    fileList = [NSMutableArray array];
   
    if (![manager fileExistsAtPath:folderPath]) return;
    // 从前向后枚举器
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    // 详细内容
    
    NSString *fileName;
    OTCModel *fileObj;
    while ((fileName = [childFilesEnumerator nextObject]) != nil) {
        //NSLog(@"fileName ==== %@", fileName);
        NSString *fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        //NSLog(@"fileAbsolutePath ==== %@", fileAbsolutePath);
        fileObj = [[OTCModel alloc] init];
        fileObj.fileName = fileName;
        NSDictionary *fileAttributes = [manager attributesOfItemAtPath:[docDirs stringByAppendingPathComponent:fileName] error:nil];
        fileObj.filemTime = [fileAttributes objectForKey:@"NSFileCreationDate"];
        fileObj.fileSize = [[fileAttributes objectForKey:@"NSFileSize"] integerValue];
        fileObj.fileOwner = [fileAttributes objectForKey:@"NSFileGroupOwnerAccountName"];//所有人
        fileObj.fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        [fileList addObject:fileObj];
    }
}

-(NSMutableDictionary *)localFile {
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:path];
    NSString *fileName;
    NSMutableDictionary *R = [NSMutableDictionary dictionary];
    while (fileName = [dirEnum nextObject]) {
        NSLog(@"短路径:%@", fileName);
        NSLog(@"全路径:%@", [path stringByAppendingPathComponent:fileName]);
        
        NSString *key = [fileName componentsSeparatedByString:@"/"].lastObject;
        [R setObject:fileName forKey:key];
    }
    return R;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 如果是本地的，从本地删除；
    OTCModel *model = [fileList objectAtIndex:indexPath.row];
    // 如果是本地的，从本地删除
    if (model.fileAbsolutePath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:model.fileAbsolutePath error:nil];
    }
    // 移除数据源的数据
    [fileList removeObjectAtIndex:indexPath.row];
    // 移除tableView中的数据
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}


#pragma mark -- tableView设置
- (UITableView*)tableView{
    if (_tableView==nil) {
        _tableView=[[UITableView alloc] init];
        _tableView.frame=CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-64);
        _tableView.delegate=self;
        _tableView.dataSource=self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.tableView registerClass:[OTAListCell class] forCellReuseIdentifier:@"OTAListCell"];
        self.tableView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

//设置tableview行
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return fileList.count;
}
//设置行高
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    OTAListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OTAListCell" forIndexPath:indexPath];
    OTCModel *fileObj = (OTCModel *)[fileList objectAtIndex:indexPath.row];
    cell.contentLabel.text = fileObj.fileName;//文件名
    return cell;
}

//点击事件
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    // 去除选中之后的效果
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.progressView = [[ProgressView alloc] init];
    [self.progressView setState:KMProgressView_Begin withProgress:0];
    [self.progressView showAt:self.view];
    self.tableView.userInteractionEnabled = false;
    self.view.userInteractionEnabled = false;
    self.selectedRow = indexPath.row;


    OTCModel *model = [fileList objectAtIndex:indexPath.row];
    BOOL bSuc = NO;
    if ( model.fileAbsolutePath == nil && model.fileAbsolutePath.length <= 0 ){
        
        [self showMessageAutoHide:@"本地路径异常，请重新选择！" afterDelay:2.0];
        bSuc = YES;
    } else {
        bSuc = [self.otaMnger startOTAWithLocFile:model.fileAbsolutePath];
    }
    self.view.userInteractionEnabled = YES;
    if ( !bSuc ){
        [self showMessageAutoHide:@"采用当前文件做OTA升级异常，请重新尝试！" afterDelay:2.0];
        NSLog(@"--------------------------------------->>>>>>>>>>>>>>>>>>>>>>>>");
    }
}



-(void)updateOTAProgress:(CBLEOTAMnger *)manager feedBackInfo:(float)progressValue {

    self.progressValue = progressValue;
    if (progressValue >= 100.0) {
        
        if (progressValue > 100.0) {
            return;
        }
        
        [self.progressView setState:KMProgressView_Completed withProgress:1.0];
        [self.progressView remove];
        self.tableView.userInteractionEnabled = true;
        //NSLog(@"进度条消失，progressValue：%.2f",progressValue);
        self.progressView = nil;
    } else {
        [self.progressView setState:KMProgressView_Uploading withProgress:progressValue/100];
    }
}

-(void)updateOTAComplete:(CBLEOTAMnger *)manager isComplete:(BOOL)isComplete{
    [self.progressView setState:KMProgressView_Completed withProgress:1.0];
    [self.progressView remove];
    self.progressView = nil;
    _otaMnger = nil;
    
    
    if ( [_otaReboot rebootAutoConnect] ){
        NSString *strTip = @"OTA升级完成，正在重新连接蓝牙！";
        [self showMessageAutoHide:strTip afterDelay:20.0];
    } else {
        NSString *strTip = @"OTA升级完成，点击确认后重新启动蓝牙，请手动连接！";
        [self showTipAuto2Main:strTip reBoot:YES];
    }
}


- (void)updateOTAError:(nullable CBLEOTAMnger *) manager
             errorCode:(NSUInteger)errorCode{
    
    [self.progressView setState:KMProgressView_Completed withProgress:1.0];
    [self.progressView remove];
    self.progressView = nil;
    
    NSString *strTip = [CBLEOTAMnger errCode2Str:errorCode];
    if ( strTip != nil ){
        [self showTipAuto2Main:strTip reBoot:NO];
    }
}


- (void)rebootFinish:(nullable CBLEOTAReboot *) manager
             bFinish:(BOOL)bFinish{
    NSString *strTip = @"蓝牙重新连接完成，2秒后返回主界面！";
    [self showMessageAutoHide:strTip afterDelay:2.0];
    [self performSelector:@selector(popVC) withObject:nil afterDelay:2.0];
}



-(void)showTipAuto2Main:(NSString*)strTip reBoot:(BOOL)bReboot{
    
    if ( bReboot )
        [[CBLECenterMnger shareMnger] otaCmd2App];
    else
        [[CBLECenterMnger shareMnger] cmdDisconnectCurPheral];
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:strTip preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [super popVC];
    }];
    
    [alertC addAction:action];
    [[UIApplication sharedApplication].keyWindow.rootViewController
     presentViewController:alertC animated:YES completion:nil];
}

@end
























#if 0

//[self setUpBluetooth];
//    NSString *dateStr = [self getDate];

[NotificationCenter addObserver:self selector:@selector(bluetoothGetBatteryLeve:) name:BluetoothGetBatteryLeve object:nil];
[NotificationCenter addObserver:self selector:@selector(bluetoothGetMacAddress:) name:BluetoothGetMacAddress object:nil];

-(void)bluetoothGetBatteryLeve:(NSNotification*)noti {
    NSData *data = noti.userInfo[@"batteryLeve"];
    NSInteger value = [JCDataConvert ToInteger:data];
    NSString * connectedBatteryLevel = [NSString stringWithFormat:@"%ld%%", (long)value];
    if (self.updateBatteryLevel) {
        self.updateBatteryLevel(connectedBatteryLevel);
    }
}

-(void)bluetoothGetMacAddress:(NSNotification*)noti {
    NSString *macAddress = noti.userInfo[@"macAddress"];
    NSString *originalMacAddress = noti.userInfo[@"originalMacAddress"];
    NSString *originalUUID = noti.userInfo[@"originalUUID"];
    NSString *connectedMacAddress = macAddress;
    if (self.updateMacAddress) {self.updateMacAddress(connectedMacAddress,originalMacAddress,originalUUID);
    }
}



#pragma mark - 蓝牙及相关设置初始化
- (void)setUpBluetooth {
    _bluetoothManager = [JCBluetoothManager shareCBCentralManager];
    _bluetoothManager.delegate = self;
}



-(void)updateOTAProgressDataback:(JCBluetoothManager *)manager isComplete:(BOOL)isComplete{
    [self.progressView setState:KMProgressView_Completed withProgress:1.0];
    [self.progressView remove];
    self.progressView = nil;
}



//NSFileManager-读取内容
OTCModel *model = [fileList objectAtIndex:indexPath.row];
if (model.fileAbsolutePath) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSData *fileData = [fileManager contentsAtPath:model.fileAbsolutePath];
    
    self.partitionArray = [NSMutableArray arrayWithCapacity:0];
    //        self.partitionArray = [[OTAManager shareOTAManager]analyzePartition:[JCDataConvert ConvertHexToString:fileData]];
    self.partitionArray = [[Partition alloc] analyzePartition:[JCDataConvert ConvertHexToString:fileData]];
    NSLog(@"----------------FileSize = %ld,%ld \r\n",fileData.length,_partitionArray.count);
}

#if 0
//如果OTA中途断掉，再次升级直接上传文件
if([_bluetoothManager.currentPeripheral.name isEqualToString:@"PPlusOTA"]) {
    //连接的蓝牙已经是OTA模式下的，直接省去前4个步骤，直接进行第5步，上传文件
    self.isFirstConnectionOTA = true;
    OTCModel *model = [fileList objectAtIndex:self.selectedRow];
    //发送文件确认命令
    [self updateFirmwareConfirmOrderWithPath:model.fileAbsolutePath];
    NSLog(@"fileArray截取的数据：%@",self.partitionArray);
} else {
    //从应用模式进入OTA模式，全自动升级
    [_bluetoothManager startOTA];//开始OTA
}
#else

//如果OTA中途断掉，再次升级直接上传文件
if([_bluetoothManager.currentPeripheral.name isEqualToString:@"PPlusOTA"]) {
    
    //1秒后开始上传文件
    [self performSelector:@selector(reUpdateOTA) withObject:nil afterDelay:1.0];
    
} else {
    //从应用模式进入OTA模式，全自动升级
    [_bluetoothManager startOTA];//开始OTA
}

#endif


-(void)reUpdateOTA{
    //连接的蓝牙已经是OTA模式下的，直接省去前4个步骤，直接进行第5步，上传文件
    self.isFirstConnectionOTA = true;
    OTCModel *model = [fileList objectAtIndex:self.selectedRow];
    [self updateFirmwareConfirmOrderWithPath:model.fileAbsolutePath];
}



//发送OTA文件确认命令
-(void)updateFirmwareConfirmOrderWithPath:(NSString *)path {
    [_bluetoothManager updateOTAFirmwareConfirmOrder:self.partitionArray andPath:path];
}


#pragma mark - UIDocumentInteractionControllerDelegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    //注意：此处要求的控制器，必须是它的页面view，已经显示在window之上了
    return self.navigationController;
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
    //MLDLog(@"发现的设备广播中：%@ %@",peripheral.identifier.UUIDString,peripheral.name);
#warning  -- 找不到就报连接设备失败错误
    
    //应用模式下根据UUID自动连接
    if ([self.OTAOrAPPType isEqualToString:@"APP"]) {
        if (self.isFirstConnectionOTA) {
            //首次进入已经连接了OTA模式的蓝牙，提醒手动连接
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"请手动连接设备" preferredStyle:UIAlertControllerStyleAlert];
            __weak __typeof__(self) weakSelf = self;
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf dismiss];
            }];
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


//连接蓝牙成功调用
- (void)bluetoothManager:(JCBluetoothManager *)manager didSucceedConectPeripheral:(CBPeripheral *)peripheral {
    [_bluetoothManager stopScan];
    
    //更新系统时间
    if ([self.OTAOrAPPType isEqualToString:@"APP"]) {
        
        //[_bluetoothManager getBLESysInfo];
        NSString *currentDate = [self getDate];
        [_bluetoothManager updateSystemTime:currentDate];
    }
    //开始上传文件
    if ([self.OTAOrAPPType isEqualToString:@"OTA"]) {
        OTCModel *model = [fileList objectAtIndex:self.selectedRow];
        //发送文件确认命令
        [self updateFirmwareConfirmOrderWithPath:model.fileAbsolutePath];
        NSLog(@"bluetoothManager::fileArray截取的数据：%@",self.partitionArray);
    }
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

#endif
