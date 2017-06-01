// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#include "PlatformViewController.h"

@implementation AppDelegate {
  FlutterResult _flutterResult;
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  FlutterViewController* controller =
  (FlutterViewController*)self.window.rootViewController;
  FlutterMethodChannel* channel =
  [FlutterMethodChannel methodChannelWithName:@"samples.flutter.io/platform_view"
                              binaryMessenger:controller];
  [channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    if ([@"switchView" isEqualToString:call.method]) {
      _flutterResult = result;
      PlatformViewController* platformViewController =
      [controller.storyboard instantiateViewControllerWithIdentifier:@"PlatformView"];
      platformViewController.counter = ((NSNumber*)call.arguments).intValue;
      platformViewController.delegate = self;
      UINavigationController* navigationController =
      [[UINavigationController alloc] initWithRootViewController:platformViewController];
      navigationController.navigationBar.topItem.title = @"Platform View";
      [controller presentViewController:navigationController animated:NO completion:nil];
    } else {
      result(FlutterMethodNotImplemented);
    }
  }];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)didUpdateCounter:(int)counter {
  _flutterResult([NSNumber numberWithInt:counter]);
}

@end
