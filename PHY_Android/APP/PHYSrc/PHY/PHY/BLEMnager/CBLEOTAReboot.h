//
//  CBLEMnger.h
//  PHY
//
//  Created by Harry on 2019/3/23.
//  Copyright © 2019年 phy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


NS_ASSUME_NONNULL_BEGIN

@class CBLEOTAReboot;
@protocol CBLEOTARebootDelegate <NSObject>
@optional

- (void)rebootFinish:(nullable CBLEOTAReboot *) manager
                       bFinish:(BOOL)bFinish;

@end

@interface CBLEOTAReboot : NSObject
@property (nonatomic, weak, nullable) id <CBLEOTARebootDelegate> delegate;
- (BOOL)rebootAutoConnect;
@end




NS_ASSUME_NONNULL_END
