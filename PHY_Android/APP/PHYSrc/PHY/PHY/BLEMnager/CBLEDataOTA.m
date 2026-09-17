//
//  CBLEMnger.m
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//

#import "CBLEDataOTA.h"
#import "JCDataConvert.h"


@interface CBLEDataOTA()
@property(nonatomic,strong)FileManager     *fileManager;
@property(nonatomic,strong)NSMutableArray  *partitionArray;
@property(assign,nonatomic) int partitionIndex;
@property(assign,nonatomic) int blockIndex;
@property(assign,nonatomic) int cmdIndex;
@property(assign,nonatomic) int flash_addr;
@property(assign,nonatomic) float totalSize;
@property(assign,nonatomic) float finshSize;
@property(assign,nonatomic) int retryTimes;
@property(assign,nonatomic) int errorTimes;
@property(assign,nonatomic) int curMsgNums;
@end
@implementation CBLEDataOTA


-(void)debugIdx{
    
#if 0
    Partition *partition = self.fileManager.list[self.partitionIndex];
    NSArray *partitionArray = partition.partitionArray;
    NSLog(@"02------[%0.2f]-------->发送数据[%d:%ld___%d:%ld]......",
          [self getPercent],
          self.partitionIndex,
          self.fileManager.list.count,

          self.blockIndex,
          partitionArray.count);
#endif
}

-(CGFloat)getPercent{
    
    if ( _totalSize == 0 )
        _totalSize = 1;
    CGFloat ftPer = _curMsgNums * 100.0 / _totalSize;
    return ftPer;
}

-(NSData*)buildOTAStartMsg{
    
    //发送命令01xx00 xx为文件分成的段数
    NSInteger nNums = _fileManager.list.count;
    NSData *cmdData = [CBLEDataMsg buildOTAStart:nNums];
    return cmdData;
}

-(NSData*)buildFirstAddrMsg{
   
    Partition *partition = self.fileManager.list[self.partitionIndex];
    int checsum =[self getPartitionCheckSum:partition];
    NSString *cmd = [self make_part_cmd:self.partitionIndex flash_addr:self.flash_addr run_addr:partition.address size:partition.partitionLength checksum:checsum];
    
    NSData *cmdData = [JCDataConvert hexToBytes:cmd];
    self.blockIndex = 0;
    
    return cmdData;
}

-(NSData*)buildNextAddrMsg{
    
    self.partitionIndex++;
    self.blockIndex = 0;
    if(self.partitionIndex < self.fileManager.list.count){
        //后面地址由前一个长度决定
        Partition *prePartition = self.fileManager.list[self.partitionIndex-1];
        self.flash_addr = self.flash_addr + prePartition.partitionLength + 16 - (prePartition.partitionLength+4)%4;
        Partition *partition = self.fileManager.list[self.partitionIndex];
        int checsum =[self getPartitionCheckSum:partition];
        NSString *cmd = [self make_part_cmd:self.partitionIndex flash_addr:self.flash_addr run_addr:partition.address size:partition.partitionLength checksum:checsum];
        
        NSData *cmdData = [JCDataConvert hexToBytes:cmd];
        return cmdData;
    }
    return nil;
}


-(NSMutableArray*)buildFirstBlockMsg{
    
    self.cmdIndex = 0;
    Partition *partition = self.fileManager.list[self.partitionIndex];
    NSArray *partitionArray = partition.partitionArray;
    NSMutableArray *mutAry = [NSMutableArray array];
    
    [self debugIdx];
    
    if ( 1 ){
        //while ( self.blockIndex < partitionArray.count) {
        if(self.errorTimes > 0){
            self.errorTimes = 0;
        }
        if(  self.blockIndex < partitionArray.count ){
            NSInteger cmdIndex = 0;
            NSArray *cmdList = partitionArray[self.blockIndex];
            //NSLog(@"          84:下标%d,partitionArray个数%lu",self.blockIndex,(unsigned long)partitionArray.count);
            cmdIndex = 0;
            while (cmdIndex < cmdList.count) {
                
                if(self.errorTimes > 0){
                    self.errorTimes = 0;
                }
                
                if(cmdIndex < cmdList.count){
                    NSData *data = [JCDataConvert hexToBytes:cmdList[cmdIndex]];
                    [mutAry addObject:data];
                }
                cmdIndex ++;
            }
        }
        self.blockIndex ++;
    }
    
    _curMsgNums ++;
    return mutAry;
}

