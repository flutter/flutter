#import "AppDelegate.h"
#import "FlutterPluginRegistrant/GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)didInitializeImplicitFlutterEngine:(NSObject<FlutterImplicitEngineBridge>*)engineBridge {
  [GeneratedPluginRegistrant registerWithRegistry:engineBridge.pluginRegistry];
}

@end
