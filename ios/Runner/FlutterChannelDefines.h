//
//  FlutterChannelDefines.h
//  Runner
//
//  Created by frank.zheng on 2019/5/26.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

//For method return value (true/false), error
#define kReturnValue @"return"
#define kErrCode @"errCode"
#define kErrMsg @"errMsg"


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
#define kSDKVersionList @"sdkVersionList"

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
