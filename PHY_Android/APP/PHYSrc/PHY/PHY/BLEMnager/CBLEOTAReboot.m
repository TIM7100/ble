//
//  CBLEMnger.m
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//

#import "CBLEOTAReboot.h"
#import "CBLECenterMnger.h"

@interface CBLEOTAReboot()
@property(nonatomic,assign)BOOL     srcIsOTA;
@property(nonatomic,copy)NSString   *srcMacAddr;
@property(nonatomic,copy)NSString   *srcUUID;
@end

@implementation CBLEOTAReboot


-(instancetype)init{
    if ( self = [super init] ){
        _srcIsOTA   = [CBLECenterMnger shareMnger].curPheral.bIsInOTA;
        _srcMacAddr = [CBLECenterMnger shareMnger].curPheral.adverMacAddr;
        _srcUUID    = [CBLECenterMnger shareMnger].curPheral.peripheral.identifier.UUIDString;
    }
    return self;
}

-(void)dealloc{
    
    REMOVE_MESSAGE(BLEMSG_CENTER_NEWPHERAL, nil);
    REMOVE_MESSAGE(BLEMSG_PHERAL_CONNECT_RST, nil);
    REMOVE_MESSAGE(BLEMSG_PHERAL_DISCONNECT, nil);
}

- (BOOL)rebootAutoConnect{
    
    if ( _srcIsOTA )
        return NO;
    
    ADD_MESSAGE(BLEMSG_CENTER_NEWPHERAL, msgForNewPheral:);
    ADD_MESSAGE(BLEMSG_PHERAL_CONNECT_RST, msgForPheralConnect);
    ADD_MESSAGE(BLEMSG_PHERAL_DISCONNECT,  msgForPheralDisConnect);
    
    @autoreleasepool{
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[CBLECenterMnger shareMnger] otaCmd2App];
            [NSThread sleepForTimeInterval:1.0f];
            [[CBLECenterMnger shareMnger] cmdDisconnectCurPheral];
        }
        );
    };
    return YES;
}


-(void)msgForPheralDisConnect{
    
    [[CBLECenterMnger shareMnger].dataPherals removeAll];
    [[CBLECenterMnger shareMnger] cmdStartScan];
}

-(void)msgForNewPheral:(NSNotification*)noti{
    
    CDataPheralInfo *data = noti.object;
    BOOL bSameAddr = [data isSamePheralWithMacAddr:_srcMacAddr];
    BOOL bSameUUID = [data isSamePheralWithUUID:_srcUUID];
    
    if ( bSameAddr || bSameUUID ){
        @autoreleasepool{
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[CBLECenterMnger shareMnger] cmdStopScan];
                [NSThread sleepForTimeInterval:0.5f];
                [[CBLECenterMnger shareMnger] cmdConnect2Pheral:data];
            }
        );
        };
    } else{
        NSLog(@"不是当前的设备！");
    }
}

////////////////////////////////////////////////////////////////////////////////

-(void)msgForPheralConnect{
    
    dispatch_async(dispatch_get_main_queue(), ^{  //更新页面回到主线程
        if ([self.delegate respondsToSelector:@selector(rebootFinish:bFinish:)]){
            [self.delegate rebootFinish:self bFinish:YES];
        }
    });
}

@end
