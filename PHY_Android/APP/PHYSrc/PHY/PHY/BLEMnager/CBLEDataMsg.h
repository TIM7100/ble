//
//  CBLEMnger.h
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define MSG_LED_CHANNEL_R   (1)
#define MSG_LED_CHANNEL_G   (2)
#define MSG_LED_CHANNEL_B   (0)

typedef enum eBLEWristCmd{
    
    eBLEWristCmdVerInfo    = 0x01,  //版本信息 固件版本，蓝牙协议栈版本，Wrist通信协议版本
    eBLEWristCmdConfig     = 0x02,  //手环的配置数据同步（时间，页面开关，蓝牙信号发射功率，抬腕，信息提醒设置）
    //eBLEWristCmdOwner    = 0x03,  //手环的使用者信息同步
    //eBLEWristCmdRing     = 0x04,  //闹钟
    //eBLEWristCmdSearch   = 0x05,  //查找手环
    //eBLEWristUnBind      = 0x06,  //解除绑定
    
    eBLEWristHRStart       = 0x21,  //启动心率血压检测
    eBLEWristHRStop        = 0x22,  //停止心率血压检测
    eBLEWristAccStart      = 0x23,  //启动加速传感器
    eBLEWristAccStop       = 0x24,  //停止加速传感器
    
    eBLEWristSetLED        = 0x30,  //LED灯的设定
    eBLEWristSendMsg       = 0x38,  //推送消息
    
    eBLEWristHRLast        = 0x81,  //获取心率数据最后的测量值
    eBLEWristHRRaw         = 0x85,  //获取心率原始数据
    eBLEWristACCRaw        = 0x86,  //获取加速度传感器原始数据
    
} WristCmdAck;

typedef enum eBLEWristOTACmd{
    
    eBLEWristOTACmdVersion  = 0x02,     //查询BootLoad版本信息
    
    OTA_CMD_START_OTA       = 0x01,     //启动OAT命令
    OTA_CMD_PARTITION_INFO,
    OTA_CMD_BLOCK_INFO,
    OTA_CMD_ERBOOT,
    OTA_CMD_ERASE,
    
    
    //ack
    eBLEWristOTACmdVersionAck = 0x00,
                                             //68 PPlus_ERR_OTA_DATA
    OTA_RSP_START_OTA         = 0x0081,      //设置设备 OTA 状态
    OTA_RSP_OTA_COMPLETE,
    OTA_RSP_PARTITION_INFO,                  //0083 所有ota数据发送成功
    OTA_RSP_PARITION_COMPLETE,               //0084 OTA地址发送成功
    OTA_RSP_BLOCK_INFO,                      //0085 一个partition 数据发送成功，发送下一个partition命令
    OTA_RSP_BLOCK_BURST,
    OTA_RSP_BLOCK_COMPLETE,                  //0087 一组16*20 ota数据发送成功，开始下一组
    OTA_RSP_ERASE,
    OTA_RSP_ERROR = 0xFF
} BLEWristOTACmd;


#define    BLEWristSendMsgTypeUnKnow       0    //未定义消息
#define    BLEWristSendMsgTypeCallNew      1    //1来电提醒
#define    BLEWristSendMsgTypeCallEnd      2    //来电提醒结束
#define    BLEWristSendMsgTypeNewSMS       3    //短信提醒
#define    BLEWristSendMsgTypeNewEmail     4    //邮件提醒
#define    BLEWristSendMsgTypeNewWeChat    5    //微信
#define    BLEWristSendMsgTypeNewQQ        6    //QQ
#define    BLEWristSendMsgTypeNewOther     7    //其他应用提醒

#define    WristMsgFlagBrief               0    //0：概要消息，没有消息正文
#define    WristMsgFlagBriefText           1    //1：概要消息，有消息正文等待推送
#define    WristMsgFlagTextMore            3    //2：消息正文，还有后续内容
#define    WristMsgFlagTextLast            2    //3：消息正文，已经是最后一包数据


//1.定义宏
#define REMOVE_MESSAGE(msg,obj)           [[NSNotificationCenter defaultCenter] removeObserver:self name:msg object:obj];
#define ADD_MESSAGE(msg,func)             [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(func) name:msg object:nil]
#define ADD_MESSAGE_WITHOBJ(msg,func,obj) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(func) name:msg object:obj]
#define POST_MESSAGE(msgName)             [[NSNotificationCenter defaultCenter] postNotificationName:msgName object:nil]
#define POST_MSG_WITHOBJ(msgName,obj)     [[NSNotificationCenter defaultCenter] postNotificationName:msgName object:obj]


//2.定义长量
#define BLE_CONST_MAX_TRYCONNECT         (10)

