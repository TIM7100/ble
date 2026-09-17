//
//  bluetoothListViewController.m
//  PHY
//
//  Created by Han on 2018/9/28.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "BluetoothListViewController.h"
#import "BluetoothListCell.h"
#import "JCBlutoothInfoModel.h"
#import "JCBluetoothManager.h"
#import "JCDataConvert.h"
#import "CBLECenterMnger.h"

#define ScanTimeInterval        3.0
#define SearchOutTime           10

@interface BluetoothListViewController ()<UITableViewDelegate,UITableViewDataSource,JCBluetoothManagerDelegate>
@property (strong, nonatomic)  UITableView *tableView;
@property (strong, nonatomic) UIButton * stopBtn;
//@property (nonatomic, weak) JCBluetoothManager              *bluetoothManager;
//@property (nonatomic, strong) NSMutableArray                *allBlutoothModel;
//@property (nonatomic, strong) NSMutableArray                *sortArray;
@property (nonatomic, strong) NSTimer                       *scanTimer;
@property (nonatomic, strong) NSTimer                       *scanTimeOut;
@property (nonatomic, strong) UIActivityIndicatorView       *animation;
@property(nonatomic,strong)NSString                         *connectedMacAddress;
@property(nonatomic,strong)NSString                         *connectedBatteryLevel;
@end

@implementation BluetoothListViewController

- (void)checkForScanBleDevice{
    
    [self showSearchingIcon:YES];
    if ( [CBLECenterMnger BLEIsPowerOff] ){
        __weak __typeof(&*self)weakSelf = self;
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"请开启蓝牙连接设备" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf popVC];
        }];
        [alertC addAction:action];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:nil];
        [self showSearchingIcon:NO];
        
    } else if ( [[CBLECenterMnger shareMnger] isCanScan] ){
        //开始扫描外部蓝牙设备
        [self startScanPeripherals];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
    [self addRightBtn];

    [[CBLECenterMnger shareMnger].dataPherals removeAll];
    [self checkForScanBleDevice];
    
    
    //注：以下也可以用Delegage来实现
    ADD_MESSAGE(BLEMSG_CENTER_POWERON,   msgForBLEPowerOn);
    ADD_MESSAGE(BLEMSG_CENTER_NEWPHERAL, msgForNewPheral);
    ADD_MESSAGE(BLEMSG_PHERAL_CONNECT_RST, msgForPheralConnect);
    ADD_MESSAGE(BLEMSG_PHERAL_DISCONNECT, msgForPheralReConnect:);
    
    ADD_MESSAGE(BluetoothGetBatteryLeve, bluetoothGetBatteryLeve:);
    ADD_MESSAGE(BluetoothGetMacAddress, bluetoothGetMacAddress:);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.barTintColor = Color_navPageButton_Green;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
    //取消扫描
    [_scanTimer invalidate];
    _scanTimer = nil;
    [_scanTimeOut invalidate];
    _scanTimeOut = nil;
    [[CBLECenterMnger shareMnger] cmdStopScan];
    [self showSearchingIcon:NO];
    
    REMOVE_MESSAGE(BLEMSG_CENTER_NEWPHERAL, nil);
    REMOVE_MESSAGE(BLEMSG_CENTER_POWERON, nil);
    REMOVE_MESSAGE(BLEMSG_PHERAL_CONNECT_RST, nil);
    REMOVE_MESSAGE(BluetoothGetMacAddress, nil);
}

-(void)msgForBLEPowerOn{
    // 关闭状态
    if ( [CBLECenterMnger BLEIsPowerOff] ) {
        
        __weak __typeof(&*self)weakSelf = self;
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"请开启蓝牙连接设备" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf popVC];
        }];
        [alertC addAction:action];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:nil];
    } else {
        
        if ( ![[CBLECenterMnger shareMnger] isScaning] )
            [self scan];
    }
}

-(void)msgForNewPheral{
    [self.tableView reloadData];
}

