//
//  WebServer.m
//  CreativeToolApp
//
//  Created by frank.zheng on 2019/3/21.
//  Copyright © 2019 Vungle Inc. All rights reserved.
//

#import "WebServer.h"

#import <GCDWebServers/GCDWebServer.h>
#import <GCDWebServers/GCDWebServerDataResponse.h>
#import <GCDWebServers/GCDWebUploader.h>
@import ZipArchive;


#import "ResourceManager.h"
#import "AppConfig.h"



@interface WebServer()
@property(nonatomic, strong) GCDWebServer *webServer;
@property(nonatomic, strong) NSString *staticBasePath;
@property(nonatomic, strong) NSString *uploadBasePath;
@property(nonatomic, strong) NSString *uploadedEndcardName;
@property(nonatomic, strong) NSString *defaultEndcardName;
@property(nonatomic, strong) NSString *defaultVideoName;
@property(nonatomic, strong) ResourceManager *resourceManager;
@property(nonatomic, strong) AppConfig *config;

@end

@implementation WebServer

+(instancetype)sharedInstance {
    static WebServer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WebServer alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _webServer = [[GCDWebServer alloc] init];
        _portNumber = 8091;
        _staticBasePath = @"static/";
        _uploadBasePath = @"upload/";
        _defaultEndcardName = @"res/endcard.zip";
        _defaultVideoName = @"res/countdown_video.mp4";
        _resourceManager = [ResourceManager sharedInstance];
        _config = [AppConfig sharedConfig];
        
        //just use the first one for now
        _uploadedEndcardName = [_resourceManager.uploadEndcardNames firstObject];
    }
    return self;
    
}



- (void)setup {
    //setup end points
    __weak __typeof(self) weakSelf = self;
    
    //home page
    [_webServer addDefaultHandlerForMethod:@"GET"
                              requestClass:[GCDWebServerRequest class]
                              processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                  return [weakSelf homePageHandler:request];
                              }];
    
    //upload
    [_webServer addHandlerForMethod:@"POST"
                               path:@"/upload"
                       requestClass:[GCDWebServerMultiPartFormRequest class]
                       processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                           return [weakSelf uploadHandler:(GCDWebServerMultiPartFormRequest*)request];
                       }];
    
    //mock ad server config
    [_webServer addHandlerForMethod:@"POST"
                               path:@"/config"
                       requestClass:[GCDWebServerRequest class]
                       processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                           return [weakSelf adConfigHandler:request];
                       }];
    
    //ok -> {"msg":"ok", code:200}
    [_webServer addHandlerForMethod:@"POST"
                               path:@"/ok"
                       requestClass:[GCDWebServerRequest class]
                       processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                           return [weakSelf okHandler:request];
                       }];
    
    //ads
    [_webServer addHandlerForMethod:@"POST"
                               path:@"/ads"
                       requestClass:[GCDWebServerRequest class]
                       processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                           return [weakSelf adsHandler:request];
                       }];
    
    
    //static resources
    //base path
#if DEBUG
    NSUInteger cacheAge = 0;
#else
    NSUInteger cacheAge = 3600;
#endif
    
    [_webServer addGETHandlerForBasePath:[NSString stringWithFormat:@"/%@", _staticBasePath]
                           directoryPath:self.webStaticFolderPath
                           indexFilename:nil
                                cacheAge:cacheAge
                      allowRangeRequests:YES];
    
    [_webServer addGETHandlerForBasePath:[NSString stringWithFormat:@"/%@", _uploadBasePath]
                           directoryPath:self.webUploadFolderPath
                           indexFilename:nil
                                cacheAge:cacheAge
                      allowRangeRequests:YES];
    
    
    [_webServer startWithPort:_portNumber bonjourName:nil];
    NSLog(@"Visit %@ in your web browser", _webServer.serverURL);
    
    _started = YES;
    
}

- (NSURL *)serverURL {
    return self.webServer.serverURL;
}

- (NSString *)serverURLWithPath:(NSString*)path  {
    return [[self.serverURL URLByAppendingPathComponent:path] absoluteString];
}

- (NSString *)staticURLWithPath:(NSString*)path {
    //TODO: here if static base path is "/static/
    //The final URL will be http://192.168.1.78//static/xxx
    //Which is a invalid url for sdk, so change it to "static/"
    NSURL *staticBaseURL = [self.serverURL URLByAppendingPathComponent:_staticBasePath];
    return [[staticBaseURL URLByAppendingPathComponent:path] absoluteString];
}


