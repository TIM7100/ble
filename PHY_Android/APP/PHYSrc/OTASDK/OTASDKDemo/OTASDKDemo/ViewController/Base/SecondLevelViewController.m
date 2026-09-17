//
//  SecondLevelViewController.m
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "SecondLevelViewController.h"

@interface SecondLevelViewController ()<UIGestureRecognizerDelegate>

@end

@implementation SecondLevelViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self backArrowSet];
    // Do any additional setup after loading the view.
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64);
}



- (void)viewAddEndEditingGesture
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
}

- (void)hideKeyBoard
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}


- (void)backArrowSet{
    
    UIButton *button = [[UIButton alloc] init];
    [button setBackgroundImage:[UIImage imageNamed:@"navigationBar_popBack"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    self.navigationItem.leftBarButtonItem = leftButton;
    
}

- (void)dismiss
{
    
    [self popToViewControllerAtIndex:0];
    
}
@end