-(void)msgForPheralConnect{
    
    //蓝牙连接上
    if ( [[CBLECenterMnger shareMnger] isConnectOK]){
        [_scanTimer invalidate];
        _scanTimer = nil;
        [_scanTimeOut invalidate];
        _scanTimeOut = nil;
        [[CBLECenterMnger shareMnger] cmdStopScan];
        [self showSearchingIcon:NO];
        
        //提示框提示调用成功
        CDataPheralInfo *pheral = [CBLECenterMnger shareMnger].curPheral;
        NSString *tip = [NSString stringWithFormat:@"蓝牙连接成功: %@,状态：%@",
                         pheral.peripheral.name,
                         pheral.peripheral.state==CBPeripheralStateConnected?@"连接成功":@"未知" ];
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:tip preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self popVC];
            if (self.updateMainPageRightBtn) {
                self.updateMainPageRightBtn();
            }
        }];
        [alertC addAction:action];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:nil];
    } else {
        [self showMessageAutoHide:@"蓝牙连接失败，请重新尝试！" afterDelay:3.0];
    }
}

-(void)msgForPheralReConnect:(NSNotification*)noti{
    NSString *strTryNums = noti.object;
    NSInteger nTryNums = strTryNums.integerValue;
    NSString *strTip = [NSString stringWithFormat:@"蓝牙断开，正在尝试第[%ld]次重新连接",(long)nTryNums];
    [self showMessageAutoHide:strTip afterDelay:3.0];
}


-(void)bluetoothGetBatteryLeve:(NSNotification*)noti {
    NSData *data = noti.userInfo[@"batteryLeve"];
    NSInteger value = [JCDataConvert ToInteger:data];
    self.connectedBatteryLevel = [NSString stringWithFormat:@"%ld%%", (long)value];
    if (self.updateBatteryLevel) {
        self.updateBatteryLevel(self.connectedBatteryLevel);
    }
}

-(void)bluetoothGetMacAddress:(NSNotification*)noti {
    NSString *macAddress = noti.userInfo[@"macAddress"];
    NSString *originalMacAddress = noti.userInfo[@"originalMacAddress"];
    NSString *originalUUID = noti.userInfo[@"originalUUID"];
    self.connectedMacAddress = macAddress;
    if (self.updateMacAddress) {
        self.updateMacAddress(self.connectedMacAddress,originalMacAddress,originalUUID);
    }
}

-(void)addRightBtn {
    self.stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.stopBtn.frame = CGRectMake(0, 0, 40, 40);
    self.stopBtn.titleLabel.font = Font_Title;
    [self.stopBtn setTitle:@"停止" forState:UIControlStateNormal];
    [self.stopBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.stopBtn addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.stopBtn];
    self.navigationItem.rightBarButtonItems = @[rightBarItem];
}

- (void)scan {
    
    if ( [[CBLECenterMnger shareMnger] isCanScan] ){
        [self startScanPeripherals];
    }
    
#if 0
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (_bluetoothManager.bluetoothState == BluetoothOpenStateIsOpen && _bluetoothManager.currentPeripheral == nil) {
        [self startScanPeripherals];
    }
#endif
}

- (void)stop {
    self.stopBtn.selected = !self.stopBtn.selected;
    if(self.stopBtn.selected){
        [self.stopBtn setTitle:@"搜索" forState:UIControlStateNormal];
        [_scanTimer invalidate];
        _scanTimer = nil;
        [_scanTimeOut invalidate];
        _scanTimeOut = nil;
        [[CBLECenterMnger shareMnger] cmdStopScan];
        [self showSearchingIcon:NO];
    }else{
        [self.stopBtn setTitle:@"停止" forState:UIControlStateNormal];
        [self showSearchingIcon:YES];
        [[CBLECenterMnger shareMnger].dataPherals removeAll];
        [self.tableView reloadData];
        [self scan];
#if 0
        //[_animation startAnimating];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        if (_bluetoothManager.bluetoothState == BluetoothOpenStateIsOpen && _bluetoothManager.currentPeripheral == nil) {
            [self startScanPeripherals];//开始扫描外设
        }
#endif
    }
}

