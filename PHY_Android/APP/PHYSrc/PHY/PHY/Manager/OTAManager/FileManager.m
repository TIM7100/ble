//
//  FileManager.m
//  PHY
//
//  Created by Han on 2018/11/5.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "FileManager.h"
#import "DDFileReader.h"
#import "JCDataConvert.h"
#import "Partition.h"

@interface FileManager()
@end

@implementation FileManager

- (instancetype)firmWareFile:(NSString *)filePath {
    FileManager *file = [[FileManager alloc]init];
    file.list = [NSMutableArray arrayWithCapacity:0];
    file.list = [[self analyzeFile:filePath] copy];
    self.list = [NSMutableArray arrayWithCapacity:0];
    self.list = file.list;
    file.length = [self getLength];
    return file;
}

-(NSArray *)analyzeFile:(NSString *)path  {
    DDFileReader * reader = [[DDFileReader alloc]initWithFilePath:path];
    int size = 0;
    NSString *result;
    int flag = 0;
    NSString *address = @"";
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:0];
    NSString * readline = nil;
    BOOL stop = NO;

    while (stop == NO && (readline = [reader readLine])) {
//        NSLog(@"read line:%@",readline);
        NSString *hexSize = [readline substringWithRange:NSMakeRange(1, 2)];
        size = [JCDataConvert hexNumberStringToNumber:hexSize];

        if ([[readline substringWithRange:NSMakeRange(7, 2)] isEqualToString:@"04"]) {
            if (result.length>0) {
                Partition *partition = [Partition partition:address data:result];
                [list addObject:partition];
            }
            address = [readline substringWithRange:NSMakeRange(9, 4)];
            flag = 0;
            result = @"";
            continue;
        }

        if ([[readline substringWithRange:NSMakeRange(7, 2)] isEqualToString:@"05"] || [[readline substringWithRange:NSMakeRange(7, 2)] isEqualToString:@"01"]) {
            Partition *partition = [Partition partition:address data:result];
            [list addObject:partition];
            break;
        }

        if (flag == 0) {
            flag = 1;
            NSString *str = [readline substringWithRange:NSMakeRange(3, 4)];
            address = [NSString stringWithFormat:@"%@%@",address,str];
        }

        NSString *resultStr = [readline substringWithRange:NSMakeRange(9, size*2)];
        result = [NSString stringWithFormat:@"%@%@",result,resultStr];
    }
    return list;
}

-(long)getLength {
    long size = 0;
    for (Partition *partition in self.list) {
        
        size += partition.partitionArray.count;
        //size += partition.partitionLength;
    }
    return size;
}
@end
