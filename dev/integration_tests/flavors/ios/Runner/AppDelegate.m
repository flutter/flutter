// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)didInitializeImplicitFlutterEngine:(NSObject<FlutterImplicitEngineBridge>*)engineBridge {
  [GeneratedPluginRegistrant registerWithRegistry:engineBridge.pluginRegistry];

  FlutterMethodChannel* flavorChannel = [FlutterMethodChannel methodChannelWithName:@"flavor" binaryMessenger:engineBridge.applicationRegistrar.messenger];

  [flavorChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
    NSString* flavor = (NSString*)[[NSBundle mainBundle].infoDictionary valueForKey:@"Flavor"];
    result(flavor);
  }];
}

@end
