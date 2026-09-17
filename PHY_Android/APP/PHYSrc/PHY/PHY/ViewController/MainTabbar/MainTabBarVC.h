//
//  MainTabBarVC.h
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MainTabBarVC : UITabBarController<UITabBarControllerDelegate>
-(id)getCurrentViewController;
@end

NS_ASSUME_NONNULL_END