- (void)setUpView {
    self.navigationItem.title = @"连接设备";
    [self baseSetup:PageGobackTypePop];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.tableView reloadData];
}

#pragma mark -- tableView设置
- (UITableView*)tableView {
    if (_tableView==nil) {
        _tableView=[[UITableView alloc] init];
        _tableView.frame=CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-64);
        _tableView.delegate=self;
        _tableView.dataSource=self;
        [self.tableView registerNib:[UINib nibWithNibName:@"BluetoothListCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"BluetoothListCell"];
        self.tableView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

//设置tableview行
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger nNums =  [[CBLECenterMnger shareMnger].dataPherals totalNums];
    return nNums;
}

//设置行高
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BluetoothListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BluetoothListCell" forIndexPath:indexPath];
    CDataPheralInfo *data = [[CBLECenterMnger shareMnger].dataPherals dataWithIndex:indexPath.row];
    cell.dataInfo = data;
    return cell;
}

//点击事件
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CDataPheralInfo *pheral = [[CBLECenterMnger shareMnger].dataPherals dataWithIndex:indexPath.row];

    //NSLog(@"选择的row:%ld,正在连接的设备：%@,%@",(long)indexPath.row,pheral.peripheral.name,pheral.adverMacAddr);
    [[CBLECenterMnger shareMnger] cmdConnect2Pheral:pheral];
    [self showSearchingIcon:YES];
    
#if 0
    JCBlutoothInfoModel *model = _sortArray[indexPath.row];
    NSLog(@"选择的row:%ld,正在连接的设备：%@,%@",(long)indexPath.row,model.peripheral.name,model.adverMacAddr);
    [_bluetoothManager connectToPeripheral:model.peripheral];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
#endif
}


- (void)reSearch:(UIBarButtonItem *)sender {
    [self startScanPeripherals];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self showSearchingIcon:YES];
    if (@available(iOS 10.0, *)) {
        _scanTimeOut = [NSTimer scheduledTimerWithTimeInterval:SearchOutTime repeats:NO block:^(NSTimer * _Nonnull timer) {
            [self->_scanTimer invalidate];
            self->_scanTimer = nil;
            [[CBLECenterMnger shareMnger] cmdStopScan];
            [self showSearchingIcon:NO];
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }];
    } else {
        // Fallback on earlier versions
    }
}

#pragma mark - 搜索设备
- (void)searchDevices:(UIButton *)sender {
    MLDLog(@"搜索设备");
    [[CBLECenterMnger shareMnger] cmdStopScan];
    //[_bluetoothManager reScan];
}





#pragma mark - 扫描定时器
- (void)startScanPeripherals {
    if (!_scanTimer) {
        [self showSearchingIcon:YES];
        _scanTimer = [NSTimer timerWithTimeInterval:ScanTimeInterval target:self selector:@selector(scanForPeripherals) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_scanTimer forMode:NSDefaultRunLoopMode];
    }
    if (_scanTimer && !_scanTimer.valid) {
        [_scanTimer fire];
    }
}

#pragma mark - 扫描外设
- (void)scanForPeripherals {
    [[CBLECenterMnger shareMnger] cmdStartScan];
    //[_bluetoothManager reScan];
}



#if 0
#pragma mark - 蓝牙及相关设置初始化
- (void)setUpBluetooth {
    _allBlutoothModel = [NSMutableArray array];
    _bluetoothManager = [JCBluetoothManager shareCBCentralManager];
    _bluetoothManager.delegate = self;
}

