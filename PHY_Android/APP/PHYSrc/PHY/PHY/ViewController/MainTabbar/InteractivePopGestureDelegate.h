//
//  InteractivePopGestureDelegate.h
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface InteractivePopGestureDelegate : NSObject
+ (instancetype)interactivePopGestureDelegateWithNavigationViewController:(UINavigationController *)navigationViewController;

- (instancetype)initWithNavigationViewController:(UINavigationController *)navigationViewController;
@end

NS_ASSUME_NONNULL_END
