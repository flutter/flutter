// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#include "SimplePlatformView.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSLog(@"[AppDelegate] didFinishLaunchingWithOptions called");
  NSLog(@"[AppDelegate] Note: Plugin registration moved to didInitializeImplicitFlutterEngine (UIScene lifecycle)");
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)didInitializeImplicitFlutterEngine:(NSObject<FlutterImplicitEngineBridge>*)engineBridge {
  NSLog(@"[AppDelegate] didInitializeImplicitFlutterEngine called - UIScene lifecycle active!");
  NSLog(@"[AppDelegate] engineBridge: %@", engineBridge);
  NSLog(@"[AppDelegate] pluginRegistry: %@", engineBridge.pluginRegistry);
  
  [GeneratedPluginRegistrant registerWithRegistry:engineBridge.pluginRegistry];
  NSLog(@"[AppDelegate] Plugins registered successfully");

  // Register platform view factory.
  NSObject<FlutterPluginRegistrar>* registrar = [engineBridge.pluginRegistry registrarForPlugin:@"spv-plugin"];
  SimplePlatformViewFactory* factory = [[SimplePlatformViewFactory alloc] initWithMessenger:registrar.messenger];
  [registrar registerViewFactory:factory withId:@"simple-platform-view"];
  NSLog(@"[AppDelegate] Platform view factory registered");
}

@end
