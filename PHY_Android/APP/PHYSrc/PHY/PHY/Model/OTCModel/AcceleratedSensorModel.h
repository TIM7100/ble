//
//  AcceleratedSensorModel.h
//  PHY
//
//  Created by Yang on 2018/10/16.
//  Copyright © 2018 phy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface AcceleratedSensorModel : BaseModel
@property(nonatomic,assign)int acceleratedXValue;
@property(nonatomic,assign)int acceleratedYValue;
@property(nonatomic,assign)int acceleratedZValue;
@end

NS_ASSUME_NONNULL_END
