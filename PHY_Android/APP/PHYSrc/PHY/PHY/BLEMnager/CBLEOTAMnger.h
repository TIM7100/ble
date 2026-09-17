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

@class CBLEOTAMnger;
@protocol CBLEOTAMngerDelegate <NSObject>
@optional
- (void)updateOTAProgress:(nullable CBLEOTAMnger *) manager
                     feedBackInfo:(float)progressValue;

- (void)updateOTAComplete:(nullable CBLEOTAMnger *) manager
                       isComplete:(BOOL)isComplete;

- (void)updateOTAError:(nullable CBLEOTAMnger *) manager
                     errorCode:(NSUInteger)errorCode;

@end

@interface CBLEOTAMnger : NSObject

@property (nonatomic, weak, nullable) id <CBLEOTAMngerDelegate> delegate;
-(BOOL)startOTAWithLocFile:(NSString*)filePath;

+(NSString*)errCode2Str:(NSUInteger)nCode;
@end




NS_ASSUME_NONNULL_END
