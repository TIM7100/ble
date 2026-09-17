//
//  HeartRateViewController.m
//  PHY
//
//  Created by Han on 2018/10/8.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "HeartRateViewController.h"
#import "HeartBeat.h"
#import "HeartLive.h"
#import "JCBluetoothManager.h"
#import "JCDataConvert.h"
#import "CBLECenterMnger.h"
#import "CBLEDataMsg.h"

@interface HeartRateViewController ()<JCBluetoothManagerDelegate>
@property (strong, nonatomic) IBOutlet UIView *outView;
@property (strong, nonatomic) IBOutlet UIView *insideView;
@property (strong, nonatomic) IBOutlet UIImageView *heartImageView;
@property (weak, nonatomic) IBOutlet UILabel *heartRateLabel;
@property (strong, nonatomic) IBOutlet UILabel *unitLabel;
@property (strong, nonatomic) HeartLive *live;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic, weak) JCBluetoothManager *bluetoothManager;
@end

@implementation HeartRateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
    //[self setUpBluetooth];
    [[CBLECenterMnger shareMnger] wristCmdStartHR:YES];
    self.view.backgroundColor = Color_navPageButton_Green;
    ADD_MESSAGE(BLEMSG_PHERAL_HR_RAW, updateHDRawData:);
    ADD_MESSAGE(BLEMSG_PHERAL_HR_LAST, updateHDLastData:);
    
}
- (void)setUpView {
    self.navigationItem.title = @"心率";
    [self baseSetup:PageGobackTypePop];
    self.view.backgroundColor = [UIColor whiteColor];
    [self getHeartbeatRateDiagram];

}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.barTintColor = Color_navPageButton_Green;
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
    [self.timer invalidate];
    self.timer =nil;
    REMOVE_MESSAGE(BLEMSG_PHERAL_HR_RAW, nil);
    REMOVE_MESSAGE(BLEMSG_PHERAL_HR_LAST, nil);
    
    [[CBLECenterMnger shareMnger] wristCmdStartHR:NO];
    
    //[_bluetoothManager stopHeartRate];
}

-(void)getHeartbeatRateDiagram{
    
    self.outView.layer.cornerRadius = self.outView.frame.size.width/2;
    self.outView.layer.masksToBounds = YES;

    self.insideView.layer.cornerRadius = self.insideView.frame.size.width/2;
    self.insideView.layer.masksToBounds = YES;
    self.insideView.backgroundColor = Color_navPageButton_Green;

    [self heartAnimation];

    //创建了一个心电图的View
    self.live = [[HeartLive alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(self.outView.frame) + 20, SCREEN_WIDTH-20, 200)];
    [self.view addSubview:self.live];
    
}

- (void)heartAnimation{
    CABasicAnimation *anima = [CABasicAnimation animation];
    anima.keyPath = @"transform.scale";
    anima.toValue = @0.5;
    anima.repeatCount = MAXFLOAT;
    anima.duration = 0.3;
    anima.autoreverses = YES;
    [self.heartImageView.layer addAnimation:anima forKey:nil];
}

#pragma mark - 蓝牙及相关设置初始化
- (void)setUpBluetooth {
    //_bluetoothManager = [JCBluetoothManager shareCBCentralManager];
    //_bluetoothManager.delegate = self;
    //[_bluetoothManager startHeartRate];
}

//获取心率测量最终值
- (void)updateHDLastData:(NSNotification*)noti{
    
    MsgDataWristAck *ackData = noti.object;
    self.heartRateValue = ackData.HRLastValue;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.heartRateLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)self.heartRateValue];//%@次/分
    });
}

- (void)updateHeartRateback:(nullable JCBluetoothManager *) manager feedBackInfo:(HeartRateModel *)model{
    HeartRateModel *heartRateModel = model;
    self.heartRateValue = heartRateModel.heartRateLastValue;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.heartRateLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)self.heartRateValue];//%@次/分
    });
}

//获取心率测量原始值
- (void)updateHDRawData:(NSNotification*)noti{
    MsgDataWristAck *ackData = noti.object;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:0];
    arr = ackData.HRRawDataArr;
    if (arr.count == 0) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0;i<16;i++) {
            NSData *heartRateLastValue = [arr objectAtIndex:i];
            NSUInteger heartRateLastIntValue = [JCDataConvert oneByteToDecimalUint:heartRateLastValue];
            NSNumber *n = [NSNumber numberWithDouble:[self getNumber:heartRateLastIntValue from:0 to:256]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.live drawRateWithPoint:n];
            });
            
        }
    });
}

- (void)updateHeartRateOriginalDataback:(JCBluetoothManager *)manager feedBackInfo:(HeartRateModel *)model{
    HeartRateModel *heartRateModel = model;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:0];
    arr = heartRateModel.heartRateOriginalDataArr;
    if (arr.count == 0) {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0;i<16;i++) {
            NSData *heartRateLastValue = [arr objectAtIndex:i];
            NSUInteger heartRateLastIntValue = [JCDataConvert oneByteToDecimalUint:heartRateLastValue];
            NSNumber *n = [NSNumber numberWithDouble:[self getNumber:heartRateLastIntValue from:0 to:256]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.live drawRateWithPoint:n];
            });
            
        }
    });
}

-(double)getNumber:(NSUInteger)value from:(int)from to:(int)to{
    double xinLv = (double)value;
    return -(xinLv-(from+to)/2)/((to-from)/2);    //-1~1
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
