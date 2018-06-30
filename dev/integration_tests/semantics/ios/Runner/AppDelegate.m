#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
  FlutterMethodChannel* semanticsChannel = [FlutterMethodChannel methodChannelWithName:@"semantics" binaryMessenger:controller];
  
  [semanticsChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
    NSNumber* id = (NSNumber*)[[NSBundle mainBundle].infoDictionary valueForKey:@"id"];
    result(nil);
  }];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
