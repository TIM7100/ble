//
//  bluetoothListViewController.m
//  PHY
//
//  Created by Han on 2018/9/28.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "BluetoothListViewController.h"
#import "BluetoothListCell.h"
#import "UpgradeModeViewController.h"
#import "OTAUpgradeViewController.h"

#define ScanTimeInterval        3.0
#define SearchOutTime           10

@interface BluetoothListViewController ()<UITableViewDelegate,UITableViewDataSource,JCBluetoothManagerDelegate>
@property (strong, nonatomic)  UITableView *tableView;
@property (strong, nonatomic) UIButton * stopBtn;
@property (nonatomic, weak) JCBluetoothManager              *bluetoothManager;
@property (nonatomic, strong) NSMutableArray                *allBlutoothModel;
@property (nonatomic, strong) NSMutableArray                *sortArray;
@property (nonatomic, strong) NSTimer                       *scanTimer;
@property (nonatomic, strong) NSTimer                       *scanTimeOut;
@property (nonatomic, strong) UIActivityIndicatorView       *animation;
@property(nonatomic,strong)NSString                         *connectedMacAddress;
@property(nonatomic,strong)NSString                         *connectedBatteryLevel;

@property(nonatomic,strong)NSString                         *originalMacAddress;
@property(nonatomic,strong)NSString                         *originalUUID;

@end

@implementation BluetoothListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
    [self addRightBtn];
    _sortArray = [NSMutableArray array];
    [self setUpBluetooth];//蓝牙初始化
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    if (_bluetoothManager.bluetoothState == BluetoothOpenStateIsOpen && _bluetoothManager.currentPeripheral == nil) {
        [self startScanPeripherals];//开始扫描外设
    } else if (_bluetoothManager.bluetoothState == BluetoothOpenStateIsClosed){
        //优化代码 -- 把这一段提取出来
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"请开启蓝牙连接设备" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alertC addAction:action];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:nil];
        //         [_animation stopAnimating];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
    [NotificationCenter addObserver:self selector:@selector(bluetoothGetBatteryLeve:) name:BluetoothGetBatteryLeve object:nil];
    [NotificationCenter addObserver:self selector:@selector(bluetoothGetMacAddress:) name:BluetoothGetMacAddress object:nil];
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
    [_bluetoothManager stopScan];
    //    _bluetoothManager.delegate = nil;
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
    self.originalMacAddress = originalMacAddress;
    self.originalUUID = originalUUID;
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
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (_bluetoothManager.bluetoothState == BluetoothOpenStateIsOpen && _bluetoothManager.currentPeripheral == nil) {
        [self startScanPeripherals];
    }
}

- (void)stop {
    self.stopBtn.selected = !self.stopBtn.selected;
    if(self.stopBtn.selected){
        [self.stopBtn setTitle:@"搜索" forState:UIControlStateNormal];
        [_scanTimer invalidate];
        _scanTimer = nil;
        [_scanTimeOut invalidate];
        _scanTimeOut = nil;
        [_bluetoothManager stopScan];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }else{
        [self.stopBtn setTitle:@"停止" forState:UIControlStateNormal];
        //    [_animation startAnimating];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        if (_bluetoothManager.bluetoothState == BluetoothOpenStateIsOpen && _bluetoothManager.currentPeripheral == nil) {
            [self startScanPeripherals];//开始扫描外设
        }
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
    return _sortArray.count;
}

//设置行高
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BluetoothListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BluetoothListCell" forIndexPath:indexPath];
    cell.blutoothInfo = _sortArray[indexPath.row];
    return cell;
}

//点击事件
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    JCBlutoothInfoModel *model = _sortArray[indexPath.row];
    NSLog(@"选择的row:%ld,正在连接的设备：%@,%@",(long)indexPath.row,model.peripheral.name,model.adverMacAddr);
    [_bluetoothManager connectToPeripheral:model.peripheral];

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)reSearch:(UIBarButtonItem *)sender {
    [self startScanPeripherals];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (@available(iOS 10.0, *)) {
        _scanTimeOut = [NSTimer scheduledTimerWithTimeInterval:SearchOutTime repeats:NO block:^(NSTimer * _Nonnull timer) {
            [self->_scanTimer invalidate];
            self->_scanTimer = nil;
            [self->_bluetoothManager stopScan];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }];
    } else {
        // Fallback on earlier versions
    }
}

#pragma mark - 搜索设备
- (void)searchDevices:(UIButton *)sender {
    MLDLog(@"搜索设备");
    [_bluetoothManager reScan];
}

#pragma mark - 蓝牙及相关设置初始化
- (void)setUpBluetooth {
    _allBlutoothModel = [NSMutableArray array];
    _bluetoothManager = [JCBluetoothManager shareCBCentralManager];
    _bluetoothManager.delegate = self;
}

#pragma mark - 蓝牙相关代理方法
//蓝牙未开启状态提醒
- (void)bluetoothStateChange:(JCBluetoothManager *)manager state:(BluetoothOpenState)openState {
    MLDLog(@"蓝牙状态改变---");
    if (BluetoothOpenStateIsClosed == openState) {//关闭状态
        [self.allBlutoothModel removeAllObjects];
        [self.sortArray removeAllObjects];
        [self.tableView reloadData];
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"请开启蓝牙连接设备" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alertC addAction:action];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:nil];
    } else {
        [self scan];
    }
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
    MLDLog(@"发现的设备广播中：%@",peripheral.identifier.UUIDString);

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
    [_bluetoothManager stopScan];
    //    _bluetoothManager.delegate = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    //提示框提示调用成功
    NSString *tip = [NSString stringWithFormat:@"蓝牙连接成功: %@,状态：%@",peripheral.name,peripheral.state==2?@"connected":@""];
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:tip preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
//        [self popVC];
//        if (self.updateMainPageRightBtn) {
//            self.updateMainPageRightBtn();
//        }
        OTAUpgradeViewController *vc = [[OTAUpgradeViewController alloc]init];
        vc.mscAddress = self.originalMacAddress;
        vc.originalUUID = self.originalUUID;
        [self dsPushViewController:vc animated:YES];

    }];
    [alertC addAction:action];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:nil];
}

-(void)bluetoothManager:(JCBluetoothManager *)manager didFailConectPeripheral:(CBPeripheral *)peripheral {
}

#pragma mark - 扫描定时器
- (void)startScanPeripherals {
    if (!_scanTimer) {
        _scanTimer = [NSTimer timerWithTimeInterval:ScanTimeInterval target:self selector:@selector(scanForPeripherals) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_scanTimer forMode:NSDefaultRunLoopMode];
    }
    if (_scanTimer && !_scanTimer.valid) {
        [_scanTimer fire];
    }
}

#pragma mark - 扫描外设
- (void)scanForPeripherals {
    [_bluetoothManager reScan];
}


@end
