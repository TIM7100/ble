//
//  MainCollectionReusableView.h
//  PHY
//
//  Created by Han on 2018/9/27.
//  Copyright © 2018年 phy. All rights reserved.
//

#import <UIKit/UIKit.h>

//NS_ASSUME_NONNULL_BEGIN

@interface MainCollectionReusableView : UICollectionReusableView
@property (strong, nonatomic)  UILabel *connectedDeviceLabel;
@property (strong, nonatomic)  UILabel *batteryStatusLabel;
@property (strong, nonatomic)  UIButton *btnReboot;


@end

//NS_ASSUME_NONNULL_END
