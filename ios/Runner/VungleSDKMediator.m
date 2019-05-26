//
//  VungleSDKMediator.m
//  Runner
//
//  Created by frank.zheng on 2019/5/20.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "VungleSDKMediator.h"
#import "VungleSDKProxyProtocol.h"
#import "FlutterChannelDefines.h"
#import "MethodResultBuilder.h"


#define kDefaultSDKVersion @"6.3.2"

@interface VungleSDKMediator() <VungleSDKProxyDelegate>
@property(nonatomic, strong) FlutterViewController *controller;
@property(nonatomic, strong) FlutterMethodChannel *sdkChan;
@property(nonatomic, strong) FlutterMethodChannel *sdkCallbackChan;
@property(nonatomic, strong) id<VungleSDKProxy> proxy;
@property(nonatomic, strong) NSDictionary *sdkVersionDict;
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
        //_proxy = [VungleSDKProxy sharedProxy];
        _sdkVersionDict = @{ @"6.3.2" : @"VungleSDKProxy_Vungle632.framework",
                             @"5.3.2" : @"VungleSDKProxy_Vungle532.framework"
                             };
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

- (BOOL)loadSDK:(NSString *)version error:(NSError **)error {
#if 1
    if(_sdkVersionDict[version] == nil) {
        version = kDefaultSDKVersion;
    }
    NSString *frameworkName = _sdkVersionDict[version];
    NSString *path = [_sdksFolderPath stringByAppendingPathComponent:frameworkName];
#else
    NSString *frameworkName = @"VungleSDKProxy.framework";
    NSString *path = [[[NSBundle mainBundle] privateFrameworksPath] stringByAppendingPathComponent:frameworkName];
#endif
    
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    if(!bundle) {
        NSString *description = [NSString stringWithFormat:@"%@ not found", path];
        NSLog(@"%@", description);
        *error = [NSError errorWithDomain:@"VungleCreativeTool"
                                     code:1001 userInfo:@{NSLocalizedDescriptionKey: description}];
        return NO;
    }
    
    if(![bundle loadAndReturnError:error]) {
        NSLog(@"Load %@ failed: %@", frameworkName, *error);
        return NO;
    } else {
        NSLog(@"Load %@ success", frameworkName);
    }
    
    Class clazz = NSClassFromString(@"VungleSDKProxyImpl");
    _proxy = [clazz sharedProxy];
    
    return YES;

}

- (NSDictionary*)startSDK:(NSDictionary *)params {
    //load sdk by it's version
    MethodResultBuilder *builder = [MethodResultBuilder builder];
    NSString *appId = params[@"appId"];
    NSArray<NSString *> *placements = params[@"placements"];
    NSString *serverURL = params[@"serverURL"];
    NSString *sdkVersion = params[@"sdkVersion"];
    NSError *error = nil;
    if(![self loadSDK:sdkVersion error:&error]) {
        [builder didError:error];
        return [builder build];
    }
    _proxy.delegate = self;
    _proxy.networkLoggingEnabled = NO;
    
    if(![_proxy startWithAppId:appId
                    placements:placements
                     serverURL:[NSURL URLWithString:serverURL]
                         error:&error]) {
        [builder didError:error];
    }
    return [builder build];
}

- (void)handleSDKMethods:(FlutterMethodCall *)call result:(FlutterResult)result {
    //NSLog(@"handleSDKMethods, method: %@, args: %@", call.method, call.arguments);
    MethodResultBuilder *builder = [MethodResultBuilder builder];
    NSError *error = nil;
    
    if([kSDKVerson isEqualToString:call.method]) {
        //sdk version
        result(_proxy.version);
    } else if([kSDKVersionList isEqualToString:call.method]) {
        //available sdk version list
        result([_sdkVersionDict allKeys]);
    } else if([kStartApp isEqualToString:call.method]) {
        //start sdk
        result([self startSDK:call.arguments]);
    } else if([kIsCached isEqualToString:call.method]) {
        //check if placeement is cached
        NSString *placementId = call.arguments;
        result(@([_proxy isAdCachedForPlacementID:placementId]));
    } else if([kLoadAd isEqualToString:call.method]) {
        NSString *placementId = call.arguments;
        if(![_proxy loadPlacementWithID:placementId error:&error]) {
            [builder didError:error];
        }
        result([builder build]);
    } else if([kPlayAd isEqualToString:call.method]) {
        //play ad
        NSDictionary *params = call.arguments;
        NSString *placementId = params[@"placementId"];
        NSNumber *isCORs = params[@"isCORs"];
        if(![_proxy playAd:_controller options:nil placementID:placementId enableCORs:isCORs.boolValue error:&error]) {
            [builder didError:error];
        }
        result([builder build]);
    } else if([kClearCache isEqualToString:call.method]) {
        //clear cache
        NSString *placementId = call.arguments;
        [_proxy clearCacheForPlacement:placementId completionBlock:^(NSError * _Nonnull error) {
            if(error != nil) {
                [builder didError:error];
            }
            result([builder build]);
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
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm Close Ad"
                                                    message:@"Some JS error happened, close ad?"
                                                   delegate:self
                                          cancelButtonTitle:@"NO"
                                          otherButtonTitles:@"YES", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1) {
        [_proxy forceCloseAd];
    }
}


- (void)onJSTrace:(NSString *)jsTrace {
    [_sdkCallbackChan invokeMethod:kOnLog arguments:@{@"type":@"trace", @"rawLog":jsTrace}];
}



@end
