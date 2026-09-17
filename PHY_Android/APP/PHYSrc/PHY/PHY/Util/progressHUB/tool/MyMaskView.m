//
//  MyMaskView.m
//  progressHUD
//
//  Created by 刘燕鲁 on 16/12/29.
//  Copyright © 2016年 刘燕鲁. All rights reserved.
//

#import "MyMaskView.h"

@implementation MyMaskView

- (id)initWithFrame:(CGRect)frame bgColor:(UIColor *)bgColor cornerRadius:(CGFloat)cornerRadius
{
    if (self = [super initWithFrame:frame]) {
        if (bgColor) {
            self.backgroundColor = bgColor;
        }else{
            self.backgroundColor = [UIColor whiteColor];
        }
        
        if (cornerRadius > 0) {
            self.layer.cornerRadius = cornerRadius;
            self.layer.masksToBounds = YES;
        }
    }
    return self;
}

+ (MyMaskView *)maskViewWithFrame:(CGRect)frame bgImageName:(NSString *)bgImageName
{
    UIImage *image = [UIImage imageNamed:bgImageName];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:frame];
    imgView.image = image;
    return (MyMaskView *)imgView;
}

@end
