//
//  InteractivePopGestureDelegate.m
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "InteractivePopGestureDelegate.h"
#import <objc/runtime.h>
@interface UINavigationController (RetainPopDelegate)

@property (strong, nonatomic) id popDelegate;

@end

@implementation UINavigationController (RetainPopDelegate)

- (void)setPopDelegate:(id)popDelegate {
    objc_setAssociatedObject(self, @selector(popDelegate), popDelegate, OBJC_ASSOCIATION_RETAIN);
}
- (id)popDelegate {
    return objc_getAssociatedObject(self, _cmd);
}

@end

@interface InteractivePopGestureDelegate ()

@property (weak, nonatomic) UINavigationController *navigationViewController;

@end

@implementation InteractivePopGestureDelegate

+ (instancetype)interactivePopGestureDelegateWithNavigationViewController:(UINavigationController *)navigationViewController {
    
    return [[[self class] alloc] initWithNavigationViewController:navigationViewController];
}

- (instancetype)initWithNavigationViewController:(UINavigationController *)navigationViewController {
    
    if (self = [super init]) {
        _navigationViewController = navigationViewController;
        _navigationViewController.popDelegate = self; //利用Navigation保持代理不被释放
    }
    return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if ([self.navigationViewController.transitionCoordinator isAnimated] || (self.navigationViewController.viewControllers.count < 2)) {
        return NO;
    } else {
        return YES;
    }
}

@end

