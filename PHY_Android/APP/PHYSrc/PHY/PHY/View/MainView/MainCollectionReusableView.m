//
//  MainCollectionReusableView.m
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "MainCollectionReusableView.h"

@implementation MainCollectionReusableView

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];

    self.connectedDeviceLabel = [[UILabel alloc]initWithFrame:CGRectMake(25, 15, SCREEN_WIDTH-50, 20)];
    self.connectedDeviceLabel.text = @"已连接设备：无";
    self.connectedDeviceLabel.textColor = [UIColor whiteColor];
    self.connectedDeviceLabel.font = Font_Title;
    [self addSubview:self.connectedDeviceLabel];
    
    self.batteryStatusLabel = [[UILabel alloc]initWithFrame:CGRectMake(25, 45, SCREEN_WIDTH-50, 20)];
    self.batteryStatusLabel.text = @"";
    self.batteryStatusLabel.textColor = [UIColor whiteColor];
    self.batteryStatusLabel.font = Font_Title;
    [self addSubview:self.batteryStatusLabel];
    
    self.btnReboot = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnReboot setTitle:@"REBOOT" forState:UIControlStateNormal];
    _btnReboot.frame = CGRectMake(SCREEN_WIDTH-100, 35, 70, 30);
    _btnReboot.backgroundColor = [UIColor darkGrayColor];
    _btnReboot.titleLabel.font = [UIFont systemFontOfSize:13];
    [_btnReboot setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    _btnReboot.hidden = YES;
    [self addSubview:_btnReboot];
}
@end
