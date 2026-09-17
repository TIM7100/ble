//
//  HeartRateModel.h
//  PHY
//
//  Created by Yang on 2018/10/15.
//  Copyright © 2018 phy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface HeartRateModel : BaseModel
//测量到的最终数值
@property(nonatomic,assign)NSUInteger heartRateLastValue;
@property(nonatomic,strong)NSMutableArray *heartRateOriginalDataArr;//测量心率的原始数据
@end

NS_ASSUME_NONNULL_END
