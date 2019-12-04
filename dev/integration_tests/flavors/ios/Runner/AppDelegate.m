// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
  FlutterMethodChannel* flavorChannel = [FlutterMethodChannel methodChannelWithName:@"flavor" binaryMessenger:controller];

  [flavorChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
    NSString* flavor = (NSString*)[[NSBundle mainBundle].infoDictionary valueForKey:@"Flavor"];
    result(flavor);
  }];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
