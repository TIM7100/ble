//
//  OTAUpgradeViewController.h
//  PHY
//
//  Created by Han on 2018/10/9.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "SecondLevelViewController.h"

NS_ASSUME_NONNULL_BEGIN


@interface OTAUpgradeViewController : SecondLevelViewController

/** 从appDelegate里面，跳转过来，主要用于打开其他app共享跳转过来的文档 */
@property (nonatomic, strong) NSString *appFilePath;

@property (nonatomic, strong) NSString *mscAddress;//mac地址
@property(nonatomic,strong)NSString *originalUUID;//uuid

//新增的传送mac地址和电池状态
@property(nonatomic, copy) void(^updateMacAddress)(NSString *macAddress,NSString *originalMacAddress,NSString *originalUUID);
@property(nonatomic, copy) void(^updateBatteryLevel)(NSString *batteryLevel);
@end

NS_ASSUME_NONNULL_END
