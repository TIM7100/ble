//
//  ViewController.m
//  PHY
//
//  Created by Han on 2018/9/26.
//  Copyright © 2018年 phy. All rights reserved.
//
#import "MainViewController.h"
#import "MainCollectionReusableView.h"
#import "MainCollectionViewCell.h"
#import "SensorViewController.h"
#import "BluetoothListViewController.h"
#import "JCBluetoothManager.h"
#import "HeartRateViewController.h"
#import "LEDViewController.h"
#import "PushNotificationViewController.h"
#import "DevelopmentBoardKeyboardViewController.h"
#import "OTAUpgradeViewController.h"

#import "CBLECenterMnger.h"

#define k_CellWidth 100

@interface MainViewController ()<UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    JCBluetoothManagerDelegate,
    MBProgressHUDDelegate>
{

}

@property(nonatomic,strong)UICollectionView     *collectionView;
@property(nonatomic,strong)UIButton             *rightItemBtn;
@property(nonatomic,strong)NSString             *rightBtnTitle;
@property(nonatomic,strong)NSString             *connectedMacAddress;
@property(nonatomic,strong)NSString             *connectedBatteryLevel;
@property(nonatomic,strong)NSString             *seleMacAddress;
@property(nonatomic,strong)NSString             *originalMacAddress;
@property(nonatomic,strong)NSString             *originalUUID;
@end

@implementation MainViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = Color_navPageButton_Green;
    self.rightBtnTitle = @"连接";
    [self createNav];
    [self setCollectionView];
    [self.collectionView registerNib:[UINib nibWithNibName:@"MainCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"MainCollectionViewCell"];
    [self.collectionView registerClass:[MainCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"MainCollectionReusableView"];
    
    ADD_MESSAGE(BLEMSG_CENTER_POWERON, msgForBLEPowerOn);
    ADD_MESSAGE(BLEMSG_PHERAL_CONNECT_RST, msgForPheralConnect);
    ADD_MESSAGE(BLEMSG_PHERAL_DISCONNECT, msgForPheralConnect);
    ADD_MESSAGE(BLEMSG_PHERAL_UPDATE_INFO, msgForPheralUpdate);
    
    //蓝牙初始化
    [CBLECenterMnger shareMnger];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = Color_navPageButton_Green;
    self.navigationController.navigationBar.hidden = YES;
    
    [self settingWhetherDeviceIsConnected];
    [self.collectionView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

#pragma makr 蓝牙开关机状态改变的消息提醒
- (void)msgForBLEPowerOn{
    
    if ( [CBLECenterMnger BLEIsPowerOff] ){
        NSString *tip = [NSString stringWithFormat:@"蓝牙处于关闭状态，请连接!"];
        [self showMessageAutoHide:tip afterDelay:2.5];
    } else {
        NSLog(@"蓝牙已经打开，可以开始查找蓝牙外部设备！\n");
    }
}

-(void)msgForPheralConnect{
    
    if ( [[CBLECenterMnger shareMnger] isConnectOK] ){
        
        self.rightBtnTitle = @"断开";
        [self.rightItemBtn setTitle:self.rightBtnTitle forState:UIControlStateNormal];
        
        CDataPheralInfo *pheral = [CBLECenterMnger shareMnger].curPheral;
        self.connectedMacAddress = pheral.adverMacAddr;
        self.originalMacAddress  = pheral.adverMacAddr;
        self.seleMacAddress      = pheral.adverMacAddr;
        [self.collectionView reloadData];
    } else {
        self.rightBtnTitle = @"连接";
        [self.rightItemBtn setTitle:self.rightBtnTitle forState:UIControlStateNormal];
        self.connectedMacAddress = @"未连接";
        [self.collectionView reloadData];
    }
}

-(void)msgForPheralUpdate{
    
    [self msgForPheralConnect];
    [self.collectionView reloadData];
}

-(void)setCollectionView{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.sectionInset = UIEdgeInsetsMake(10, 30, 10, 30);
    flowLayout.itemSize =CGSizeMake((SCREEN_WIDTH-20-10-50)/2, (SCREEN_WIDTH-20-10-50)/2);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 84,SCREEN_WIDTH, SCREEN_HEIGHT-84) collectionViewLayout:flowLayout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.collectionView];
    self.collectionView.scrollEnabled = YES;
    self.collectionView.delegate= self;
    self.collectionView.dataSource = self;
}
// 创建“导航栏”
- (void)createNav{
    // 在主线程异步加载，使下面的方法最后执行，防止其他的控件挡住了导航栏
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *navView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 84)];
        navView.backgroundColor = Color_White;
        [self.view addSubview:navView];
        self.rightItemBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.rightItemBtn setTitle:self.rightBtnTitle forState:UIControlStateNormal];
        self.rightItemBtn.titleLabel.font = Font_NavBtn_Title;
        [self.rightItemBtn setTitleColor:Color_navPageButton_Green forState:UIControlStateNormal];
        self.rightItemBtn.frame = CGRectMake(SCREEN_WIDTH-40-20, 40, 40, 44);
        [self.rightItemBtn addTarget:self action:@selector(bluetooth) forControlEvents:UIControlEventTouchUpInside];
        [navView addSubview:self.rightItemBtn];
        UIImageView *logImageView = [[UIImageView alloc]initWithFrame:CGRectMake(20, 50, 120, 25)];
        logImageView.image = [UIImage imageNamed:@"phy"];
        [navView addSubview:logImageView];
    });
}