//3.定义消息
#define BLEMSG_CENTER_POWERON             @"BLEMSG_CENTER_POWERON"      //蓝牙是否开机
#define BLEMSG_CENTER_NEWPHERAL           @"BLEMSG_CENTER_NEWPHERAL"    //发现新的蓝牙设备
#define BLEMSG_CENTER_NEWPHERAL_OTA       @"BLEMSG_CENTER_NEWPHERAL_OTA"    //发现新的蓝牙设备,OTA准备好
#define BLEMSG_PHERAL_CONNECT_RST         @"BLEMSG_PHERAL_CONNECT_RST"  //连接蓝牙设备的结果
#define BLEMSG_PHERAL_DISCONNECT          @"BLEMSG_PHERAL_DISCONNECT"   //蓝牙断开，系统尝试自动重连
#define BLEMSG_PHERAL_UPDATE_INFO         @"BLEMSG_PHERAL_UPDATE_INFO"  //更新蓝牙的基本信息
#define BLEMSG_PHERAL_ACC_SENSOR          @"BLEMSG_PHERAL_ACC_SENSOR"   //更新加速传感器信息
#define BLEMSG_PHERAL_HR_RAW              @"BLEMSG_PHERAL_HR_RAW"       //
#define BLEMSG_PHERAL_HR_LAST             @"BLEMSG_PHERAL_HR_LAST"      //
#define BLEMSG_PHERAL_SENDMSG_ACK         @"BLEMSG_PHERAL_SENDMSG_ACK"  //发送消息后的返回值
#define BLEMSG_PHERAL_OATCMD_ACK          @"BLEMSG_PHERAL_OATCMD_ACK"   //OTA解析后的消息

//4.定义蓝牙UUID
//    4.1读取系统信息
#define BLEUUID_SERVER_DEVICE_INFO    @"0000180A-0000-1000-8000-00805f9b34fb"
#define BLEUUID_SERVER_DEVICE_READMAC @"00002A23-0000-1000-8000-00805f9b34fb" //读MAC地址

//    4.2读写蓝牙数据
#define BLEUUID_SERVER_WR             @"5833FF01-9B8B-5191-6142-22A4536EF123"
#define BLEUUID_SERVER_WR_WRITE       @"5833FF02-9B8B-5191-6142-22A4536EF123"
#define BLEUUID_SERVER_WR_INDICATE    @"5833FF03-9B8B-5191-6142-22A4536EF123"
#define BLEUUID_SERVER_WR_DATA_WRITE  @"5833FF04-9B8B-5191-6142-22A4536EF123"  //只有OAT才有该特征

//   4.3通用命令相关 实时监测的值 Wrist私有协议由三种通信方式构成：命令+应答，推送通知，只读区域
#define BLEUUID_SERVICE_WRIST         @"0000ff01-0000-1000-8000-00805f9b34fb"
#define BLEUUID_SERVER_WRIST_CMDACK   @"0000ff02-0000-1000-8000-00805f9b34fb" //命令+应答和推送通知使用一个UUID：0xff02
#define BLEUUID_SERVER_WRIST_READ     @"0000ff10-0000-1000-8000-00805f9b34fb" //只读区域提

@interface MsgDataWristAck : NSObject
@property(nonatomic,assign)int X;
@property(nonatomic,assign)int Y;
@property(nonatomic,assign)int Z;
@property(nonatomic,assign)NSInteger       srcCmd;
@property(nonatomic,assign)NSInteger       msgAck;
@property(nonatomic,assign)NSUInteger      HRLastValue;
@property(nonatomic,strong)NSMutableArray* HRRawDataArr; //测量心率的原始数据
@property(nonatomic,copy)NSString*         strMacAddr;
@property(nonatomic,copy)NSString*         strBootVer;
@end


@interface CBLEDataMsg : NSObject
+(NSData*)buildLEDMsg:(NSInteger)nChannel nVal:(NSInteger)nVal;
+(NSData*)buildStartSensorMsg:(BOOL)bStart;
+(NSData*)buildStartHeartRate:(BOOL)bStart;
+(NSData*)buildNewMsgNotify:(NSInteger)nMsgType strMsg:(NSString*)strMsg moreState:(NSInteger)moreState;

+(NSData*)buildApp2OTA;
+(NSData*)buildApp2OTARes;
+(NSData*)buildBleVersion;
+(NSData*)buildOTA2App;

//OTA相关命令
+(NSData*)buildOTAStart:(NSInteger)nPartitionNums;
+(NSData*)buildPartition;

//将待发送的消息转换为最大15个字符的数组
+(NSMutableArray*)convertMsg2Ary:(NSString*)strMsg;

@end




