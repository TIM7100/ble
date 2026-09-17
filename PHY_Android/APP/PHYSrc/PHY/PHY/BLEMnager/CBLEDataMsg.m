//
//  CBLEMnger.m
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//
#import "CBLEDataMsg.h"
#import "CBLEDataParse.h"

#define MSG_OFFSET_CMD    (0)
#define MSG_OFFSET_CSN    (1)
#define MSG_OFFSET_PARAM  (2)
#define MSG_LENGHT_FIX    (3)

@interface MsgDataWristAck()
@end
@implementation MsgDataWristAck
@end


@interface CBLEDataMsg()
@end
@implementation CBLEDataMsg

+(NSMutableArray*)convertMsg2Ary:(NSString*)strMsg {
    
    if ( strMsg == nil || strMsg.length <= 0 )
        return nil;
    
    NSMutableArray *msgList = [NSMutableArray array];
    const NSInteger nMaxNums = 15;
    NSInteger nNums = strMsg.length / nMaxNums;
    NSInteger nLeft = strMsg.length % nMaxNums;

    
    for (NSInteger i = 0; i < nNums; i++) {
        NSString *strSub = [strMsg substringWithRange:NSMakeRange(i*nMaxNums, nMaxNums)];
        [msgList addObject:strSub];
    }
    
    if ( nLeft > 0 ){
        NSString *strSub = [strMsg substringFromIndex:nNums*nMaxNums];
        [msgList addObject:strSub];
    }
    
    
    return msgList;
}


+(NSData*)buildLEDMsg:(NSInteger)nChannel nVal:(NSInteger)nVal{
    
    Byte btParam[2+MSG_LENGHT_FIX];
    btParam[MSG_OFFSET_PARAM]   = nVal & 0xFF;
    btParam[MSG_OFFSET_PARAM+1] = nChannel & 0xFF;
    
    return [self buidMsgWithParam:eBLEWristSetLED btParam:btParam nLen:2+MSG_LENGHT_FIX];
}


+(NSData*)buildStartSensorMsg:(BOOL)bStart{
    
    Byte btParam[0+MSG_LENGHT_FIX];
    NSUInteger nCmd = bStart ? eBLEWristAccStart : eBLEWristAccStop;
    return [self buidMsgWithParam:nCmd btParam:btParam nLen:MSG_LENGHT_FIX];
}


+(NSData*)buildStartHeartRate:(BOOL)bStart{
    
    Byte btParam[0+MSG_LENGHT_FIX];
    NSUInteger nCmd = bStart ? eBLEWristHRStart : eBLEWristHRStop;
    return [self buidMsgWithParam:nCmd btParam:btParam nLen:MSG_LENGHT_FIX];
}


+ (NSData*)buidMsgWithParam:(NSUInteger)nCmd btParam:(Byte[])btParam nLen:(NSUInteger)nLen{
    
    static Byte stCSN = 0;
    Byte btXor = 0;
    btParam[MSG_OFFSET_CMD] = nCmd;       //命令字
    btParam[MSG_OFFSET_CSN] = stCSN++;    //顺序号
    for (NSUInteger i =0; i < nLen - 1; i++) {
        btXor ^= btParam[i];
    }
    btParam[nLen-1] = btXor; //校验和
    
    NSData *data = [NSData dataWithBytes:btParam length:nLen];
    return data;
}


+(NSData*)buildNewMsgNotify:(NSInteger)nMsgType  strMsg:(NSString*)strMsg moreState:(NSInteger)moreState{
    
    Byte btParam[17+MSG_LENGHT_FIX];

    //1.初始化内存
    for(int i = 0; i < 17; i++ ){
        btParam[i] = '\0';
    }
    
    //2.Bit 0～5:消息类型 Bit 6~7
    Byte btMsgType = (nMsgType & 0x3F);
    btMsgType |= ((moreState & 0x03) << 6);
    btParam[MSG_OFFSET_PARAM] = btMsgType;
    
    //3.填充内容
    if( strMsg != nil && strMsg.length > 0 ){
        
        NSData *data = [strMsg dataUsingEncoding:NSASCIIStringEncoding];
        NSString *strCheck = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"  str=%@  %@",strCheck,strMsg);
        Byte *datByte = (Byte *)[data bytes];
        int nDataLen = [data length];
        if ( nDataLen > 15 )
            nDataLen = 15;
        for(int i= 0; i< [data length]; i++ ) {
            btParam[MSG_OFFSET_PARAM+1+i] = datByte[i];
        }
    }
    return [self buidMsgWithParam:eBLEWristSendMsg btParam:btParam nLen:17+MSG_LENGHT_FIX];
}




+(NSData*)buildApp2OTA{
    
    Byte btCmd[] = {0x01,0x02};
    NSData *data = [NSData dataWithBytes:btCmd length:2];
    return data;
}

+(NSData*)buildApp2OTARes{
    Byte btCmd[] = {0x01,0x03};
    NSData *data = [NSData dataWithBytes:btCmd length:2];
    return data;
}

+(NSData*)buildBleVersion{
    
    Byte btCmd[] = {0x02 ,0x00};
    NSData *data = [NSData dataWithBytes:btCmd length:2];
    return data;
}

+(NSData*)buildOTA2App{
    
    Byte btCmd[] = {0x04 };
    NSData *data = [NSData dataWithBytes:btCmd length:1];
    return data;
}


//**************** OTA 相关参数****************
+(NSData*)buildOTAStart:(NSInteger)nPartitionNums{
    
    Byte btNums  = (nPartitionNums & 0xFF);
    Byte btCmd[] = {OTA_CMD_START_OTA ,btNums,0x00};
    NSData *data = [NSData dataWithBytes:btCmd length:3];
    return data;
}

+(NSData*)buildPartition{
    return nil;
}

@end
