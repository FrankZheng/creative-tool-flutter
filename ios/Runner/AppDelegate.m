#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "AppInitializer.h"
#import "FlutterMediator.h"
#import "VungleSDKMediator.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[AppInitializer sharedInstance] start];
    
    [GeneratedPluginRegistrant registerWithRegistry:self];
    
    FlutterViewController *controller = (FlutterViewController*)self.window.rootViewController;
    [[FlutterMediator sharedInstance] startWithFlutterViewController:controller];
    [[VungleSDKMediator sharedInstance] startWithFlutterViewController:controller];
    
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
