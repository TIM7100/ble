//
//  MainTabBarVC.m
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "MainTabBarVC.h"
#import "MainViewController.h"
#import "InteractivePopGestureDelegate.h"
@interface MainTabBarVC ()<UITabBarControllerDelegate>
@property (nonatomic, strong) MainViewController      * mainVC;
@end

@implementation MainTabBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self setUpViewController];
    self.delegate = self;
    
}
- (void)setUpViewController {
    self.view.backgroundColor = Color_Background;
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName:Font_Tabbar_Title,
                                                        NSForegroundColorAttributeName:Color_Tabbar_Normal}
                                             forState:UIControlStateNormal];
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName:Font_Tabbar_Title,
                                                        NSForegroundColorAttributeName:Color_Tabbar_Selected}
                                             forState:UIControlStateSelected];
    
    [UITabBar appearance].tintColor = Color_Tabbar_Selected;
    [[UITabBar appearance] setBarTintColor:Color_White];
    
    //tabBar
//    _mainVC = [[MainViewController alloc] init];
//    UINavigationController *naviInfoVC = [self createNavigationControllerWithRootViewController:_mainVC title:@"资讯" image:ImageNamed(@"homepage_icon_information")];
//    [naviInfoVC.tabBarItem setSelectedImage:[ImageNamed(@"homepage_icon_information_chosen") imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
//    _disVC = [[DiscussionVC alloc] init];
//    UINavigationController *naviDisVC = [self createNavigationControllerWithRootViewController:_disVC title:@"论坛" image:ImageNamed(@"homepage_icon_BBS") selectedImv:ImageNamed(@"homepage_icon_BBS_chosen")];
//
//    _meVC = [[MeVC alloc] init];
//    UINavigationController *naviMeVC = [self createNavigationControllerWithRootViewController:_meVC title:@"账户" image:ImageNamed(@"homepage_icon_account") selectedImv:ImageNamed(@"homepage_icon_account_chosen")];
    
    self.tabBar.translucent = NO;
//    self.viewControllers = @[naviInfoVC/**navigaitonVCMoments,*/];
    
    UIView *vLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0.5)];
    vLine.backgroundColor = Color_Tabbar_LineColor;
    [self.tabBar addSubview:vLine];
}

- (UINavigationController *)createNavigationControllerWithRootViewController:(UIViewController *)viewController title:(NSString *)title image:(UIImage *)image {
    NSAssert(nil != viewController, @"rootViewController 参数不对");
    
    UINavigationController *result = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    result.tabBarItem.title = title;
    //    result.tabBarItem.image = image;
    result.tabBarItem.image = [image  imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    result.interactivePopGestureRecognizer.enabled = YES;
    result.interactivePopGestureRecognizer.delegate = [InteractivePopGestureDelegate interactivePopGestureDelegateWithNavigationViewController:result];
    
    return result;
}

- (UINavigationController *)createNavigationControllerWithRootViewController:(UIViewController *)viewController title:(NSString *)title image:(UIImage *)image selectedImv:(UIImage *)imvSelected{
    NSAssert(nil != viewController, @"rootViewController 参数不对");
    
    UINavigationController *result = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    result.tabBarItem.title = title;
    
    result.tabBarItem.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    result.tabBarItem.selectedImage = [imvSelected imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [result.tabBarItem setSelectedImage:[imvSelected imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    result.interactivePopGestureRecognizer.enabled = YES;
    result.interactivePopGestureRecognizer.delegate = [InteractivePopGestureDelegate interactivePopGestureDelegateWithNavigationViewController:result];
    
    return result;
}


#pragma mark -- tabBarController delegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    
    UINavigationController *nav = (UINavigationController *)viewController;
    if ([nav.viewControllers[0] isKindOfClass:[MainViewController class]]) {
        [UserDefaults setObject:@"1" forKey:@"Setp"];
    }
//    else    if ([nav.viewControllers[0] isKindOfClass:[DiscussionVC class]]) {
//        [UserDefaults setObject:@"2" forKey:@"Setp"];
//    }else    if ([nav.viewControllers[0] isKindOfClass:[MeVC class]]) {
//        [UserDefaults setObject:@"3" forKey:@"Setp"];
//    }
    
//        if([nav.viewControllers[0] isKindOfClass:[MeVC class]])
    //    {
    //        if(![[UserManager sharedUserManager]isLogin])
    //        {
    //
    //            [[UserManager sharedUserManager]showLoginPage:viewController];
    //
    //            //            __weak typeof(self) weakSelf = self;
    //
    //            return NO;
    //        }else{
    //            return YES;
    //        }
    //    }
    return YES;
}

//获取当前显示在最前面的页面的vc
- (id)getCurrentViewController
{
    UINavigationController *navNow = [self.viewControllers objectAtIndex:self.selectedIndex];
    return [navNow.viewControllers objectAtIndex:[navNow.viewControllers count] - 1];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