- (NSString *)uploadURLWithPath:(NSString*)path {
    NSURL *uploadBaseURL = [self.serverURL URLByAppendingPathComponent:_uploadBasePath];
    return [[uploadBaseURL URLByAppendingPathComponent:path] absoluteString];
}



//for home page, "/" or "/index"
- (GCDWebServerResponse *)homePageHandler:(GCDWebServerRequest*)req {
    NSString *indexFile = [_webStaticFolderPath stringByAppendingPathComponent:@"index.html"];
    NSString *indexStr = [NSString stringWithContentsOfFile:indexFile
                                                   encoding:NSUTF8StringEncoding error:NULL];
    return [GCDWebServerDataResponse responseWithHTML:indexStr];
}

- (GCDWebServerDataResponse *)responseWithCode:(NSInteger)code msg:(NSString *)msg {
    return [self responseWithCode:code msg:msg data:@""];
}

- (GCDWebServerDataResponse *)responseWithCode:(NSInteger)code msg:(NSString *)msg data:(id)data {
    NSDictionary *json = @{@"code":@(code), @"msg":msg, @"data":data};
    return [GCDWebServerDataResponse responseWithJSONObject:json];
}

//for upload, user could upload end card zip file by using this
- (GCDWebServerResponse *)uploadHandler:(GCDWebServerMultiPartFormRequest*)req {
    
    GCDWebServerMultiPartFile* file = [req firstFileForControlName:@"bundle"];
    NSLog(@"%@, %@", file.temporaryPath, file.fileName);
    
    //SDK doesn't support end card name with spaces(%20), so here need replace it
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *uploadedFileName = [regex stringByReplacingMatchesInString:file.fileName options:0 range:NSMakeRange(0, file.fileName.length) withTemplate:@"_"];
    
    //verify end card zip
    NSString *targetZipPath = [file.temporaryPath stringByAppendingString:@"-unzipped"];
    if(![SSZipArchive unzipFileAtPath:file.temporaryPath
                        toDestination:targetZipPath
                            overwrite:YES password:nil error:&error]) {
        NSLog(@"Failed to unzip bundle, %@", error);
        return [self responseWithCode:1
                                  msg:[NSString stringWithFormat:@"Failed to unzip the bundle, %@", error]];
    }
    //check if has index.html
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *filenameList = [fm contentsOfDirectoryAtPath:targetZipPath error:&error];
    if(error) {
        NSLog(@"Failed to get contents from the zip folder, %@", error);
        return [self responseWithCode:1 msg:[NSString stringWithFormat:@"Failed to list files in the bundle, %@", error]];
    }
    BOOL hasEntryFile = NO;
    BOOL hasSubDir = NO;
    BOOL hasDownloadJs = NO;
    BOOL hasCompleteJs = NO;
    for (NSString *filename in filenameList) {
        NSString *filePath = [targetZipPath stringByAppendingPathComponent:filename];
        BOOL isDir = NO;
        if([fm fileExistsAtPath:filePath isDirectory:&isDir]) {
            hasSubDir = isDir;
            if(!isDir) {
                if([filename isEqualToString:@"index.html"]) {
                    hasEntryFile = YES;
                }
                //Search html and js to check if have download / complete function
                NSString *ext = [filename pathExtension];
                if ([ext caseInsensitiveCompare:@"html"] == NSOrderedSame ||
                    [ext caseInsensitiveCompare:@"js"] == NSOrderedSame) {
                    NSError *error = nil;
                    NSString *str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
                    if(error != nil) {
                        NSLog(@"Failed to read file: %@, %@", filePath, error);
                        return [self responseWithCode:1 msg:[NSString stringWithFormat:@"Failed to read file in the bundle, %@", error]];
                    }
                    
                    NSString *pattern = @"parent\\.postMessage\\s*\\(\\s*('|\")%@('|\")\\s*,\\s*('|\")\\*('|\")\\s*\\)";
                    NSString *downloadPar = [NSString stringWithFormat:pattern, @"download"];
                    NSString *completePar = [NSString stringWithFormat:pattern, @"complete"];
                    NSRange range = [str rangeOfString:downloadPar options:NSRegularExpressionSearch];
                    if (range.location != NSNotFound) {
                        hasDownloadJs = YES;
                    }
                    range = [str rangeOfString:completePar options:NSRegularExpressionSearch];
                    if (range.location != NSNotFound) {
                        hasCompleteJs = YES;
                    }
                }
            }
        }
    }
    
    if(!hasEntryFile) {
        NSLog(@"The uploaded endcard doesn't have index.html");
        return [self responseWithCode:1 msg:@"`index.html` NOT found!"];
    }
    
    if([_config verifyRequiredJsCalls]) {
        if(!hasDownloadJs) {
            NSLog(@"The uploaded endcard doesn't have download function");
            return [self responseWithCode:1 msg:@"parent.postMessage('download','*') NOT found!"];
        }
        
        if(!hasCompleteJs) {
            NSLog(@"The uploaded endcard doesn't have complete function");
            return [self responseWithCode:1 msg:@"parent.postMessage('complete','*') NOT found!"];
        }
    }
    
    //Move the uploaded end card zip to application support/web/upload
    NSString *targetPath = [_webUploadFolderPath stringByAppendingPathComponent:uploadedFileName];
    
    //because we only support 1 end card for now
    //so we just removed all uploaded end cards
    [_resourceManager cleanUpUploadFolder];
    
    
    if(![fm moveItemAtPath:file.temporaryPath toPath:targetPath error:&error]) {
        NSLog(@"Failed to move upload file to target path, %@", error);
        return [self responseWithCode:1 msg:[NSString stringWithFormat:@"Failed to move uploaded bundle file to destination folder, %@", error]];
    }
    
    //save the uploaded end card name
    _uploadedEndcardName = uploadedFileName;
    
    if(_delegate != nil && [_delegate respondsToSelector:@selector(onEndcardUploaded:)]) {
        [_delegate onEndcardUploaded:_uploadedEndcardName];
    }
    
    return [self responseWithCode:0 msg:@"Upload successfully"];
}

