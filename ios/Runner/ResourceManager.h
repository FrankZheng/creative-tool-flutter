//
//  ResourceManager.h
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//This class used to manage the static resources for web content
@interface ResourceManager : NSObject
@property(nonatomic, readonly) NSString *webStaticFolderPath;
@property(nonatomic, readonly) NSString *webUploadFolderPath;
@property(nonatomic, readonly) NSString *sdksFolderPath;
@property(nonatomic, readonly) NSString *jsLogsFolderPath;
@property(nonatomic, readonly) NSArray<NSString *> *uploadEndcardNames;
@property(nonatomic, assign) NSInteger uploadEndcardMaxCount;
@property(nonatomic, readonly) BOOL didSetup;


+(instancetype)sharedInstance;

-(BOOL)setup;

//remove all uploaded creatives
-(void)cleanUpUploadFolder;


@end

NS_ASSUME_NONNULL_END

