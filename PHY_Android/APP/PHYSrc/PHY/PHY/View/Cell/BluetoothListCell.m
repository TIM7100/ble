//
//  BluetoothListCellTableViewCell.m
//  PHY
//
//  Created by Han on 2018/9/28.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "BluetoothListCell.h"
@implementation BluetoothListCell
- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


-(void)setDataInfo:(CDataPheralInfo *)dataInfo{
    
    _dataInfo = dataInfo;
    
    NSNumber *RSSI = dataInfo.RSSI;
    BOOL isName = ([dataInfo.peripheral.name isEqualToString:@""] || dataInfo.peripheral.name == nil);
    self.bluetoothName.text = isName ? @"Unnamed": dataInfo.peripheral.name;
    self.bluetoothMacName.text = dataInfo.peripheral.identifier.UUIDString;
    if (dataInfo.adverMacAddr != nil && dataInfo.adverMacAddr.length > 17) {
        NSMutableString*macString = [[NSMutableString alloc]init];
        [macString appendString:[[dataInfo.adverMacAddr substringWithRange:NSMakeRange(14,2)]uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[dataInfo.adverMacAddr substringWithRange:NSMakeRange(12,2)]uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[dataInfo.adverMacAddr substringWithRange:NSMakeRange(10,2)]uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[dataInfo.adverMacAddr substringWithRange:NSMakeRange(8,2)]uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[dataInfo.adverMacAddr substringWithRange:NSMakeRange(6,2)]uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[dataInfo.adverMacAddr substringWithRange:NSMakeRange(4,2)]uppercaseString]];
        self.bluetoothMacName.text = macString;
    }
    /*计算蓝牙距离*/
    int iRssi = abs([RSSI intValue]);
    self.signaiStrengthLabel.text = [NSString stringWithFormat:@"%@dBm",RSSI];
    //    float power = (iRssi-59)/(10*2.0);
    //    float distance = pow(10, power);
    //    self.distance.text = [NSString stringWithFormat:@"%.3f米",distance];
    if (iRssi < 40) {
        self.signalImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"信号3"]];//信号4
    }
    else if(iRssi > 100){
        self.signalImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"信号0"]];
    }
    else if(iRssi <= 100 || iRssi >= 40){
        self.signalImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"信号%01d",4-((iRssi - 20)/20)]];//5-((iRssi - 25)/15)
    }
}

- (void)setBlutoothInfo:(JCBlutoothInfoModel *)blutoothInfo{
    _blutoothInfo = blutoothInfo;
    NSNumber *RSSI = blutoothInfo.RSSI;
    BOOL isName = ([blutoothInfo.peripheral.name isEqualToString:@""] || blutoothInfo.peripheral.name == nil);
    self.bluetoothName.text = isName ? @"Unnamed": blutoothInfo.peripheral.name;
    self.bluetoothMacName.text = blutoothInfo.peripheral.identifier.UUIDString;
    if (blutoothInfo.adverMacAddr != nil && blutoothInfo.adverMacAddr.length > 17) {
        NSMutableString*macString = [[NSMutableString alloc]init];
        [macString appendString:[[blutoothInfo.adverMacAddr substringWithRange:NSMakeRange(14,2)]uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[blutoothInfo.adverMacAddr substringWithRange:NSMakeRange(12,2)]uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[blutoothInfo.adverMacAddr substringWithRange:NSMakeRange(10,2)]uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[blutoothInfo.adverMacAddr substringWithRange:NSMakeRange(8,2)]uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[blutoothInfo.adverMacAddr substringWithRange:NSMakeRange(6,2)]uppercaseString]];
        [macString appendString:@":"];
        [macString appendString:[[blutoothInfo.adverMacAddr substringWithRange:NSMakeRange(4,2)]uppercaseString]];
        self.bluetoothMacName.text = macString;
    }
    /*计算蓝牙距离*/
    int iRssi = abs([RSSI intValue]);
    self.signaiStrengthLabel.text = [NSString stringWithFormat:@"%@dBm",RSSI];
//    float power = (iRssi-59)/(10*2.0);
//    float distance = pow(10, power);
//    self.distance.text = [NSString stringWithFormat:@"%.3f米",distance];
    if (iRssi < 40) {
        self.signalImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"信号3"]];//信号4
    }
    else if(iRssi > 100){
        self.signalImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"信号0"]];
    }
    else if(iRssi <= 100 || iRssi >= 40){
        self.signalImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"信号%01d",4-((iRssi - 20)/20)]];//5-((iRssi - 25)/15)
    }
}
@end
