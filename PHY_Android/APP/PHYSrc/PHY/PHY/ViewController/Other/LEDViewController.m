//
//  LEDViewController.m
//  PHY
//
//  Created by Han on 2018/10/9.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "LEDViewController.h"
#import "ValueSlider.h"
#import "JCBluetoothManager.h"
#import "JCDataConvert.h"
#import "CBLECenterMnger.h"

@interface LEDViewController ()<JCBluetoothManagerDelegate>
@property (strong, nonatomic) ValueSlider  *redSlider;
@property (strong, nonatomic) ValueSlider  *greenSlider;
@property (strong, nonatomic) ValueSlider  *blueSlider;
@property (assign, nonatomic) float  redOldValue;
@property (assign, nonatomic) float  greenOldValue;
@property (assign, nonatomic) float  blueOldValue;
//@property (nonatomic, weak) JCBluetoothManager *bluetoothManager;
@end

@implementation LEDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
    //[self setUpBluetooth];
}

- (void)setUpView{
    self.navigationItem.title = @"LED灯控";
    [self baseSetup:PageGobackTypePop];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.barTintColor = Color_navPageButton_Green;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

-(void)setView{
    //R
    UILabel *redLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 50, 15, 15)];
    redLabel.text = @"R";
    [self.view addSubview:redLabel];
    
    __weak typeof(self) weakSelf = self;
    self.redSlider = [[ValueSlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(redLabel.frame)+10, redLabel.center.y-15, self.view.bounds.size.width - (CGRectGetMaxX(redLabel.frame)+10)-20, 30.0)];
    self.redSlider.minimumValue = 0;
    self.redSlider.maximumValue = 100;
    self.redSlider.thumbTintColor = [UIColor redColor];
    self.redSlider.minimumTrackTintColor = [UIColor redColor];
    self.redSlider.maximumTrackTintColor = [[UIColor lightGrayColor] colorWithAlphaComponent:.5];
    [self.view addSubview:self.redSlider];
    
    self.redSlider.touchUpInside = ^(ValueSlider *slider) {
        weakSelf.redSlider.valueText = [NSString stringWithFormat:@"%.1f", slider.value];
        NSString *valueStr = [[JCDataConvert ToHex:(int)slider.value] stringByAppendingFormat:@"%@",[JCDataConvert ToHex:LAMPCHANNELONE]];
        //免去命令过于频繁，只有前后两个数变化大于1时发送
        float dotoneValue = [[NSString stringWithFormat:@"%.1f", slider.value] floatValue];
        float fabValue = fabsf(slider.value - weakSelf.redOldValue);//取绝对值
        if (fabValue > 2) {
            //[[CBLECenterMnger shareMnger] wristCmdSetLED:MSG_LED_CHANNEL_R nVal:(int)slider.value];
            //[weakSelf.bluetoothManager startLedSetting:valueStr];
            [weakSelf writeCmd:MSG_LED_CHANNEL_R nVal:(int)slider.value];
            weakSelf.redOldValue = dotoneValue;
        }
    };

    //G
    UILabel *greenLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(self.redSlider.frame)+50, 15, 15)];
    greenLabel.text = @"G";
    [self.view addSubview:greenLabel];
    
    self.greenSlider = [[ValueSlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(greenLabel.frame)+10, greenLabel.center.y-15, self.view.bounds.size.width - (CGRectGetMaxX(greenLabel.frame)+10)-20, 30.0)];
    self.greenSlider.minimumValue = .0;
    self.greenSlider.maximumValue = 100.0;
    self.greenSlider.thumbTintColor = [UIColor greenColor];
    self.greenSlider.minimumTrackTintColor = [UIColor greenColor];
    self.greenSlider.maximumTrackTintColor = [[UIColor lightGrayColor] colorWithAlphaComponent:.5];
    [self.view addSubview:self.greenSlider];
    
    self.greenSlider.touchUpInside = ^(ValueSlider *slider) {
        weakSelf.greenSlider.valueText = [NSString stringWithFormat:@"%.1f", slider.value];
        NSString *valueStr = [[JCDataConvert ToHex:(int)slider.value] stringByAppendingFormat:@"%@",[JCDataConvert ToHex:LAMPCHANNELTWO]];

        float dotoneValue = [[NSString stringWithFormat:@"%.1f", slider.value] floatValue];
        float fabValue = fabsf(slider.value - weakSelf.greenOldValue);//取绝对值
        if (fabValue > 1) {
            [weakSelf writeCmd:MSG_LED_CHANNEL_G nVal:(int)slider.value];
            //[[CBLECenterMnger shareMnger] wristCmdSetLED:MSG_LED_CHANNEL_G nVal:(int)slider.value];
            //[weakSelf.bluetoothManager startLedSetting:valueStr];
            weakSelf.redOldValue = dotoneValue;
        }
    };
    
    //B
    UILabel *blueLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(self.greenSlider.frame)+50, 15, 15)];
    blueLabel.text = @"B";
    [self.view addSubview:blueLabel];
    
    self.blueSlider = [[ValueSlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(blueLabel.frame)+10, blueLabel.center.y-15, self.view.bounds.size.width - (CGRectGetMaxX(blueLabel.frame)+10)-20, 30.0)];
    self.blueSlider.minimumValue = .0;
    self.blueSlider.maximumValue = 100.0;
    self.blueSlider.thumbTintColor = [UIColor blueColor];
    self.blueSlider.minimumTrackTintColor = [UIColor blueColor];
    self.blueSlider.maximumTrackTintColor = [[UIColor lightGrayColor] colorWithAlphaComponent:.5];
    [self.view addSubview:self.blueSlider];
    
    self.blueSlider.touchUpInside = ^(ValueSlider *slider) {
        weakSelf.blueSlider.valueText = [NSString stringWithFormat:@"%.1f", slider.value];
        NSString *valueStr = [[JCDataConvert ToHex:(int)slider.value] stringByAppendingFormat:@"%@",[JCDataConvert ToHex:LAMPCHANNELTHREE]];

        float dotoneValue = [[NSString stringWithFormat:@"%.1f", slider.value] floatValue];
        float fabValue = fabsf(slider.value - weakSelf.blueOldValue);//取绝对值
        if (fabValue > 1) {
            [weakSelf writeCmd:MSG_LED_CHANNEL_B nVal:(int)slider.value];
            //[[CBLECenterMnger shareMnger] wristCmdSetLED:MSG_LED_CHANNEL_G nVal:(int)slider.value];
            //[weakSelf.bluetoothManager startLedSetting:valueStr];
            weakSelf.redOldValue = dotoneValue;
        }
    };
}

#pragma mark - 蓝牙及相关设置初始化
- (void)setUpBluetooth {
    //_bluetoothManager = [JCBluetoothManager shareCBCentralManager];
    //_bluetoothManager.delegate = self;
}

-(void)writeCmd:(NSInteger)nChannel nVal:(NSInteger)nVal{
    
    [[CBLECenterMnger shareMnger] wristCmdSetLED:nChannel nVal:nVal];
}


@end
