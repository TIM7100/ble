//
//  CBLEMnger.h
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CBLEDataMsg.h"



@interface CBLEDataParse : NSObject
@property(nonatomic,strong)MsgDataWristAck *ackData;
+(instancetype)dataParse;
-(NSString*)parseMacAddr:(CBCharacteristic*)chrtcs;
-(NSInteger)parseCmdAck:(CBCharacteristic*)chrtcs;
-(NSInteger)parseOTAAck:(CBCharacteristic*)chrtcs;
-(NSInteger)parseAppOTAAck:(CBCharacteristic*)chrtcs;
@end
