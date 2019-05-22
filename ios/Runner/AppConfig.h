//
//  AppConfig.h
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppConfig : NSObject

+(instancetype)sharedConfig;

+(NSString *)appId;
+(NSString *)placementId;

-(void)setup;

//sdk versions
-(NSString *)currentSdkVersion;
-(NSArray<NSString *>*)sdkVersions;
-(void)setCurrentSDKVersion:(NSString *)sdkVersion;

//CORs - cross domain resources sharing
-(BOOL)isCORsEnabled;
-(void)setCORsEnabled:(BOOL)enabled;

//Verify required javascript calls
//like parent.postMessage('download', '*');
//like parent.postMessage('complete', '*');
-(BOOL)verifyRequiredJsCalls;
-(void)setVerifyRequiredJsCalls:(BOOL)verifyRequiredJsCalls;

@end

NS_ASSUME_NONNULL_END
