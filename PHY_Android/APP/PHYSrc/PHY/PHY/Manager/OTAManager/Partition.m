//
//  Partition.m
//  PHY
//
//  Created by Han on 2018/11/5.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "Partition.h"

@implementation Partition

+(Partition *) partition:(NSString *)address data:(NSString *)dataStr {
    Partition *partition = [[Partition alloc]init];
    partition.address = address;
    partition.dataStr = dataStr;
    partition.partitionLength = dataStr.length/2;
    partition.partitionArray = [partition analyzePartition:dataStr];
    return partition;
}

//把数据分成若干小段
-(NSMutableArray *)analyzePartition:(NSString *)data {
    int index = 0;
    NSString *partitionStr = data;
    NSMutableArray *partitionArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *smallPieceData = nil;
    while (true) {
        if (index == 0) {
            smallPieceData = [NSMutableArray arrayWithCapacity:0];
        }

        if (partitionStr.length <= 20*2) {
            [smallPieceData addObject:partitionStr];
            [partitionArray addObject:smallPieceData];//大的分段放小分段
            break;
        } else {
            NSString *str = [partitionStr substringWithRange:NSMakeRange(0, 20*2)];
            partitionStr = [partitionStr substringWithRange:NSMakeRange(20*2, partitionStr.length-20*2)];
            [smallPieceData addObject:str];
            index ++;
        }
        if (smallPieceData.count == 16){
            [partitionArray addObject:smallPieceData];
            index = 0;
        }
    }
//    NSLog(@"大段的数据：%@",partitionArray);
    return partitionArray;
}

@end
