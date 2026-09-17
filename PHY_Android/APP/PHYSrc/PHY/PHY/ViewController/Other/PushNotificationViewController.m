//
//  PushNotificationViewController.m
//  PHY
//
//  Created by Han on 2018/10/9.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "PushNotificationViewController.h"
#import "JCBluetoothManager.h"
#import "JCDataConvert.h"
#import "NSString+Additions.h"
#import "CBLECenterMnger.h"

@interface PushNotificationViewController ()<JCBluetoothManagerDelegate>
@property (nonatomic, weak) JCBluetoothManager *bluetoothManager;
@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet UITextField *contentTextField;
@property(strong,nonatomic) NSString *titleStr;
@property(strong,nonatomic) NSString *contentStr;
@property(strong,nonatomic) NSMutableArray *messageList;
@end

@implementation PushNotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
    self.messageList = [NSMutableArray arrayWithCapacity:0];
    //[self setUpBluetooth];
}

- (void)setUpView{
    self.navigationItem.title = @"推送消息";
    [self baseSetup:PageGobackTypePop];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.barTintColor = Color_navPageButton_Green;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

-(void)setView{
    //限制输入title的长度
    [self.titleTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    //禁止输入中文
    [self.contentTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

#pragma mark - 蓝牙及相关设置初始化
- (void)setUpBluetooth {
    _bluetoothManager = [JCBluetoothManager shareCBCentralManager];
    _bluetoothManager.delegate = self;
}

-(NSString *)getContentStr {
    NSMutableData *mData = [NSMutableData data];
    for (int i = 0; i < 15 ; i++) {
        NSUInteger int1 = 0x00;
        Byte bytes = int1 & 0xff;
        [mData appendBytes:&bytes length:1];
    }
    NSLog(@"mData:%@",mData);
    NSString *contentStr = [JCDataConvert ConvertHexToString:mData];//data转string
    return contentStr;
}

-(NSString *)getSendStr:(int)byte {
    NSString *messageTypeStr = [JCDataConvert ToHex:byte];
    NSString *contentStr = [self getContentStr];
    NSString *sendStr = [messageTypeStr stringByAppendingFormat:@"%@%@",contentStr,@"\\0"];
    NSLog(@"sendStr:%@",sendStr);
    return sendStr;
}

- (IBAction)phoneCallRemindAction:(UIButton *)sender {
    
    [[CBLECenterMnger shareMnger] wristNotifyNewMsg:BLEWristSendMsgTypeCallNew];
    
#if 0
    //推送消息报文（1～17字节）
    //报文类型 1 字节 8位 0~5 消息类型 低位 6~7 位于高位 有无后续类型
    //内容 2~16 内容 17 title和message 都 以 \0结束   内容长度不定 1~17位都可以
    //NSUInteger
    Byte byte[1] = {};
    byte[0] = 0x01;
    NSString *sendStr = [self getSendStr:byte[0]];
    [self.bluetoothManager sendMessage:sendStr];
#endif
}

- (IBAction)phoneStandbyAction:(id)sender {
    
    [[CBLECenterMnger shareMnger] wristNotifyNewMsg:BLEWristSendMsgTypeCallEnd];
    
#if 0
    Byte byte[1] = {};
    byte[0] = 0x02;
    NSString *sendStr = [self getSendStr:byte[0]];
    [self.bluetoothManager sendMessage:sendStr];
#endif
}

- (IBAction)phoneSMSAction:(UIButton *)sender {
    [self getMessageFromTextField];
    [[CBLECenterMnger shareMnger] wristSendMsgBySMS:self.titleStr strMsg:self.contentStr];
    //[_bluetoothManager sendMessage:self.messageList phoneType:phoneSMS];
}

- (IBAction)phoneWeChatAction:(id)sender {
    [self getMessageFromTextField];
    [[CBLECenterMnger shareMnger] wristSendMsgByWeChat:self.titleStr strMsg:self.contentStr];
    //[_bluetoothManager sendMessage:self.messageList phoneType:phoneWechat];
}


-(void)getMessageFromTextField {
    NSString *titleStr = [self.titleTextField.text stringByAppendingFormat:@"%@",@"\0"];
    self.titleStr = titleStr;
    if (![self.contentTextField.text isEmpty]) {
        NSString *contentStr = [self.contentTextField.text stringByAppendingFormat:@"%@",@"\0"];
        self.contentStr = contentStr;
    }
    [self getMsgList];
}

-(void)getMsgList {
    NSData *data = [JCDataConvert stringToBytes:self.titleStr];
    NSLog(@"titleData:%@",data);

    NSString *titleStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"titleStr:%@",titleStr);

    Byte *testByte = (Byte *)[data bytes];
    for(int i=0;i<[data length];i++) {
        printf("titleStr -> Byte = %d\n",testByte[i]);
    }
    [self.messageList removeAllObjects];
    [self.messageList addObject:data];//普通字符串转data

    if (![self.contentStr isEmpty]) {
        [self getMsgList:self.contentStr];
    }
}

-(void)getMsgList:(NSString *)message {
    NSData *contentData = [JCDataConvert stringToBytes:message];
    NSLog(@"contentData:%@",contentData);
    NSString *contentStr = [[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding];
    NSLog(@"contentStr:%@",contentStr);

    Byte *contentByte = (Byte *)[contentData bytes];//内容转为byte
    for(int i=0;i<[contentData length];i++) {
        printf("contentByte -> Byte = %d\n",contentByte[i]);
    }
    int index = contentData.length % 15 == 0 ? contentData.length / 15 : contentData.length / 15 + 1;
    for (int i = 1; i <= index; i++) {
        if (i * 15 <= contentData.length) {
            Byte apduByte[15] = {};
            NSUInteger length = 15 * i;
            for (int j = 0; j < 15 ; j++) {
                NSUInteger contentDataLength = contentData.length;
                NSUInteger yuShu = contentData.length % 15;
                NSUInteger chuShu = contentData.length / 15;
                NSUInteger int1 = contentByte[contentDataLength - 15 * (chuShu + 1 -i) - yuShu + j];
                Byte bytes = int1 & 0xff;
                apduByte[j] = bytes;
            }

            NSData *messageData = [[NSData alloc] initWithBytes:apduByte length:15];
            NSLog(@"messageData:%@",messageData);
            [self.messageList addObject:messageData];
        } else {
            NSUInteger length = 15 - (i*15 - contentData.length);
            Byte *apduByte= malloc(sizeof(Byte)*(length));

            for (int j = 0; j < length ; j++) {
                NSUInteger contentDataLength = contentData.length;
                NSUInteger int1 = contentByte[(contentDataLength - length) + j];//(i*15 - contentData.length) + j
                Byte bytes = int1 & 0xff;
                apduByte[j] = bytes;
            }

            NSData *messageData = [[NSData alloc] initWithBytes:apduByte length:length];
            NSLog(@"messageData2:%@",messageData);
            [self.messageList addObject:messageData];
        }
    }
}

-(void)textFieldDidChange:(UITextField *)textField {
    CGFloat maxLength = 12;
    if (textField == self.titleTextField) {
        NSString *toBeString = textField.text;
        //获取高亮部分
        UITextRange *selectedRange = [textField markedTextRange];
        UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
        if (!position || !selectedRange) {
            if (toBeString.length > maxLength) {
                NSRange rangeIndex = [toBeString rangeOfComposedCharacterSequenceAtIndex:maxLength];
                if (rangeIndex.length == 1) {
                    textField.text = [toBeString substringToIndex:maxLength];
                } else {
                    NSRange rangeRange = [toBeString rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, maxLength)];
                    textField.text = [toBeString substringWithRange:rangeRange];
                }
            }
        }
    }
    self.titleTextField.text = [self filterCharactor:self.titleTextField.text withRegex:@"[\u4e00-\u9fa5]"];
    self.contentTextField.text = [self filterCharactor:self.contentTextField.text withRegex:@"[\u4e00-\u9fa5]"];
}

//根据正则，过滤特殊字符
- (NSString *)filterCharactor:(NSString *)string withRegex:(NSString *)regexStr{
    NSString *searchText = string;
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *result = [regex stringByReplacingMatchesInString:searchText options:NSMatchingReportCompletion range:NSMakeRange(0, searchText.length) withTemplate:@""];
    return result;
}

@end