// 连接
- (void)bluetooth{
    if ([self.rightBtnTitle isEqualToString:@"断开"]){
        self.rightBtnTitle = @"连接";
        [self.rightItemBtn setTitle:self.rightBtnTitle forState:UIControlStateNormal];
        [[CBLECenterMnger shareMnger] cmdDisconnectCurPheral];
        self.connectedBatteryLevel = @"无";
        self.connectedMacAddress = @"未连接";
        [self.collectionView reloadData];  
    }else{
        BluetoothListViewController *bluetoothVC = [[BluetoothListViewController alloc]init];
        __weak typeof(self)weakself = self;
        bluetoothVC.updateMainPageRightBtn = ^{
            weakself.rightBtnTitle = @"断开";
            [weakself.rightItemBtn setTitle:self.rightBtnTitle forState:UIControlStateNormal];
        };
        bluetoothVC.updateMacAddress = ^(NSString * _Nonnull macAddress,NSString * _Nonnull originalMacAddress,NSString * _Nonnull originalUUID) {
            self.connectedMacAddress = macAddress;
            self.originalMacAddress = originalMacAddress;
            self.seleMacAddress = macAddress;
            self.originalUUID = originalUUID;
            [self.collectionView reloadData];
        };
         bluetoothVC.updateBatteryLevel = ^(NSString * _Nonnull batteryLevel) {
             self.connectedBatteryLevel = batteryLevel;
             [self.collectionView reloadData];
         };
        [self dsPushViewController:bluetoothVC animated:YES];
    }
}




#pragma mark HUD的代理方法,关闭HUD时执行
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [self settingWhetherDeviceIsConnected];
}

-(void)settingWhetherDeviceIsConnected {
    
    if ( [[CBLECenterMnger shareMnger] isConnectOK] ) {
        self.rightBtnTitle = @"断开";
        self.connectedMacAddress = self.seleMacAddress;
        [self.rightItemBtn setTitle:self.rightBtnTitle forState:UIControlStateNormal];
        [self.collectionView reloadData];
        NSLog(@"settingWhetherDeviceIsConnected::%@\r\n",self.connectedMacAddress);
    } else {
        self.rightBtnTitle = @"连接";
        self.connectedMacAddress = @"未连接";
        [self.rightItemBtn setTitle:self.rightBtnTitle forState:UIControlStateNormal];
        [self.collectionView reloadData];
    }
}

#pragma mark ---- UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 6;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (kind == UICollectionElementKindSectionHeader) {
        MainCollectionReusableView *headerRV = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"MainCollectionReusableView" forIndexPath:indexPath];
        [headerRV.btnReboot addTarget:self action:@selector(btnRebootBle:) forControlEvents:UIControlEventTouchUpInside];
        headerRV.connectedDeviceLabel.text = [NSString stringWithFormat:@"已连接设备：%@",self.connectedMacAddress==nil?@"未连接":self.connectedMacAddress];
//        headerRV.batteryStatusLabel.text = [NSString stringWithFormat:@"电池状态：%@",self.connectedBatteryLevel==nil?@"无":self.connectedBatteryLevel];
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        
        NSString *strTip1 = [NSString stringWithFormat:@"APP版本:%@  ",app_Version];
        NSString *strTip2 = @"";
        CDataPheralInfo *curPheral = [CBLECenterMnger shareMnger].curPheral;
        if ( curPheral != nil ){
            strTip2 = [curPheral fmtBootVer];
            headerRV.btnReboot.hidden = !curPheral.bIsInOTA;
        } else {
            headerRV.btnReboot.hidden = YES;
        }
        headerRV.batteryStatusLabel.text = [strTip1 stringByAppendingString:strTip2];
        
        return headerRV;
    }else{
        
        return nil;
    }
}

