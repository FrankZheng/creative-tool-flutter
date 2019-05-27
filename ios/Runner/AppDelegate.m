#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "AppInitializer.h"
#import "FlutterMediator.h"
#import "VungleSDKMediator.h"
@import HockeySDK;

#define kHockeyAppId @"f804b56571a54567875a445545f74b78"

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
