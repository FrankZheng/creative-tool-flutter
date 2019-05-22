//
//  AppConfig.m
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import "AppConfig.h"

#define kActiveSDKVersion @"ActiveSDKVerison"
#define kCORsIsEnabled @"IsCORsEnabled"
#define kDefaultSDKVersion @"6.3.2"
#define kVerifyRequiredJsCalls @"VerifyRequiredJsCalls"


@interface AppConfig()
@property(nonatomic, strong) NSString *currentSDKVerison;
@property(nonatomic, strong) NSArray<NSString *> *sdkVersions;
@property(nonatomic, assign) BOOL isCORsEnabled;
@property(nonatomic, strong) NSUserDefaults *defaults;
@property(nonatomic, assign) BOOL verifyJsCalls;
@end

@implementation AppConfig

+(instancetype)sharedConfig {
    static AppConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AppConfig alloc] init];
    });
    return instance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _defaults = [NSUserDefaults standardUserDefaults];
        
    }
    
    return self;
}

+(NSString *)appId {
    return @"CreativeTool";
}

+(NSString *)placementId {
    return @"LOCAL01";
}

-(void)setup {
    //TODO:
    _sdkVersions = @[@"6.3.2", @"5.3.2"];
    
    //load sdk version from defaults
    _currentSDKVerison = [_defaults objectForKey:kActiveSDKVersion];
    if(!_currentSDKVerison) {
        _currentSDKVerison = kDefaultSDKVersion;
    }
    
    //load CORs enabled from defaults
    NSNumber *enabled = [_defaults objectForKey:kCORsIsEnabled];
    if (!enabled) {
        _isCORsEnabled = NO;
    } else {
        _isCORsEnabled = [enabled boolValue];
    }
    
    enabled = [_defaults objectForKey:kVerifyRequiredJsCalls];
    if (!enabled) {
        _verifyJsCalls = YES;
    } else {
        _verifyJsCalls = [enabled boolValue];
    }
    
    
}

- (NSString *)currentSdkVersion {
    return _currentSDKVerison;
}

-(NSArray<NSString *>*)sdkVersions {
    return _sdkVersions;
}

-(void)setCurrentSDKVersion:(NSString *)sdkVersion {
    if (![sdkVersion isEqualToString:_currentSDKVerison]) {
        _currentSDKVerison = sdkVersion;
        [_defaults setObject:sdkVersion forKey:kActiveSDKVersion];
    }
}

//CORs - cross domain resources sharing
- (BOOL)isCORsEnabled {
    return _isCORsEnabled;
}

- (void)setCORsEnabled:(BOOL)enabled {
    if (_isCORsEnabled != enabled) {
        _isCORsEnabled = enabled;
        [_defaults setBool:enabled forKey:kCORsIsEnabled];
    }
}

- (BOOL)verifyRequiredJsCalls {
    return _verifyJsCalls;
}

- (void)setVerifyRequiredJsCalls:(BOOL)verifyRequiredJsCalls {
    if (verifyRequiredJsCalls != _verifyJsCalls) {
        _verifyJsCalls = verifyRequiredJsCalls;
        [_defaults setBool:verifyRequiredJsCalls forKey:kVerifyRequiredJsCalls];
    }
}



@end