-(void)btnRebootBle:(UIButton*)btn{
    [[CBLECenterMnger shareMnger] otaCmd2App];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    MainCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MainCollectionViewCell" forIndexPath:indexPath];
    [cell renderWithIndexPath:indexPath.row];
    return cell;
}

#pragma mark ---- UICollectionViewDelegateFlowLayout

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 10.f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 10.f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    return (CGSize){SCREEN_WIDTH,70};
}

#pragma mark ---- UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"点击的collection:%ld",(long)indexPath.row);

    [self settingWhetherDeviceIsConnected];
    
    if ( ![[CBLECenterMnger shareMnger] isConnectOK] ) {
        NSString *tip = [NSString stringWithFormat:@"请先连接蓝牙设备！"];
        [self showMessageAutoHide:tip afterDelay:2.0];
        return;
    }
    //传感器
    if(indexPath.row == 0){
        SensorViewController *sensorvc = [[SensorViewController alloc]init];
        [self dsPushViewController:sensorvc animated:YES];
    }
    //心率
    else if(indexPath.row == 1){
        HeartRateViewController *vc = [[HeartRateViewController alloc]init];
        [self dsPushViewController:vc animated:YES];
    }
    //LED灯控
    else if(indexPath.row == 2){
        LEDViewController *vc = [[LEDViewController alloc]init];
        [self dsPushViewController:vc animated:YES];
    }
    //推送消息
    else if(indexPath.row == 3){
        PushNotificationViewController *vc = [[PushNotificationViewController alloc]init];
        [self dsPushViewController:vc animated:YES];
    }
    //键盘功能
    else if(indexPath.row == 4){
        NSString *tip = [NSString stringWithFormat:@"暂未实现"];
        //[self hudSetting:tip];
//        DevelopmentBoardKeyboardViewController *vc = [[DevelopmentBoardKeyboardViewController alloc]init];
//        [self dsPushViewController:vc animated:YES];
    }
    //OTA固件升级
    else if(indexPath.row == 5){
        OTAUpgradeViewController *vc = [[OTAUpgradeViewController alloc]init];
        vc.mscAddress = self.originalMacAddress;
        vc.originalUUID = self.originalUUID;
        vc.updateMacAddress = ^(NSString * _Nonnull macAddress,NSString * _Nonnull originalMacAddress,NSString * _Nonnull originalUUID) {
            self.connectedMacAddress = macAddress;
            self.originalMacAddress = originalMacAddress;
            self.seleMacAddress = macAddress;
            self.originalUUID = originalUUID;
            [self.collectionView reloadData];
        };
        vc.updateBatteryLevel = ^(NSString * _Nonnull batteryLevel) {
            self.connectedBatteryLevel = batteryLevel;
            [self.collectionView reloadData];
        };
        [self dsPushViewController:vc animated:YES];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    
}




#if 0
//蓝牙未开启状态提醒
- (void)bluetoothStateChange:(JCBluetoothManager *)manager state:(BluetoothOpenState)openState {
    MLDLog(@"蓝牙状态改变---");
    if (BluetoothOpenStateIsClosed == openState) {
        NSString *tip = [NSString stringWithFormat:@"蓝牙处于关闭状态，请连接"];
        [self hudSetting:tip];
    }
}

//连接蓝牙成功调用
- (void)bluetoothManager:(JCBluetoothManager *)manager didSucceedConectPeripheral:(CBPeripheral *)peripheral {
    NSString *tip = [NSString stringWithFormat:@"蓝牙连接成功: %@,状态：%@",peripheral.name,peripheral.state==2?@"connected":@""];
    //[self hudSetting:tip];
}

-(void)bluetoothManager:(JCBluetoothManager *)manager didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSString *tip = [NSString stringWithFormat:@"蓝牙断开连接: %@,状态：%@",peripheral.name,peripheral.state==0?@"disconnected":@""];
    //[self hudSetting:tip];
}


-(void)connectionSuccessful:(NSNotification*)noti{
    self.rightBtnTitle = @"断开";
    [self.rightItemBtn setTitle:self.rightBtnTitle forState:UIControlStateNormal];
}


-(void)bluetoothDisconnected:(NSNotification*)noti{
    self.rightBtnTitle = @"连接";
    [self.rightItemBtn setTitle:self.rightBtnTitle forState:UIControlStateNormal];
    self.connectedMacAddress = @"未连接";
    [self.collectionView reloadData];
}


- (void)setUpBluetooth{
    //_bluetoothManager = [JCBluetoothManager shareCBCentralManager];
    //_bluetoothManager.delegate = self;
}


#endif

@end
