#include "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = [[FlutterViewController alloc] init];
  [self.window makeKeyAndVisible];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