- (GCDWebServerResponse *)adConfigHandler:(GCDWebServerRequest*)req {
    NSString *configFilePath = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:configFilePath];
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSMutableDictionary *endpoints = [json[@"endpoints"] mutableCopy];
    endpoints[@"new"] = [self serverURLWithPath:@"ok"];
    endpoints[@"report_ad"] = [self serverURLWithPath:@"ok"];
    endpoints[@"ads"] = [self serverURLWithPath:@"ads"];
    
    //Following endpoints should not be called
    //logging is disabled
    //will_play_ad is disabled
    //ri is disabled
    //endpoints[@"log"] =
    //endpoints[@"will_play_ad"] =
    //endpoints[@"ri"] =
    NSMutableDictionary *mutableJson = [json mutableCopy];
    mutableJson[@"endpoints"] = endpoints;
    
    return [GCDWebServerDataResponse responseWithJSONObject:[mutableJson copy]];
}

- (GCDWebServerResponse *)adsHandler:(GCDWebServerRequest*)req {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ads" ofType:@"json"];
    //NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    NSString *str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    NSDictionary *variables = @{@"${postBundle}" : [self getEndcardPath],
                                @"${videoURL}" : [self staticURLWithPath:_defaultVideoName],
                                @"${expiry}" : @([self getNotExpiredTime]).stringValue};
    NSString *replacedStr = [self replaceString:str withVariables:variables];
    NSData *data = [replacedStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return [GCDWebServerDataResponse responseWithJSONObject:json];
}

- (GCDWebServerResponse *)okHandler:(GCDWebServerRequest*)req {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ok" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return [GCDWebServerDataResponse responseWithJSONObject:json];
}

- (NSString *)replaceString:(NSString *)str withVariables:(NSDictionary *)vars {
    NSString *res = str;
    for( NSString *key in [vars allKeys]) {
        NSString *value = vars[key];
        res = [res stringByReplacingOccurrencesOfString:key withString:value];
    }
    return res;
}

- (NSInteger )getNotExpiredTime {
    static const NSTimeInterval daySeconds = 3600.0 * 24;
    NSDate *now = [NSDate date];
    NSDate *expiredDate = [now dateByAddingTimeInterval: daySeconds * 7];
    return (NSInteger)([expiredDate timeIntervalSince1970]);
}

- (NSString *)getEndcardPath {
    //first check if upload folder has the one
    NSString *uploadEndcardPath = [_webUploadFolderPath stringByAppendingPathComponent:_uploadedEndcardName];
    NSFileManager *fm = [NSFileManager defaultManager];
    if(_uploadedEndcardName.length > 0 && [fm fileExistsAtPath:uploadEndcardPath]) {
        return [self uploadURLWithPath:_uploadedEndcardName];
    } else {
        //use default endcard
        return [self staticURLWithPath:_defaultEndcardName];
    }
}





@end
