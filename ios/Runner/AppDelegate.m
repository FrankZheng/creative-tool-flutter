#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "AppInitializer.h"
#import "FlutterMediator.h"
#import "VungleSDKMediator.h"
@import HockeySDK;

#define kHockeyAppId @"9e59f741179240f8a6570a2dc3653508"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //for hockey sdk
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:kHockeyAppId];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    
    [[AppInitializer sharedInstance] start];
    
    [GeneratedPluginRegistrant registerWithRegistry:self];
    
    FlutterViewController *controller = (FlutterViewController*)self.window.rootViewController;
    [[FlutterMediator sharedInstance] startWithFlutterViewController:controller];
    [[VungleSDKMediator sharedInstance] startWithFlutterViewController:controller];
    
    
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
