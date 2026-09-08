//
//  JCBluetoothData.m
//  Zebra
//
//  Created by han on 2018/10/13.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "JCBluetoothData.h"

static JCBluetoothData *_bluetoothData;
@interface JCBluetoothData ()

@end

@implementation JCBluetoothData

#pragma mark - 创建单例蓝牙数据模型
+ (JCBluetoothData *)shareBluetoothData{
    @synchronized(self) {
        if (!_bluetoothData) {
            _bluetoothData = [JCBluetoothData new];

        }
    }
    return _bluetoothData;
}


@end
