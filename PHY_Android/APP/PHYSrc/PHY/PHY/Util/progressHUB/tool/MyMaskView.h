//
//  MyMaskView.h
//  progressHUD
//
//  Created by 刘燕鲁 on 16/12/29.
//  Copyright © 2016年 刘燕鲁. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyMaskView : UIView

- (id)initWithFrame:(CGRect)frame bgColor:(UIColor *)bgColor cornerRadius:(CGFloat)cornerRadius;
+ (MyMaskView *)maskViewWithFrame:(CGRect)frame bgImageName:(NSString *)bgImageName;

@end
