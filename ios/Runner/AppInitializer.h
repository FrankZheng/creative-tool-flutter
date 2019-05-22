//
//  AppInitializer.h
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/29.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AppInitializerDelegate

- (void)appDidInitialize;

@end

@interface AppInitializer : NSObject
@property(nonatomic, readonly, getter=isInitialized) BOOL initialized;

+ (instancetype)sharedInstance;

- (void)addDelegate:(id<AppInitializerDelegate>)delegate;

- (void)start;

@end

NS_ASSUME_NONNULL_END
