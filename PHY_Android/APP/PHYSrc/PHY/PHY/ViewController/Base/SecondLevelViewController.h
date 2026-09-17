//
//  SecondLevelViewController.h
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SecondLevelViewController : BaseViewController
//点击空白处隐藏键盘
- (void)viewAddEndEditingGesture;
- (void)backArrowSet;
- (void)dismiss;
@end

NS_ASSUME_NONNULL_END
