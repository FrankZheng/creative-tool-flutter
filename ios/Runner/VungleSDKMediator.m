//
//  VungleSDKMediator.m
//  Runner
//
//  Created by frank.zheng on 2019/5/20.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "VungleSDKMediator.h"
@import VungleSDKProxy;


//SDK channel and method names
#define kSDKChan @"com.vungle.vcltool/vungleSDK"
#define kSDKVerson @"sdkVersion"
#define kIsInitialized @"isInitialized"
#define kStartApp @"startApp"
#define kLoadAd @"loadAd"
#define kPlayAd @"playAd"
#define kForceCloseAd @"forceCloseAd"
#define kClearCache @"clearCache"
#define kIsCached @"isCached"

//SDK callbacks channel and method names
#define kSDKCallbackChan @"com.vungle.vcltool/vungleSDKCallbacks"
#define kSDKDidInitialized @"sdkDidInitialized"
#define kSDKFailedToInitialize @"sdkFailedToInitialize"
#define kAdLoaded @"adLoaded"
#define kAdLoadFailed @"adLoadFailed"
#define kAdWillShow @"adWillShow"
#define kAdWillClose @"adWillClose"
#define kAdDidClose @"adDidClose"
#define kOnLog @"onLog"

#define kReturnValue @"return"
#define kErrCode @"errCode"
#define kErrMsg @"errMsg"

//TODO: add utility for NSError -> dictionary
//TODO: add utility for encode placement id to dictionary


@interface VungleSDKMediator() <VungleSDKProxyDelegate>
@property(nonnull, strong) FlutterViewController *controller;
@property(nonnull, strong) FlutterMethodChannel *sdkChan;
@property(nonnull, strong) FlutterMethodChannel *sdkCallbackChan;
@property(nonnull, strong) VungleSDKProxy *proxy;
@end

@implementation VungleSDKMediator

+(instancetype)sharedInstance {
    static VungleSDKMediator *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VungleSDKMediator alloc] init];
    });
    
    return instance;
}


-(instancetype)init {
    self = [super init];
    if (self) {
        _proxy = [VungleSDKProxy sharedProxy];
    }
    return self;
}

- (void)startWithFlutterViewController:(FlutterViewController*)vc {
    __weak typeof(self) weakSelf = self;
    _controller = vc;
    _sdkChan = [FlutterMethodChannel methodChannelWithName:kSDKChan binaryMessenger:_controller];
    [_sdkChan setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        [weakSelf handleSDKMethods:call result:result];
    }];
    _sdkCallbackChan = [FlutterMethodChannel methodChannelWithName:kSDKCallbackChan binaryMessenger:_controller];
}

- (void)handleSDKMethods:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSLog(@"handleSDKMethods, method: %@, args: %@", call.method, call.arguments);
    if([kSDKVerson isEqualToString:call.method]) {
        //sdk version
        result(_proxy.version);
    } else if([kStartApp isEqualToString:call.method]) {
        //start sdk
        NSDictionary *params = call.arguments;
        NSString *appId = params[@"appId"];
        NSArray<NSString *> *placements = params[@"placements"];
        NSString *serverURL = params[@"serverURL"];
        NSError *error = nil;
        NSMutableDictionary *ret = [NSMutableDictionary dictionary];
        ret[kReturnValue] = @(YES);
        _proxy.delegate = self;
        if(![_proxy startWithAppId:appId
                        placements:placements
                         serverURL:[NSURL URLWithString:serverURL]
                             error:&error]) {
            ret[kReturnValue] = @(NO);
            if(error != nil) {
                ret[kErrCode] = @(error.code);
                ret[kErrMsg] = error.localizedDescription;
            }
        }
        result(ret);
    } else if([kIsCached isEqualToString:call.method]) {
        //check if placeement is cached
        NSString *placementId = call.arguments;
        result(@([_proxy isAdCachedForPlacementID:placementId]));
    } else if([kLoadAd isEqualToString:call.method]) {
        NSString *placementId = call.arguments;
        NSMutableDictionary *ret = [NSMutableDictionary dictionary];
        ret[kReturnValue] = @(YES);
        NSError *error = nil;
        if(![_proxy loadPlacementWithID:placementId error:&error]) {
            ret[kReturnValue] = @(NO);
            if(error != nil) {
                ret[kErrCode] = @(error.code);
                ret[kErrMsg] = error.localizedDescription;
            }
        }
        result(ret);
    } else if([kPlayAd isEqualToString:call.method]) {
        //play ad
        NSDictionary *params = call.arguments;
        NSString *placementId = params[@"placementId"];
        NSNumber *isCORs = params[@"isCORs"];
        NSMutableDictionary *ret = [NSMutableDictionary dictionary];
        ret[kReturnValue] = @(YES);
        NSError *error = nil;
        if(![_proxy playAd:_controller options:nil placementID:placementId enableCORs:isCORs.boolValue error:&error]) {
            ret[kReturnValue] = @(NO);
            if(error != nil) {
                ret[kErrCode] = @(error.code);
                ret[kErrMsg] = error.localizedDescription;
            }
        }
        result(ret);
    } else if([kClearCache isEqualToString:call.method]) {
        //clear cache
        NSString *placementId = call.arguments;
        [_proxy clearCacheForPlacement:placementId completionBlock:^(NSError * _Nonnull error) {
            NSMutableDictionary *ret = [NSMutableDictionary dictionary];
            ret[kReturnValue] = @(YES);
            if(error != nil) {
                ret[kReturnValue] = @(NO);
                ret[kErrCode] = @(error.code);
                ret[kErrMsg] = error.localizedDescription;
            }
            result(ret);
        }];
    } else if([kForceCloseAd isEqualToString:call.method]) {
        //force close ad
        [_proxy forceCloseAd];
        result(@(YES));
    } else {
        result(FlutterMethodNotImplemented);
    }
}


