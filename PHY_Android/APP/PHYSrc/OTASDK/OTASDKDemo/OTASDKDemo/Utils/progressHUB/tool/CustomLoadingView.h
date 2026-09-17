//
//  CustomLoadingView.h
//  progressHUD
//
//  Created by 刘燕鲁 on 16/12/29.
//  Copyright © 2016年 刘燕鲁. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomLoadingView : UIView

@property (nonatomic,strong)UILabel *loadLabel;

+ (id)sharedLoadingView:(BOOL)isInteractive;
- (void)beginAnimation;
- (void)endAnimation;

@end
