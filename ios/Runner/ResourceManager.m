//
//  ResourceManager.m
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import "ResourceManager.h"

@interface ResourceManager()
@property(nonatomic, strong) NSFileManager *fileManager;

@end

@implementation ResourceManager

+(instancetype)sharedInstance {
    static ResourceManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ResourceManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //only permit one end card for now
        _uploadEndcardMaxCount = 1;
        _fileManager = [NSFileManager defaultManager];
        
    }
    return self;
}

-(BOOL)setup {
    //copy the resources in the app bundle to documents for later use
    //copy web/static folder to Application Support/web/static folder
    NSString *supportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *webFolderPath = [supportPath stringByAppendingPathComponent:@"web"];
    //iOS does NOT allow load frameworks from documents or dirs, which could be used to do some hot patch
    _sdksFolderPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"sdks"];
    NSLog(@"web folder path: %@", webFolderPath);
    
    _webStaticFolderPath = [webFolderPath stringByAppendingPathComponent:@"static"];
    _webUploadFolderPath = [webFolderPath stringByAppendingPathComponent:@"upload"];
    _jsLogsFolderPath = [supportPath stringByAppendingPathComponent:@"js-logs"];
    BOOL isFolder = NO;
    
    if (![_fileManager fileExistsAtPath:webFolderPath isDirectory:&isFolder]) {
        //create web folder
        NSError *error = nil;
        if (![_fileManager createDirectoryAtPath:webFolderPath
                     withIntermediateDirectories:YES
                                      attributes:nil
                                           error:&error]) {
            NSLog(@"Failed to create web folder, %@, %@", webFolderPath, error);
            return NO;
        }
        
        if(![self setupWebStaticFolder]) {
            return NO;
        }
        
        if(![self setupWebUploadFolder]) {
            return NO;
        }
        
        if(![self setupJsLogsFolder]) {
            return NO;
        }
     }
    
#if DEBUG
    //try to copy & overwrite static folder every time for debugging
    if(![self setupWebStaticFolder]) {
        return NO;
    }
#endif
    
    _didSetup = YES;
    return YES;
}

//Create upload folder web/upload
- (BOOL)setupWebUploadFolder {
    NSError *error = nil;
    if(![_fileManager createDirectoryAtPath:_webUploadFolderPath
                withIntermediateDirectories:NO
                                 attributes:nil
                                      error:&error]) {
        NSLog(@"Failed to create web upload folder, %@", error);
        return NO;
    }
    return YES;
}

//Copy static folder in the app bundle to web/static
- (BOOL)setupWebStaticFolder {
    
    NSError *error = nil;
    NSString *staticPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"static"];
    if([_fileManager fileExistsAtPath:_webStaticFolderPath]) {
        if(![_fileManager removeItemAtPath:_webStaticFolderPath error:&error]) {
            NSLog(@"Failed to remove static folder before setup, %@", error);
            return NO;
        }
    }
    if (![_fileManager copyItemAtPath:staticPath toPath:_webStaticFolderPath error:&error]) {
        NSLog(@"Failed to copy web static resources, %@", error);
        return NO;
    }
    return YES;
}

- (BOOL)setupJsLogsFolder {
    NSError *error = nil;
    if(![_fileManager createDirectoryAtPath:_jsLogsFolderPath
                withIntermediateDirectories:NO
                                 attributes:nil
                                      error:&error]) {
        NSLog(@"Failed to create js logs folder, %@", error);
        return NO;
    }
    return YES;
}

- (NSArray<NSString *>*) uploadEndcardNames {
    BOOL isFolder = NO;
    NSMutableArray *names = [NSMutableArray array];
    if ([_fileManager fileExistsAtPath:_webUploadFolderPath isDirectory:&isFolder] && isFolder) {
        //list all files here
        NSError *error = nil;
        NSArray *filenameList = [_fileManager contentsOfDirectoryAtPath:_webUploadFolderPath error:&error];
        if(filenameList && error == nil) {
            for(NSString *filename in filenameList) {
                NSString *filePath = [_webUploadFolderPath stringByAppendingPathComponent:filename];
                if ([_fileManager fileExistsAtPath:filePath isDirectory:&isFolder] && !isFolder) {
                    [names addObject:filename];
                }
            }
        }
    }
    return [names copy];
}

//Remove all uploaded creatives
-(void)cleanUpUploadFolder {
    //for now, clean all end card in the upload foler
    NSError *error = nil;
    NSArray *filenameList = [_fileManager contentsOfDirectoryAtPath:_webUploadFolderPath error:&error];
    BOOL isFolder = NO;
    if(filenameList && error == nil) {
        for(NSString *filename in filenameList) {
            NSString *filePath = [_webUploadFolderPath stringByAppendingPathComponent:filename];
            if ([_fileManager fileExistsAtPath:filePath isDirectory:&isFolder] && !isFolder) {
                if (![_fileManager removeItemAtPath:filePath error:&error]) {
                    NSLog(@"Failed to remove %@, %@", filePath, error);
                }
            }
        }
    }
}





@end
