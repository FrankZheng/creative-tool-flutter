//
//  VungleSDKProxyProtocol.h
//  VungleSDKProxy
//
//  Created by frank.zheng on 2019/5/23.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VungleSDKViewInfo : NSObject
@property (nonatomic, readonly) NSNumber *completedView;
@property (nonatomic, readonly) NSNumber *playTime;
@property (nonatomic, readonly) NSNumber *didDownload;
@end


@protocol VungleSDKProxyDelegate<NSObject>
@optional

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(nullable NSString *)placementID error:(nullable NSError *)error;

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID;

- (void)vungleWillCloseAdWithViewInfo:(nonnull VungleSDKViewInfo *)info placementID:(nonnull NSString *)placementID;

- (void)vungleDidCloseAdWithViewInfo:(nonnull VungleSDKViewInfo *)info placementID:(nonnull NSString *)placementID;

- (void)vungleSDKDidInitialize;

- (void)vungleSDKFailedToInitializeWithError:(NSError *)error;

- (void)onSDKLog:(NSString *)log;

//javascript debug stuff
- (void)onJSLog:(NSString *)jsLog;

- (void)onJSError:(NSString *)jsError;

- (void)onJSTrace:(NSString *)jsTrace;


@end


@protocol VungleSDKProxy
@property(nonatomic, readonly) NSString* version;
@property (atomic, readonly, getter = isInitialized) BOOL initialized;
@property(nonatomic, weak) id<VungleSDKProxyDelegate> delegate;
@property(nonatomic, readonly) NSURL* serverURL;
@property(nonatomic, assign) BOOL networkLoggingEnabled;

+(instancetype)sharedProxy;

- (BOOL)startWithAppId:(nonnull NSString *)appID
            placements:(nullable NSArray <NSString *> *)placements
             serverURL:(NSURL *)serverURL
                 error:(NSError **)error;

- (BOOL)isAdCachedForPlacementID:(nonnull NSString *)placementID;

- (BOOL)loadPlacementWithID:(NSString *)placementID error:(NSError **)error;

- (BOOL)playAd:(UIViewController *)controller
       options:(nullable NSDictionary *)options
   placementID:(nullable NSString *)placementID
    enableCORs:(BOOL)enableCORs
         error:(NSError *__autoreleasing _Nullable *_Nullable)error;

- (void)clearCacheForPlacement:(NSString *)placementID
               completionBlock:(nullable void (^)(NSError *))completionBlock;

- (void)forceCloseAd;


@end



NS_ASSUME_NONNULL_END
