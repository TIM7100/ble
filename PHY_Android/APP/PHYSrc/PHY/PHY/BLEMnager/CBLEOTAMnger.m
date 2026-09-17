//
//  CBLEMnger.m
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//

#import "CBLEOTAMnger.h"
#import "CBLECenterMnger.h"
#import "JCDataConvert.h"
#import "Partition.h"
#import "FileManager.h"
#import "CBLEDataParse.h"
#import "CBLEDataOTA.h"

@interface CBLEOTAMnger()
@property(nonatomic,copy)NSString          *strLocFilePath;
@property(nonatomic,copy)NSString          *strCurMacAddr;
@property(nonatomic,strong)CBLEDataOTA     *otaMsgData;
@end

@implementation CBLEOTAMnger


-(instancetype)init{
    if ( self = [super init] ){
        
        ADD_MESSAGE(BLEMSG_CENTER_NEWPHERAL, msgForNewPheral:);
        ADD_MESSAGE(BLEMSG_CENTER_NEWPHERAL_OTA, msgForPheralOTAOk);
        ADD_MESSAGE(BLEMSG_PHERAL_CONNECT_RST, msgForPheralConnect);
        ADD_MESSAGE(BLEMSG_PHERAL_DISCONNECT,  msgForPheralDisConnect);
        ADD_MESSAGE(BLEMSG_PHERAL_OATCMD_ACK,  msgForOTACmdAck:);
    }
    return self;
}

-(void)dealloc{
    REMOVE_MESSAGE(BLEMSG_CENTER_NEWPHERAL, nil);
    REMOVE_MESSAGE(BLEMSG_CENTER_POWERON, nil);
    REMOVE_MESSAGE(BLEMSG_CENTER_NEWPHERAL_OTA, nil);
    REMOVE_MESSAGE(BLEMSG_PHERAL_DISCONNECT, nil);
}

-(CBLEDataOTA*)otaMsgData{
    if ( _otaMsgData == nil ){
        _otaMsgData = [[CBLEDataOTA alloc] init];
    }
    return _otaMsgData;
}

-(void)msgForPheralDisConnect{
    
    if ( [self.otaMsgData getPercent] > 0 ){
        [self update2UIErrTip:0x100];
    } else {
     
        [[CBLECenterMnger shareMnger].dataPherals removeAll];
        [[CBLECenterMnger shareMnger] cmdStartScan];
    }
}

-(void)msgForNewPheral:(NSNotification*)noti{
    
    CDataPheralInfo *data = noti.object;
    BOOL bOK = [data isSamePheralWithMacAddr:_strCurMacAddr];
    if ( bOK ){
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

-(void)msgForPheralOTAOk{
    //等待OTA模式启动
    NSLog(@" 自动连接完成，OTA模式已经准备好");
    [self startOTACmd];
}

-(void)msgForPheralConnect{
    NSLog(@" 自动连接已经完成，等待OTA模式完成！");
#if 0
    //蓝牙连接上
    if ( [[CBLECenterMnger shareMnger] isConnectOK]){
        [_scanTimer invalidate];
        _scanTimer = nil;
        [_scanTimeOut invalidate];
        _scanTimeOut = nil;
        [[CBLECenterMnger shareMnger] cmdStopScan];
        [self showSearchingIcon:NO];
        
        //提示框提示调用成功
        CDataPheralInfo *pheral = [CBLECenterMnger shareMnger].curPheral;
        NSString *tip = [NSString stringWithFormat:@"蓝牙连接成功: %@,状态：%@",
                         pheral.peripheral.name,
                         pheral.peripheral.state==CBPeripheralStateConnected?@"连接成功":@"未知" ];
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:tip preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self popVC];
            if (self.updateMainPageRightBtn) {
                self.updateMainPageRightBtn();
            }
        }];
        [alertC addAction:action];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:nil];
    } else {
        [self showMessageAutoHide:@"蓝牙连接失败，请重新尝试！" afterDelay:3.0];
    }
#endif
}


-(BOOL)startOTAWithLocFile:(NSString*)filePath{

    //1.准备OTA数据
    BOOL bSuc = [self.otaMsgData reLoadOTAData:filePath];
    if ( !bSuc )
        return NO;
    
    //2.判断当前是否是OTA模式
    CDataPheralInfo *curPheral = [CBLECenterMnger shareMnger].curPheral;
    if ( curPheral == nil )
        return NO;
    
    _strLocFilePath = filePath;
    //1.如果是OTA，直接进入升级模式
    if ( curPheral.bIsInOTA ){
        [self startOTACmd];
        
    } else {
        //1.保存当前MacAddr,2.断开当前连接
        _strCurMacAddr = curPheral.adverMacAddr;
        @autoreleasepool{
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[CBLECenterMnger shareMnger] appCmdSwitch2OTA];
                [NSThread sleepForTimeInterval:1.0f];
                [[CBLECenterMnger shareMnger] cmdDisconnectCurPheral];
            }
        );
        };
    }
    
    return YES;
}

