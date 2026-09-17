//
//  BaseViewController.h
//  PHY
//
//  Created by Han on 2018/9/26.
//  Copyright © 2018年 phy. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    PageGobackTypeNone,
    PageGobackTypeDismiss,
    PageGobackTypePop,
    PageGobackTypeRoot
}PageGobackType;

@interface BaseViewController : UIViewController
@property(nonatomic,assign)BOOL isRequestProcessing;//请求是否在处理中
/**
 页面提示信息
 
 @param gobackType 页面返回类型
 */
-(void)baseSetup:(PageGobackType)gobackType;

/**
 显示提示信息
 
 @param msg 要显示的消息内容
 */
-(void)showMessage:(NSString*)msg;

/**
 显示加载框
 
 @param msg 提示内容
 */
-(void)showLoading:(NSString *)msg;

/**
 隐藏加载框
 */
-(void)hideLoading;

/**
 用于push vc 隐藏tabbar
 
 @param vc 要push 的vc
 @param animated 动画效果
 */
-(void)dsPushViewController:(UIViewController *)vc animated:(BOOL)animated;

/**
 dismiss页面
 */
-(void)dismissVC;

/**
 popToRoot页面
 */
-(void)popToRoot;

/**
 返回任意一个页面
 */
-(void)popToViewControllerAtIndex:(NSInteger)index;

/**
 pop页面
 */
-(void)popVC;

@end
