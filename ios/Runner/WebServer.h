//
//  WebServer.h
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@protocol WebServerDelegate
@optional

-(void)onEndcardUploaded:(NSString *)zipName;

@end

@interface WebServer : NSObject
@property(nonatomic, readonly, nullable) NSURL* serverURL;
@property(nonatomic, assign) NSInteger portNumber;
@property(nonatomic, copy) NSString *webStaticFolderPath;
@property(nonatomic, copy) NSString *webUploadFolderPath;
@property(nonatomic, weak) NSObject<WebServerDelegate> *delegate;
@property(nonatomic, readonly, getter=isStarted) BOOL started;


+(instancetype)sharedInstance;

-(void)setup;

@end

NS_ASSUME_NONNULL_END
