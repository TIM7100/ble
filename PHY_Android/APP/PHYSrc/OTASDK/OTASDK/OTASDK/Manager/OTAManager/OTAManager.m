//
//  OTAManager.m
//  PHY
//
//  Created by Yang on 2018/10/13.
//  Copyright © 2018 phy. All rights reserved.
//

#import "OTAManager.h"
#import "JCDataConvert.h"
#import "DDFileReader.h"

static OTAManager *_manager;

@interface OTAManager()
@property(strong,nonatomic)NSMutableArray *partitionArray;//段落数组，元素为16*20个字节，每小段又有16段20个字节 的数据
@property(strong,nonatomic) NSString *address;
@property(strong,nonatomic) NSString *dataStr;
@property(assign,nonatomic) int partitionLength;

@end

@implementation OTAManager

+ (OTAManager *)shareOTAManager{
    @synchronized(self) {
        if (!_manager) {
            _manager = [[OTAManager alloc]init];
        }
    }
    return _manager;
}

-(void)cacelOTAUpdate:(BOOL)isCancel {
    if ([self.delegate respondsToSelector:@selector(cancelOTASuccess:feedBackInfo:)]) {
        [self.delegate cancelOTASuccess:self feedBackInfo:isCancel];
    }
}

-(void)isInOTAPageUpdate:(BOOL)isCancel {
    if ([self.delegate respondsToSelector:@selector(isInOTAPageUpdate:feedBackInfo:)]) {
        [self.delegate isInOTAPageUpdate:self feedBackInfo:isCancel];
    }
}
@end
