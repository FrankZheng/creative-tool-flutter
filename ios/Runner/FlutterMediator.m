//
//  FlutterMediator.m
//  Runner
//
//  Created by frank.zheng on 2019/5/15.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//
#import "FlutterMediator.h"
#import "WebServer.h"
#import "ResourceManager.h"
#import "AppModel.h"


//Web Server channel and method names
#define kWebServerChan @"com.vungle.vcltool/webserver"
#define kEndcardName @"endCardName"
#define kServerURL @"serverURL"
#define kLocalhostURL @"localhostURL"
#define kEnableVerifyJsCalls @"enableVerifyRequiredJsCalls"

//Web Server callbacks channel and method names
#define kWebServerCallbackChan @"com.vungle.vcltool/webserverCallbacks"
#define kEndcardUploaded @"endcardUploaded"

#define kAppChan @"com.vungle.vcltool/app"
#define kCloseApp @"closeApp"

@interface FlutterMediator() <WebServerDelegate, UIAlertViewDelegate>
@property(nonatomic, strong) FlutterViewController *controller;
@property(nonatomic, strong) FlutterMethodChannel *webServerChan;
@property(nonatomic, strong) FlutterMethodChannel *webServerCallbackChan;
@property(nonatomic, strong) FlutterMethodChannel *appChan;

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
    
    _resourceManager = [ResourceManager sharedInstance];
    
    _webServerChan = [FlutterMethodChannel methodChannelWithName:kWebServerChan binaryMessenger:_controller];
    [_webServerChan setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        [weakSelf handleWebServerMethods:call result:result];
    }];
    _webServerCallbackChan = [FlutterMethodChannel methodChannelWithName:kWebServerCallbackChan binaryMessenger:_controller];
    
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
    } else if([kEnableVerifyJsCalls isEqualToString:call.method]) {
        NSNumber *enabled = call.arguments;
        _webServer.verifyRequiredJsCalls = enabled.boolValue;
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

#pragma mark - WebServerDelegate methods
-(void)onEndcardUploaded:(NSString *)zipName {
    [_webServerCallbackChan invokeMethod:kEndcardUploaded arguments:zipName];
}

@end
