//
//  UpgradeModeViewController.h
//  OTASDKDemo
//
//  Created by Yang on 2018/10/28.
//  Copyright © 2018 phy. All rights reserved.
//

#import "SecondLevelViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface UpgradeModeViewController : SecondLevelViewController

@property (nonatomic, strong) NSString *appFilePath;
@property (nonatomic, strong) NSString *mscAddress;//mac地址
@property(nonatomic,strong)NSString *originalUUID;//uuid

@property(assign,nonatomic)NSInteger selectedRow;//选取的行数
@property(nonatomic,strong)NSMutableArray *fileList;
@end

NS_ASSUME_NONNULL_END
