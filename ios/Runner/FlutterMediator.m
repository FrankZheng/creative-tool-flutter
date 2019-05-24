//
//  FlutterMediator.m
//  Runner
//
//  Created by frank.zheng on 2019/5/15.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//
#import "FlutterMediator.h"
#import "WebServer.h"
#import "AppConfig.h"
#import "ResourceManager.h"
#import "AppModel.h"


//Web Server channel and method names
#define kWebServerChan @"com.vungle.vcltool/webserver"
#define kEndcardName @"endCardName"
#define kServerURL @"serverURL"
#define kLocalhostURL @"localhostURL"

//Web Server callbacks channel and method names
#define kWebServerCallbackChan @"com.vungle.vcltool/webserverCallbacks"
#define kEndcardUploaded @"endcardUploaded"

#define kAppChan @"com.vungle.vcltool/app"
#define kCloseApp @"closeApp"

//App Config channel and method names
#define kAppConfigChan @"com.vungle.vcltool/appConfig"
#define kCurrentSDKVersion @"currentSDKVersion"
#define kSDKVersions @"sdkVersions"
#define kSetCurrentSDKVersion @"setCurrentSDKVersion"
#define kCORsEnabled @"isCORsEnabled"
#define kSetCORsEnabled @"setCORsEnabled"
#define kVerifyJsCalls @"verifyJsCalls"
#define kSetVerifyJsCalls @"setVerifyJsCalls"

@interface FlutterMediator() <WebServerDelegate, UIAlertViewDelegate>
@property(nonatomic, strong) FlutterViewController *controller;
@property(nonatomic, strong) FlutterMethodChannel *webServerChan;
@property(nonatomic, strong) FlutterMethodChannel *webServerCallbackChan;
@property(nonatomic, strong) FlutterMethodChannel *appConfigChan;
@property(nonatomic, strong) FlutterMethodChannel *appChan;

@property(nonatomic, strong) AppConfig* appConfig;
@property(nonatomic, strong) WebServer* webServer;
@property(nonatomic, strong) ResourceManager *resourceManager;



@end


@implementation FlutterMediator

+ (instancetype)sharedInstance {
    static FlutterMediator* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FlutterMediator alloc] init];
    });
    return instance;
}


- (void)startWithFlutterViewController:(FlutterViewController*)vc {
    _controller = vc;
    
    __weak typeof(self) weakSelf = self;
    
    _webServer = [WebServer sharedInstance];
    [_webServer setDelegate:self];
    
    _appConfig = [AppConfig sharedConfig];
    _resourceManager = [ResourceManager sharedInstance];
    
    _webServerChan = [FlutterMethodChannel methodChannelWithName:kWebServerChan binaryMessenger:_controller];
    [_webServerChan setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        [weakSelf handleWebServerMethods:call result:result];
    }];
    _webServerCallbackChan = [FlutterMethodChannel methodChannelWithName:kWebServerCallbackChan binaryMessenger:_controller];
    
    _appConfigChan = [FlutterMethodChannel methodChannelWithName:kAppConfigChan binaryMessenger:_controller];
    [_appConfigChan setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        [weakSelf handleAppConfigMethods:call result:result];
    }];
    
    _appChan = [FlutterMethodChannel methodChannelWithName:kAppChan binaryMessenger:_controller];
    [_appChan setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        [weakSelf handleAppMethods:call result:result];
    }];
    
}

- (void)handleWebServerMethods:(FlutterMethodCall *)call result:(FlutterResult)result {
    if([kServerURL isEqualToString:call.method]) {
        NSURL *url = _webServer.serverURL;
        result(url.absoluteString);
    } else if([kLocalhostURL isEqualToString:call.method]) {
        NSURL *url = _webServer.localhostURL;
        result(url.absoluteString);
    } else if([kEndcardName isEqualToString:call.method]) {
        NSArray<NSString*> *names = _resourceManager.uploadEndcardNames;
        if(names.count > 0) {
            result(names[0]);
        } else {
            result(nil);
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)handleAppMethods:(FlutterMethodCall *)call result:(FlutterResult)result {
    if([kCloseApp isEqualToString:call.method]) {
        result(nil);
        [AppModel closeApp];
    }
}


- (void)handleAppConfigMethods:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([kCurrentSDKVersion isEqualToString:call.method]) {
        result(_appConfig.currentSdkVersion);
    } else if([kSDKVersions isEqualToString:call.method]) {
        result(_appConfig.sdkVersions);
    } else if([kSetCurrentSDKVersion isEqualToString:call.method]) {
        NSString *newVersion = call.arguments;
        if(![_appConfig.currentSdkVersion isEqualToString:newVersion]) {
            [_appConfig setCurrentSDKVersion:newVersion];
            
            [[UIApplication sharedApplication] performSelector:@selector(suspend)];
            [NSThread sleepForTimeInterval:2.0];
            exit(0);
        }
        result(@(YES));
    } else if([kCORsEnabled isEqualToString:call.method]) {
        result(@(_appConfig.isCORsEnabled));
    } else if([kSetCORsEnabled isEqualToString:call.method]) {
        NSNumber *num = call.arguments;
        [_appConfig setCORsEnabled:num.boolValue];
        result(@(YES));
    } else if([kVerifyJsCalls isEqualToString:call.method]) {
        result(@(_appConfig.verifyRequiredJsCalls));
    } else if([kSetVerifyJsCalls isEqualToString:call.method]) {
        NSNumber *num = call.arguments;
        [_appConfig setVerifyRequiredJsCalls:num.boolValue];
        result(@(YES));
    } else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - WebServerDelegate methods
-(void)onEndcardUploaded:(NSString *)zipName {
    [_webServerCallbackChan invokeMethod:kEndcardUploaded arguments:zipName];
}

@end
