//
//  VungleSDKProxy.m
//  VungleSDKProxy
//
//  Created by Frank Zheng on 2019/5/19.
//  Copyright © 2019 Frank Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VungleSDKProxy.h"
#import <VungleSDK/VungleSDK.h>
#import "ObjcUtils.h"
#import "ForceCloseAdDelegate.h"
@import ObjectiveC;

@interface VungleSDKViewInfo()
@property (nonatomic, strong) NSNumber *completedView;
@property (nonatomic, strong) NSNumber *playTime;
@property (nonatomic, strong) NSNumber *didDownload;

-(instancetype)initWithVungleViewInfo:(VungleViewInfo*)info;
@end

@implementation VungleSDKViewInfo

-(instancetype)initWithVungleViewInfo:(VungleViewInfo*)info {
    self = [super init];
    if (self) {
        _completedView = [info.completedView copy];
        _playTime = [info.playTime copy];
        _didDownload = [info.didDownload copy];
    }
    return self;
}

@end


@interface VungleSDK ()
- (void)setPluginName:(NSString *)pluginName version:(NSString *)version;
- (void)setHTTPHeaderPair:(NSDictionary *)header;
- (void)clearAdUnitCreativesForPlacement:(NSString *)placementRefID
                         completionBlock:(nullable void (^)(NSError *))completionBlock;
- (NSArray *)getValidPlacementInfo;
@end

@interface VungleSDKProxy() <VungleSDKDelegate, VungleSDKLogger>
@property(nonatomic, strong) VungleSDK *sdk;
@property(nonatomic, strong) NSUserDefaults *defaults;
@property(nonatomic, weak) id<ForceCloseAdDelegate> forceCloseAdDelegate;
@property(nonatomic, assign) BOOL isCORsEnabled;

- (void)onVungleAdPlayabilityUpdate:(BOOL)isAdPlayable
                        placementID:(nullable NSString *)placementID
                              error:(nullable NSError *)error;

//handle javascript debug stuff
- (void)onJSLog:(NSString *)log;
- (void)onJSError:(NSString *)error;
- (void)onJSTrace:(NSString *)trace;


@end

void onVungleAdPlayabilityUpdate(id self, SEL _cmd, BOOL isAdPlayable, NSString *placementID, NSError *error) {
    [self onVungleAdPlayabilityUpdate:isAdPlayable placementID:placementID error:error];
}

void onVungleAdPlayabilityUpdateWithoutError(id self, SEL _cmd, BOOL isAdPlayable, NSString *placementID) {
    [self onVungleAdPlayabilityUpdate:isAdPlayable placementID:placementID error:nil];
}


@implementation VungleSDKProxy

+(instancetype)sharedProxy {
    static VungleSDKProxy *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if([ObjcUtils isSelector:@selector(vungleAdPlayabilityUpdate:placementID:error:)
                      ofProtocol:@protocol(VungleSDKDelegate)]) {
            //add implementation at runtime to class
            //BOOL is different on 32bit/64bit devices
            NSString *types = [NSString stringWithFormat:@"v@:%s@@", @encode(BOOL)];
            class_addMethod([VungleSDKProxy class],
                            @selector(vungleAdPlayabilityUpdate:placementID:error:),
                            (IMP)onVungleAdPlayabilityUpdate,
                            [types UTF8String]);
        }
#pragma GCC diagnostic pop
        else {
            NSString *types = [NSString stringWithFormat:@"v@:%s@", @encode(BOOL)];
            class_addMethod([VungleSDKProxy class],
                            @selector(vungleAdPlayabilityUpdate:placementID:),
                            (IMP)onVungleAdPlayabilityUpdateWithoutError,
                            [types UTF8String]);
        }
        
        instance = [[VungleSDKProxy alloc] init];
    });
    return instance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _defaults = [NSUserDefaults standardUserDefaults];
        _version = VungleSDKVersion;
    }
    return self;
}

- (void)setNetworkLoggingEnabled:(BOOL)networkLoggingEnabled {
    [_defaults setBool:networkLoggingEnabled forKey:@"vungle.network_logging"];
}


- (BOOL)startWithAppId:(nonnull NSString *)appID
            placements:(nullable NSArray <NSString *> *)placements
             serverURL:(NSURL *)serverURL
                 error:(NSError **)error {
    //if sdk not initialized, try to initialize
    //Should set end point before sdk instantiation, and url should not have "/" at the last.
    //It's tricky, but needed for 5.3.2 version
    _serverURL = serverURL;
    NSString *url = self.serverURL.absoluteString;
    if([url characterAtIndex:url.length-1] == '/') {
        url = [url substringWithRange:NSMakeRange(0,url.length-1)];
    }
    [_defaults setObject:url forKey:@"vungle.api_endpoint"];
    
    _sdk = [VungleSDK sharedSDK];
    [_sdk setLoggingEnabled:YES];
    [_sdk attachLogger:self];
    _sdk.delegate = self;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_sdk startWithAppId:appID placements:placements error:error];