-(void)startOTACmd{
    
    NSData *otaCmd = [self.otaMsgData buildOTAStartMsg];
    [[CBLECenterMnger shareMnger] wristWriteOTACmd:otaCmd bInOTA:YES];
}


-(void)msgForOTACmdAck:(NSNotification*)noti{
    
    CBLEDataParse *tool = noti.object;
    if ( tool == nil ) return;
    @autoreleasepool {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if ( tool.ackData.srcCmd == OTA_RSP_START_OTA ){
                
                NSData *cmdData = [self.otaMsgData buildFirstAddrMsg];
                [[CBLECenterMnger shareMnger] wristWriteOTACmd:cmdData bInOTA:YES];
                
                NSLog(@"                 01-->OTAACK:0x81 发送地址信息......");
            } else if ( tool.ackData.srcCmd == OTA_RSP_PARITION_COMPLETE ){
                
                NSMutableArray *mutAry = [self.otaMsgData buildFirstBlockMsg];
                for (NSInteger i = 0; i < mutAry.count; i++) {
                    NSData *otaData = [mutAry objectAtIndex:i];
                    [[CBLECenterMnger shareMnger] wristWriteOTAData:otaData];
                }
                [self update2UIProcess];
                
            } else if ( tool.ackData.srcCmd == OTA_RSP_BLOCK_COMPLETE ){
                
                NSMutableArray *mutAry = [self.otaMsgData buildNextBlockMsg];
                for (NSInteger i = 0; i < mutAry.count; i++) {
                    NSData *otaData = [mutAry objectAtIndex:i];
                    [[CBLECenterMnger shareMnger] wristWriteOTAData:otaData];
                }
                [self update2UIProcess];
                
            } else if ( tool.ackData.srcCmd == OTA_RSP_BLOCK_INFO ){
                
                NSData *cmdData = [self.otaMsgData buildNextAddrMsg];
                [[CBLECenterMnger shareMnger] wristWriteOTACmd:cmdData bInOTA:YES];
                
            } else if ( tool.ackData.srcCmd == OTA_RSP_PARTITION_INFO ){
                NSLog(@" OTA升级结束🔚！");
                [self update2UIComplete];
            } else {
                //错误提示
                [self update2UIErrTip:tool.ackData.srcCmd];
            }
        });
    };
}


-(void)update2UIProcess{

    float num = [self.otaMsgData getPercent];
    dispatch_async(dispatch_get_main_queue(), ^{  //更新页面回到主线程
        if ([self.delegate respondsToSelector:@selector(updateOTAProgress:feedBackInfo:)]){
            [self.delegate updateOTAProgress:self feedBackInfo:num];
        }
    });
}

-(void)update2UIComplete{
    dispatch_async(dispatch_get_main_queue(), ^{  //更新页面回到主线程
        if ([self.delegate respondsToSelector:@selector(updateOTAComplete:isComplete:)]){
            [self.delegate updateOTAComplete:self isComplete:YES];
        }
    });
}

-(void)update2UIErrTip:(NSInteger)nErrCode{
    dispatch_async(dispatch_get_main_queue(), ^{  //更新页面回到主线程
        if ([self.delegate respondsToSelector:@selector(updateOTAError:errorCode:)]){
            [self.delegate updateOTAError:self errorCode:nErrCode];
        }
    });
}


+(NSString*)errCode2Str:(NSUInteger)nCode{
    NSString *tip = nil;
    switch (nCode) {
        case 0x64: {
            tip = [NSString stringWithFormat:@"文件解析错误"];
        }
            break;
        case 0x65: {
            tip = [NSString stringWithFormat:@"进入OTA状态后连接错误"];
        }
            break;
        case 0x66: {tip = [NSString stringWithFormat:@"OTA数据发送service未找到"];
        }
            break;
        case 0x67: {
            tip = [NSString stringWithFormat:@"OTA命令发送service未找到"];
        }
            break;
        case 0x68: {
            tip = [NSString stringWithFormat:@"OTA数据写入错误"];
        }
            break;
        case 0x69: {
            tip = [NSString stringWithFormat:@"OTA响应错误"];
        }
            break;
        case 0x6a: {
            tip = [NSString stringWithFormat:@"断开连接"];
        }
            break;
        case 0x6b: {tip = [NSString stringWithFormat:@"设备未连接"];
        }
            break;
        case 0x6c: {tip = [NSString stringWithFormat:@"设备不在OTA状态"];
        }
            break;
        case 0x100:{
            tip = @"蓝牙设备失去连接，重新连接后再次尝试！";
        }
        break;
    }
    return tip;
}
@end
