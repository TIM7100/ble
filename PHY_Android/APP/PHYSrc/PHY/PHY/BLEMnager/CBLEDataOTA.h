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
#import "Partition.h"
#import "FileManager.h"

@interface CBLEDataOTA : NSObject

-(BOOL)reLoadOTAData:(NSString*)strLocPath;

//.OTA相关消息打包
-(NSData*)buildOTAStartMsg;
-(NSData*)buildFirstAddrMsg;
-(NSData*)buildNextAddrMsg;
-(NSMutableArray*)buildFirstBlockMsg;
-(NSMutableArray*)buildNextBlockMsg;
-(CGFloat)getPercent;
@end
