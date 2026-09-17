//
//  MainCollectionViewCell.m
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "MainCollectionViewCell.h"

@implementation MainCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

-(void)renderWithIndexPath:(NSInteger)row{
    switch (row) {
        case 0:
            self.cellImageView.image = [UIImage imageNamed:@"传感器"];
            self.cellLabel.text = @"传感器";
            break;
        case 1:
            self.cellImageView.image = [UIImage imageNamed:@"心率"];
            self.cellLabel.text = @"心率";
            break;
        case 2:
            self.cellImageView.image = [UIImage imageNamed:@"LED"];
            self.cellLabel.text = @"LED灯控";
            break;
        case 3:
            self.cellImageView.image = [UIImage imageNamed:@"推送"];
            self.cellLabel.text = @"推送消息";
            break;
        case 4:
            self.cellImageView.image = [UIImage imageNamed:@"键盘"];
            self.cellLabel.text = @"键盘功能";
            break;
        case 5:
            self.cellImageView.image = [UIImage imageNamed:@"OTA"];
            self.cellLabel.text = @"OTA";
            break;
        default:
            break;
    }
}
@end
