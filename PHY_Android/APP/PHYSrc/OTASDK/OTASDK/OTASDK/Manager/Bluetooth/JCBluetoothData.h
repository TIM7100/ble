//
//  JCBluetoothData.h
//  Zebra
//
//  Created by han on 2018/10/13.
//  Copyright © 2018年 phy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCBluetoothData : NSObject
@property (nonatomic, strong) NSData *bluetoothRecieveData;

+ (JCBluetoothData *)shareBluetoothData;

@end
