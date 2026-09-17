//
//  BluetoothListCellTableViewCell.h
//  PHY
//
//  Created by Han on 2018/9/28.
//  Copyright © 2018年 phy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCBlutoothInfoModel.h"
#import "CBLEDataMnger.h"

NS_ASSUME_NONNULL_BEGIN

@interface BluetoothListCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *signalImageView;
@property (weak, nonatomic) IBOutlet UILabel *bluetoothName;
@property (weak, nonatomic) IBOutlet UILabel *bluetoothMacName;
@property (weak, nonatomic) IBOutlet UILabel *signaiStrengthLabel;

@property (nonatomic, strong) JCBlutoothInfoModel *blutoothInfo;
@property (nonatomic, strong) CDataPheralInfo      *dataInfo;
@end

NS_ASSUME_NONNULL_END