#pragma clang diagnostic pop

}


- (BOOL)isAdCachedForPlacementID:(nonnull NSString *)placementID {
    return [_sdk isAdCachedForPlacementID:placementID];
}

- (BOOL)loadPlacementWithID:(NSString *)placementID error:(NSError **)error {
    return [_sdk loadPlacementWithID:placementID error:error];
}

- (BOOL)playAd:(UIViewController *)controller
       options:(nullable NSDictionary *)options
   placementID:(nullable NSString *)placementID
    enableCORs:(BOOL)enableCORs
         error:(NSError *__autoreleasing _Nullable *_Nullable)error {
    _isCORsEnabled = enableCORs;
    return [_sdk playAd:controller options:options placementID:placementID error:error];
}

- (void)forceCloseAd {
    [_forceCloseAdDelegate onForceCloseAd];
}

- (void)clearCacheForPlacement:(NSString *)placementID
               completionBlock:(nullable void (^)(NSError *))completionBlock {
    
    [_sdk clearAdUnitCreativesForPlacement:placementID completionBlock:completionBlock];
}

- (void)onVungleAdPlayabilityUpdate:(BOOL)isAdPlayable
                        placementID:(nullable NSString *)placementID
                              error:(nullable NSError *)error {
    [_delegate vungleAdPlayabilityUpdate:isAdPlayable placementID:placementID error:error];
}

- (void)onJSLog:(NSString *)log {
    if ([_delegate respondsToSelector:@selector(onJSLog:)]) {
        [_delegate onJSLog:log];
    }
}

- (void)onJSError:(NSString *)error {
    if ([_delegate respondsToSelector:@selector(onJSError:)]) {
        [_delegate onJSError:error];
    }
}

- (void)onJSTrace:(NSString *)trace {
    if ([_delegate respondsToSelector:@selector(onJSTrace:)]) {
        [_delegate onJSTrace:trace];
    }
}



#pragma mark - VungleSDKLogger methods

- (void)vungleSDKLog:(NSString *)message {
    if([_delegate respondsToSelector:@selector(onSDKLog:)]) {
        [_delegate onSDKLog:message];
    }
}


#pragma mark - VungleSDKDelegate methods

- (void)vungleSDKDidInitialize {
    if([_delegate respondsToSelector:@selector(vungleSDKDidInitialize)]) {
        [_delegate vungleSDKDidInitialize];
    }
}

- (void)vungleSDKFailedToInitializeWithError:(NSError *)error {
    if([_delegate respondsToSelector:@selector(vungleSDKFailedToInitializeWithError:)]) {
        [_delegate vungleSDKFailedToInitializeWithError:error];
    }
}

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID {
    if([_delegate respondsToSelector:@selector(vungleWillShowAdForPlacementID:)]) {
        [_delegate vungleWillShowAdForPlacementID:placementID];
    }
}

- (void)vungleWillCloseAdWithViewInfo:(nonnull VungleViewInfo *)info placementID:(nonnull NSString *)placementID {
    if ([_delegate respondsToSelector:@selector(vungleWillCloseAdWithViewInfo:placementID:)]) {
        [_delegate
         vungleWillCloseAdWithViewInfo:[[VungleSDKViewInfo alloc] initWithVungleViewInfo:info]
                           placementID:placementID];
    }
    
    //SDK5.3.2 don't have `vungleDidCloseAd` method, so here could simulate one
    if ([_delegate respondsToSelector:@selector(vungleDidCloseAdWithViewInfo:placementID:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        __weak typeof(self) weakSelf = self;
        if(![ObjcUtils isSelector:@selector(vungleDidCloseAdWithViewInfo:placementID:)
                       ofProtocol:@protocol(VungleSDKDelegate)]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.delegate vungleDidCloseAdWithViewInfo:[[VungleSDKViewInfo alloc] initWithVungleViewInfo:info]
                                            placementID:placementID];
            });
        }
#pragma GCC diagnostic pop
    }
}

- (void)vungleDidCloseAdWithViewInfo:(nonnull VungleViewInfo *)info placementID:(nonnull NSString *)placementID {
    if ([_delegate respondsToSelector:@selector(vungleDidCloseAdWithViewInfo:placementID:)]) {
        [_delegate vungleDidCloseAdWithViewInfo:[[VungleSDKViewInfo alloc] initWithVungleViewInfo:info]
                                    placementID:placementID];
    }
}
@end
