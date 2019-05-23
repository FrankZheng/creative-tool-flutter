//
//  VungleSDKProxy.h
//  VungleSDKProxy
//
//  Created by Frank Zheng on 2019/5/19.
//  Copyright © 2019 Frank Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "VungleSDKProxyProtocol.h"

NS_ASSUME_NONNULL_BEGIN

//@interface VungleSDKViewInfo : NSObject
//@property (nonatomic, readonly) NSNumber *completedView;
//@property (nonatomic, readonly) NSNumber *playTime;
//@property (nonatomic, readonly) NSNumber *didDownload;
//@end
//
//
//@protocol VungleSDKProxyDelegate<NSObject>
//@optional
//
//- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(nullable NSString *)placementID error:(nullable NSError *)error;
//
//- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID;
//
//- (void)vungleWillCloseAdWithViewInfo:(nonnull VungleSDKViewInfo *)info placementID:(nonnull NSString *)placementID;
//
//- (void)vungleDidCloseAdWithViewInfo:(nonnull VungleSDKViewInfo *)info placementID:(nonnull NSString *)placementID;
//
//- (void)vungleSDKDidInitialize;
//
//- (void)vungleSDKFailedToInitializeWithError:(NSError *)error;
//
//- (void)onSDKLog:(NSString *)log;
//
////javascript debug stuff
//- (void)onJSLog:(NSString *)jsLog;
//
//- (void)onJSError:(NSString *)jsError;
//
//- (void)onJSTrace:(NSString *)jsTrace;
//
//
//@end

@interface VungleSDKProxyImpl : NSObject<VungleSDKProxy>


@end

NS_ASSUME_NONNULL_END

