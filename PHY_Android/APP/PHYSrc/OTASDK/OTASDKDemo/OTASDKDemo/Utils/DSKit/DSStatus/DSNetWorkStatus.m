//
//  DSNetWorkStatus.m
//  DSDeveloperKit
//
//  Created by FengDongsheng on 12/7/25.
//  Copyright (c) 2012年 FengDongsheng. All rights reserved.
//

#import "DSNetWorkStatus.h"

@interface DSNetWorkStatus()
@property (nonatomic) DSReachability *hostReachability;
//@property (nonatomic) Reachability *internetReachability;
//@property (nonatomic) Reachability *wifiReachability;
@end

@implementation DSNetWorkStatus

- (instancetype)init{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kDSReachabilityChangedNotification object:nil];
        NSString *remoteHostName = @"www.baidu.com";
        self.hostReachability = [DSReachability reachabilityWithHostName:remoteHostName];
        [self.hostReachability startNotifier];
        
//        self.internetReachability = [Reachability reachabilityForInternetConnection];
//        [self.internetReachability startNotifier];
//        
//        self.wifiReachability = [Reachability reachabilityForLocalWiFi];
//        [self.wifiReachability startNotifier];
    }
    return self;
}

+ (instancetype)sharedNetWorkStatus{
    static DSNetWorkStatus *dsNetWorkStatus = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dsNetWorkStatus = [[DSNetWorkStatus alloc] init];
        dsNetWorkStatus.netWorkStatus = ReachableUnknown;
    });
    return dsNetWorkStatus;
}

- (void) reachabilityChanged:(NSNotification *)note{
    DSReachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[DSReachability class]]);
    self.netWorkStatus = [curReach currentReachabilityStatus];
//    [self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(DSReachability *)reachability{
//    if (reachability == self.hostReachability){
//        NetworkStatus netStatus = [reachability currentReachabilityStatus];
//        BOOL connectionRequired = [reachability connectionRequired];
//        
//        NSString* baseLabelText = @"";
//        
//        if (connectionRequired){
//            baseLabelText = NSLocalizedString(@"Cellular data network is available.\nInternet traffic will be routed through it after a connection is established.", @"Reachability text if a connection is required");
//        }else{
//            baseLabelText = NSLocalizedString(@"Cellular data network is active.\nInternet traffic will be routed through it.", @"Reachability text if a connection is not required");
//        }
//    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDSReachabilityChangedNotification object:nil];
}
@end
