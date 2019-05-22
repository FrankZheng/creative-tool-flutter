//
//  VunglePostRollWebViewHooks.m
//  VungleSDKProxy
//
//  Created by Frank Zheng on 2019/5/19.
//  Copyright © 2019 Frank Zheng. All rights reserved.
//

#import "VunglePostRollWebViewHooks.h"
#import "VungleSDKProxy.h"
@import WebKit;
@import ObjectiveC;


@interface VungleSDKProxy()
@property(nonatomic, weak) id<ForceCloseAdDelegate> forceCloseAdDelegate;
@property(nonatomic, assign) BOOL isCORsEnabled;

//handle javascript debug stuff
- (void)onJSLog:(NSString *)log;
- (void)onJSError:(NSString *)error;
- (void)onJSTrace:(NSString *)trace;
@end

@implementation NSObject(VunglePostRollWebViewHooks)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class clazz = objc_getClass("VunglePostRollWebView");
        Method loadMethod = class_getInstanceMethod(clazz, @selector(load));
        Method newLoadMethod = class_getInstanceMethod(self, @selector(new_load));
        method_exchangeImplementations(loadMethod, newLoadMethod);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        Method jsMsgHandlerMethod = class_getInstanceMethod(clazz, @selector(javascriptMessageHandler:));
#pragma clang diagnostic pop
        Method newJsMsgHandlerMethod = class_getInstanceMethod(self, @selector(new_javascriptMessageHandler:));
        method_exchangeImplementations(jsMsgHandlerMethod, newJsMsgHandlerMethod);
    });
    
}

- (void)new_load {
    id obj = [self valueForKey:@"webView"];
    VungleSDKProxy *proxy = [VungleSDKProxy sharedProxy];
    if([obj isKindOfClass:[WKWebView class]]) {
        //NSLog(@"new_load");
        WKWebView *webView = (WKWebView *)obj;
        //inject extra js script for debugging
        NSBundle *bundle = [NSBundle bundleForClass:proxy.class];
        NSString *scriptFilePath = [bundle pathForResource:@"inject" ofType:@"js"];
        //NSLog(@"scriptFilePath:%@", scriptFilePath);
        NSError *error = nil;
        NSString *script = [NSString stringWithContentsOfFile:scriptFilePath encoding:NSUTF8StringEncoding error:&error];
        //NSLog(@"script:%@", @(script.length));
        WKUserScript *userScript = [[ WKUserScript alloc] initWithSource:script
                                                           injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                        forMainFrameOnly:YES];
        [webView.configuration.userContentController addUserScript:userScript];
        
        BOOL isCORsEnabled = proxy.isCORsEnabled;
        [webView.configuration.preferences setValue:@(isCORsEnabled) forKey:@"allowFileAccessFromFileURLs"];
    }
    //call original `load` implementation
    //register to the sdk delegate to get the `force close ad` event from app side
    proxy.forceCloseAdDelegate = self;
    [self new_load];
}

- (BOOL)new_javascriptMessageHandler:(NSString *)message {
    //NSLog(@"new_javascriptMessageHandler:%@", message);
    NSArray *prefixes = @[@"log:", @"error:", @"trace:"];
    for(NSString *prefix in prefixes) {
        if([message hasPrefix:prefix]) {
            NSString *content = [message substringFromIndex:prefix.length];
            if([prefix isEqualToString:@"log:"]) {
                //js log
                [[VungleSDKProxy sharedProxy] onJSLog:content];
            } else if([prefix isEqualToString:@"trace:"]) {
                //js trace
                [[VungleSDKProxy sharedProxy] onJSTrace:content];
            } else if([prefix isEqualToString:@"error:"]) {
                //js error
                [[VungleSDKProxy sharedProxy] onJSError:content];
            }
            return YES;
        }
    }
    
    return [self new_javascriptMessageHandler:message];
}

//force close ad
- (void)onForceCloseAd {
    [self new_javascriptMessageHandler:@"button:close"];
}


@end