//蓝牙未开启状态提醒
- (void)bluetoothStateChange:(JCBluetoothManager *)manager state:(BluetoothOpenState)openState {
    MLDLog(@"蓝牙状态改变---");
    
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

//发现设备
- (void)foundPeripheral:(JCBluetoothManager *)manager peripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    // 1 - 创建外设模型
    JCBlutoothInfoModel *model = [[JCBlutoothInfoModel alloc]init];
    model.peripheral = peripheral;
    model.RSSI = RSSI;
    model.advertisementData = advertisementData;
    if (([peripheral.name isEqualToString:@""] || peripheral.name == nil)) {
        return;
    }
    //MLDLog(@"发现设备：%@,%@",peripheral.name,peripheral.identifier.UUIDString);
    
    // 2 -解析广播数据
    NSObject *value = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
    NSString *macStr = nil;
    if (![value isKindOfClass: [NSArray class]]){
        const char *valueString = [[value description] cStringUsingEncoding: NSUTF8StringEncoding];
        model.adverMacAddr = macStr;
        if (valueString != NULL) {//如果为空，则跳过，解决出现空指针bug
            NSString *value = [NSString stringWithFormat:@"%s",valueString];
            value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
            value = [value stringByReplacingOccurrencesOfString:@"<" withString:@""];
            value = [value stringByReplacingOccurrencesOfString:@">" withString:@""];
            model.adverMacAddr = value;
        }
    }
    
    // 3 - 第一次扫描到的设备，添加进数组中
    if (_allBlutoothModel.count == 0) {
        [_allBlutoothModel addObject:model];
    } else {
        //4 - 遍历数组中的蓝牙模型，更新原有的数据（主要是更新信号强度）
        for (NSInteger i = 0; i < _allBlutoothModel.count; i++) {
            JCBlutoothInfoModel *primaryModel = _allBlutoothModel[i];
            CBPeripheral *per = primaryModel.peripheral;
            if ([peripheral.identifier.UUIDString isEqualToString:per.identifier.UUIDString]) {
                [_allBlutoothModel replaceObjectAtIndex:i withObject:model];//更新数组中的数据
                // 5 - 数组数据源中的模型 按信号值排序
                _sortArray = [NSMutableArray arrayWithArray:[_allBlutoothModel sortedArrayUsingComparator:^NSComparisonResult(JCBlutoothInfoModel *p1, JCBlutoothInfoModel *p2){
                    return [p2.RSSI compare:p1.RSSI];
                }]];
                // 6 - 刷新列表
                [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
        // 7 - 若未有包含过此设备，则将其添加进数组中
        if (![_allBlutoothModel containsObject:model]) {
            [_allBlutoothModel addObject:model];
        }
    }
}



#pragma mark - 蓝牙相关代理方法
//连接蓝牙成功调用
- (void)bluetoothManager:(JCBluetoothManager *)manager didSucceedConectPeripheral:(CBPeripheral *)peripheral {
    for (NSInteger i = 0; i < _allBlutoothModel.count; i++) {
        JCBlutoothInfoModel *primaryModel = _allBlutoothModel[i];
        CBPeripheral *per = primaryModel.peripheral;
        if ([peripheral.identifier.UUIDString isEqualToString:per.identifier.UUIDString]) {
            MLDLog(@"连接成功的外设信息：%@",primaryModel.advertisementData);
        }
    }
    
    [_scanTimer invalidate];
    _scanTimer = nil;
    [_scanTimeOut invalidate];
    _scanTimeOut = nil;
    [[CBLECenterMnger shareMnger] cmdStopScan];
    //[_bluetoothManager stopScan];
    //_bluetoothManager.delegate = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    //提示框提示调用成功
    NSString *tip = [NSString stringWithFormat:@"蓝牙连接成功: %@,状态：%@",peripheral.name,peripheral.state==2?@"connected":@""];
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:tip preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self popVC];
        if (self.updateMainPageRightBtn) {
            self.updateMainPageRightBtn();
        }
    }];
    [alertC addAction:action];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:nil];
}




-(void)bluetoothManager:(JCBluetoothManager *)manager didFailConectPeripheral:(CBPeripheral *)peripheral {
    //    [SVProgressHUD dismiss];
    //    [SVProgressHUD showInfoWithStatus:@"连接失败！"];
}




#endif

@end