-(NSMutableArray*)buildNextBlockMsg{
    
    Partition *partition = self.fileManager.list[self.partitionIndex];
    NSArray *partitionArray = partition.partitionArray;
    NSMutableArray *mutAry = [NSMutableArray array];
    [self debugIdx];
    
    if ( 1 ) {
        if ( 1 ) {
            //while ( self.blockIndex < partitionArray.count ) {
            if(self.errorTimes > 0){
                self.errorTimes = 0;
            }
            if(self.blockIndex < partitionArray.count){
                NSInteger cmdIndex = 0;
                NSArray *cmdList = partitionArray[self.blockIndex];
                //NSLog(@"   87:下标%d,partitionArray个数%lu",self.blockIndex,(unsigned long)partitionArray.count);
                
                while (cmdIndex < cmdList.count) {
                    if(self.errorTimes > 0){
                        self.errorTimes = 0;
                    }
                    if(cmdIndex < cmdList.count){
                        
                        NSData *cmdData = [JCDataConvert hexToBytes:cmdList[cmdIndex]];
                        [mutAry addObject:cmdData];
                        //[[CBLECenterMnger shareMnger] wristWriteOTAData:cmdData];
                    }
                    cmdIndex ++;
                }
            }
            self.blockIndex ++;
        }
    }
    _curMsgNums ++;
    return mutAry;
}







-(BOOL)reLoadOTAData:(NSString*)strLocPath{
    
    BOOL bSuc = [self loadLocHexFile:strLocPath];
    if ( !bSuc )
        return NO;
    
    _fileManager = [[FileManager alloc] firmWareFile:strLocPath];
    self.totalSize = self.fileManager.length;
    [self initData];
    
    //发送命令01xx00 xx为文件分成的段数
    //NSInteger nNums = _fileManager.list.count;
    
    return YES;
}

-(void)initData{
    //OTA相关
    self.partitionIndex = 0;
    self.blockIndex = 0;
    self.cmdIndex = 0;
    self.flash_addr = 0;
    self.finshSize = 0;
    self.retryTimes = 3;
    self.curMsgNums = 0;
}


-(int)getPartitionCheckSum:(Partition *)partition {
    NSData *data = [JCDataConvert hexToBytes:partition.dataStr];
    return [JCDataConvert checkSum:0 byte:data];
}

-(NSString *) make_part_cmd:(int)index flash_addr:(int)flash_addr run_addr:(NSString *)run_addr size:(int)size checksum:(int)checksum {
    NSString *fa = [self strAdd0:[NSString stringWithFormat:@"%@",[JCDataConvert ToHex:flash_addr]] length:4];
    NSString *ra = [self strAdd0:run_addr length:4];
    NSString *sz = [self strAdd0:[NSString stringWithFormat:@"%@",[JCDataConvert ToHex:size]] length:4];
    NSString *cs = [self strAdd0:[NSString stringWithFormat:@"%@",[JCDataConvert ToHex:checksum]] length:2];
    NSString *Idindex = [self strAdd0:[NSString stringWithFormat:@"%@",[JCDataConvert ToHex:index]] length:1];
    return [NSString stringWithFormat:@"%@%@%@%@%@%@",@"02",Idindex,fa,ra,sz,cs];
}


-(NSString *)strAdd0:(NSString *)str length:(int)lenth {
    //不足8位 ，高位补0
    int strLength = str.length;
    for (int i=0;i<lenth*2-strLength;i++){
        str = [NSString stringWithFormat:@"%@%@",@"0",str];
    }
    NSMutableData *mData = [NSMutableData data];
    for (int i = 0; i < lenth ; i++) {
        NSUInteger int1 = 0x00;
        Byte bytes = int1 & 0xff;
        [mData appendBytes:&bytes length:1];
    }
    //NSLog(@"转换前mData:%@",mData);
    NSData *contentData = [JCDataConvert hexToBytes:str];
    
    Byte *byte= malloc(sizeof(Byte)*(lenth));
    [mData getBytes:byte length:lenth];
    NSUInteger length = contentData.length;
    Byte *contentByte = (Byte *)[contentData bytes];
    for (int j = 0; j < lenth; j++) {
        NSUInteger int1 = contentByte[lenth-j-1];
        Byte bytes = int1 & 0xff;
        byte[j] = bytes;
    }
    
    NSData *data = [[NSData alloc] initWithBytes:byte length:lenth];
    //NSLog(@"转换后mData:%@",data);
    NSString *contentStr = [JCDataConvert ConvertHexToString:data];//data转string
    return contentStr;
}


-(BOOL)loadLocHexFile:(NSString*)filePath{
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSData *fileData = [fileManager contentsAtPath:filePath];
    if( fileData == nil )
        return FALSE;
    
    NSString *strFileData = [JCDataConvert ConvertHexToString:fileData];
    if ( strFileData == nil )
        return FALSE;
    
    _partitionArray = [NSMutableArray arrayWithCapacity:0];
    _partitionArray = [[Partition alloc] analyzePartition:strFileData];
    
    return YES;
}

@end
