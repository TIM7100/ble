//
//  bluetoothListViewController.h
//  PHY
//
//  Created by Han on 2018/9/28.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "SecondLevelViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BluetoothListViewController : SecondLevelViewController
@property(nonatomic, copy) void(^updateMainPageRightBtn)(void);
//新增的传送mac地址和电池状态
@property(nonatomic, copy) void(^updateMacAddress)(NSString *macAddress,NSString *originalMacAddress,NSString *originalUUID);
@property(nonatomic, copy) void(^updateBatteryLevel)(NSString *batteryLevel);
@end

NS_ASSUME_NONNULL_END
