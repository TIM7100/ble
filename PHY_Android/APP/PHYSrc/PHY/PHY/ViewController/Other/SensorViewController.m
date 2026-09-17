//
//  sensorViewController.m
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "SensorViewController.h"
#import "JCBluetoothManager.h"
#import "JCDataConvert.h"
#import "CBLECenterMnger.h"
#import "CBLEDataMsg.h"

@interface SensorViewController ()<CDataPheralInfoDelegate>
{//加速度传感器
    
}
@property (nonatomic, weak) JCBluetoothManager *bluetoothManager;
@property (weak, nonatomic) IBOutlet UILabel *XLabel;
@property (weak, nonatomic) IBOutlet UILabel *YLabel;
@property (weak, nonatomic) IBOutlet UILabel *ZLabel;
//动画 立方体六个面集合
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *imageViewArray;
//立方体所在的区域
@property (weak, nonatomic) IBOutlet UIView *contentView;
//旋转角度
@property (nonatomic, assign) CGPoint diceAngle;
//传入的坐标值
@property(nonatomic,assign)float x;
@property(nonatomic,assign)float y;
@property(nonatomic,assign)float z;
@end

@implementation SensorViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
    
    [CBLECenterMnger shareMnger].curPheral.delegate = self;
    [[CBLECenterMnger shareMnger] wristCmdStartSensor:YES];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.barTintColor = Color_navPageButton_Green;
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
    [[CBLECenterMnger shareMnger] wristCmdStartSensor:NO];
    [CBLECenterMnger shareMnger].curPheral.delegate = nil;
    //[_bluetoothManager stopAcceleratorSensor];//停止运动加速器传感器
}
- (void)setUpView{
    self.navigationItem.title = @"传感器";
    [self baseSetup:PageGobackTypePop];
    self.view.backgroundColor = [UIColor whiteColor];
    //设置动画
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(viewTransform:)];
    [self.contentView addGestureRecognizer:pan];
    
    //add cube face 1
    CATransform3D diceTransform = CATransform3DIdentity;
    diceTransform = CATransform3DTranslate(diceTransform, 0, 0, 75);
    [self addFace:0 withTransform:diceTransform];
    
    //add cube face 2
    diceTransform = CATransform3DTranslate(CATransform3DIdentity, 75, 0, 0);
    diceTransform = CATransform3DRotate(diceTransform, M_PI_2, 0, 1, 0);
    [self addFace:1 withTransform:diceTransform];
    
    //add cube face 3
    //move this code after the setup for face no. 6 to enable button
    diceTransform = CATransform3DTranslate(CATransform3DIdentity, 0, -75, 0);
    diceTransform = CATransform3DRotate(diceTransform, M_PI_2, 1, 0, 0);
    [self addFace:2 withTransform:diceTransform];
    
    //add cube face 4
    diceTransform = CATransform3DTranslate(CATransform3DIdentity, 0, 75, 0);
    diceTransform = CATransform3DRotate(diceTransform, -M_PI_2, 1, 0, 0);
    [self addFace:3 withTransform:diceTransform];
    
    //add cube face 5
    diceTransform = CATransform3DTranslate(CATransform3DIdentity, -75, 0, 0);
    diceTransform = CATransform3DRotate(diceTransform, -M_PI_2, 0, 1, 0);
    [self addFace:4 withTransform:diceTransform];
    
    //add cube face 6
    diceTransform = CATransform3DTranslate(CATransform3DIdentity, 0, 0, -75);
    diceTransform = CATransform3DRotate(diceTransform, M_PI, 0, 1, 0);
    [self addFace:5 withTransform:diceTransform];
    
    self.x =0;
    self.y = 0;
    self.z = 0;
}

#pragma mark - 蓝牙及相关设置初始化

-(void)accSensorDataUpdate:(CBLECenterMnger *)manager feedBackInfo:(MsgDataWristAck *)ackData{
    
    self.x = 1.00 * ackData.X/1024;///1024
    self.y = 1.00 * ackData.Y/1024;
    self.z = 1.00 * ackData.Z/1024;
    
    CGFloat angleX = self.diceAngle.x + (self.x/10);
    CGFloat angleY = self.diceAngle.y - (self.y/10);
    
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1 / 50;
    transform = CATransform3DRotate(transform, angleX, 0, 1, 0);
    transform = CATransform3DRotate(transform, angleY, 1, 0, 0);
    self.diceAngle = CGPointMake(angleX, angleY);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.XLabel setText:[NSString stringWithFormat:@"X:%.2f",self.x]];
        if (self.y >1.5) {
            [self.YLabel setText:[NSString stringWithFormat:@"Y:%.2f",0.00]];
        } else if (self.y < -1.5) {
            [self.YLabel setText:[NSString stringWithFormat:@"Y:%.2f",-0.00]];
        } else {
            [self.YLabel setText:[NSString stringWithFormat:@"Y:%.2f",self.y]];
        }
        
        [self.ZLabel setText:[NSString stringWithFormat:@"Z:%.2f",self.z]];
        self.contentView.layer.sublayerTransform = transform;
    });
}

-(void)updateAcceleratedSensorDataback:(JCBluetoothManager *)manager feedBackInfo:(AcceleratedSensorModel *)model{
    AcceleratedSensorModel *acceleratedSensorModel = model;
    self.x = 1.00 * acceleratedSensorModel.acceleratedXValue/1024;///1024
    self.y = 1.00 * acceleratedSensorModel.acceleratedYValue/1024;
    self.z = 1.00 * acceleratedSensorModel.acceleratedZValue/1024;

    CGFloat angleX = self.diceAngle.x + (self.x/10);
    CGFloat angleY = self.diceAngle.y - (self.y/10);
    
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1 / 50;
    transform = CATransform3DRotate(transform, angleX, 0, 1, 0);
    transform = CATransform3DRotate(transform, angleY, 1, 0, 0);
    self.diceAngle = CGPointMake(angleX, angleY);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.XLabel setText:[NSString stringWithFormat:@"X:%.2f",self.x]];
        if (self.y >1.5) {
            [self.YLabel setText:[NSString stringWithFormat:@"Y:%.2f",0.00]];
        } else if (self.y < -1.5) {
            [self.YLabel setText:[NSString stringWithFormat:@"Y:%.2f",-0.00]];
        } else {
            [self.YLabel setText:[NSString stringWithFormat:@"Y:%.2f",self.y]];
        }
        
        [self.ZLabel setText:[NSString stringWithFormat:@"Z:%.2f",self.z]];
         self.contentView.layer.sublayerTransform = transform;
    });
}

- (void)addFace:(NSInteger)index withTransform:(CATransform3D)transform{
    UIImageView *face = (UIImageView *)self.imageViewArray[index];
    [self.contentView addSubview:face];
    
    CGSize containerSize = self.contentView.bounds.size;
    face.center = CGPointMake(containerSize.width / 2.0,
                              containerSize.height / 2.0);
    face.layer.transform = transform;
    face.layer.doubleSided = NO;
}

- (void)viewTransform:(UIPanGestureRecognizer *)sender{
    CGPoint point = [sender translationInView:self.contentView];
    CGFloat angleX = self.diceAngle.x + (point.x/30);
    CGFloat angleY = self.diceAngle.y - (point.y/30);
    
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1 / 500;
    transform = CATransform3DRotate(transform, angleX, 0, 1, 0);
    transform = CATransform3DRotate(transform, angleY, 1, 0, 0);
    self.contentView.layer.sublayerTransform = transform;
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        self.diceAngle = CGPointMake(angleX, angleY);
    }
}
@end