#pragma mark - VungleSDKProxyDelegate methods
- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(nullable NSString *)placementID error:(nullable NSError *)error {
    if(isAdPlayable) {
        [_sdkCallbackChan invokeMethod:kAdLoaded arguments:placementID];
    } else {
        if(error != nil) {
            NSDictionary *params = @{ @"placementId": placementID,
                                      kErrCode:@(error.code),
                                      kErrMsg:error.localizedDescription};
            [_sdkCallbackChan invokeMethod:kAdLoadFailed arguments:params];
        }
    }
}

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID {
    [_sdkCallbackChan invokeMethod:kAdWillShow arguments:placementID];
}

- (void)vungleWillCloseAdWithViewInfo:(nonnull VungleSDKViewInfo *)info placementID:(nonnull NSString *)placementID {
    NSDictionary *dict = @{@"placementId":placementID,
                           @"completed": info.completedView,
                           @"didDownload": info.didDownload,
                           @"playTime": info.playTime};
    [_sdkCallbackChan invokeMethod:kAdWillClose arguments:dict];
}

- (void)vungleDidCloseAdWithViewInfo:(nonnull VungleSDKViewInfo *)info placementID:(nonnull NSString *)placementID {
    NSDictionary *dict = @{@"placementId":placementID,
                           @"completed": info.completedView,
                           @"didDownload": info.didDownload,
                           @"playTime": info.playTime};
    [_sdkCallbackChan invokeMethod:kAdDidClose arguments:dict];
}

- (void)vungleSDKDidInitialize {
    [_sdkCallbackChan invokeMethod:kSDKDidInitialized arguments:nil];
}

- (void)vungleSDKFailedToInitializeWithError:(NSError *)error {
    
    [_sdkCallbackChan invokeMethod:kSDKFailedToInitialize
                         arguments:error == nil ? nil : @{kErrCode:@(error.code), kErrMsg:error.localizedDescription}];
}

- (void)onSDKLog:(NSString *)log {
    [_sdkCallbackChan invokeMethod:kOnLog arguments:@{@"type":@"sdk", @"rawLog":log}];
}

//javascript debug stuff
- (void)onJSLog:(NSString *)jsLog {
    [_sdkCallbackChan invokeMethod:kOnLog arguments:@{@"type":@"log", @"rawLog":jsLog}];
}

- (void)onJSError:(NSString *)jsError {
    [_sdkCallbackChan invokeMethod:kOnLog arguments:@{@"type":@"error", @"rawLog":jsError}];
}

- (void)onJSTrace:(NSString *)jsTrace {
    [_sdkCallbackChan invokeMethod:kOnLog arguments:@{@"type":@"trace", @"rawLog":jsTrace}];
}



@end
