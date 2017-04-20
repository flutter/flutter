// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterAppDelegate.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#include "lib/ftl/logging.h"

@implementation FlutterAppDelegate {
  UIBackgroundTaskIdentifier _debugBackgroundTask;
}

// Returns the key window's rootViewController, if it's a FlutterViewController.
// Otherwise, returns nil.
- (FlutterViewController*)rootFlutterViewController {
  UIViewController* viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
  if ([viewController isKindOfClass:[FlutterViewController class]]) {
    return (FlutterViewController*)viewController;
  }
  return nil;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  [super touchesBegan:touches withEvent:event];

  // Pass status bar taps to key window Flutter rootViewController.
  if (self.rootFlutterViewController != nil) {
    [self.rootFlutterViewController handleStatusBarTouches:event];
  }
}

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
- (void)applicationDidEnterBackground:(UIApplication *)application {
  // The following keeps the Flutter session alive when the device screen locks
  // in debug mode. It allows continued use of features like hot reload and 
  // taking screenshots once the device unlocks again.
  //
  // Note the name is not an identifier and multiple instances can exist. 
  _debugBackgroundTask = [application beginBackgroundTaskWithName:@"Flutter debug task"
                                                expirationHandler:^{
      FTL_LOG(WARNING) << "\nThe OS has terminated the Flutter debug connection for being "
                          "inactive in the background for too long.\n\n"
                          "There are no errors with your Flutter application.\n\n"
                          "To reconnect, launch your application again via 'flutter run";
      }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  [application endBackgroundTask: _debugBackgroundTask];
}
#endif  // FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG

@end
