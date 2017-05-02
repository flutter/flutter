#import <Flutter/Flutter.h>
#include "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

  // The following keeps the Flutter session alive when the device screen locks
  // in debug mode. It allows continued use of features like hot reload and 
  // taking screenshots once the device unlocks again.
  if ([@"debug" isEqualToString:
       [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FLTBuildMode"]]) {
    [application beginBackgroundTaskWithName:@"Flutter debug task"
                           expirationHandler:^{NSLog(@"Flutter debug task expired");}];
  }
}

@end
