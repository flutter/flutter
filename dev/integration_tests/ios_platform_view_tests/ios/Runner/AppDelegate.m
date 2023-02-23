// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "ViewFactory.h"
#import "TextFieldFactory.h"
#import "ButtonFactory.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  id<FlutterPluginRegistrar> registrar = [self registrarForPlugin:@"flutter"];
  [registrar registerViewFactory:[[ViewFactory alloc] init] withId:@"platform_view"];
  [registrar registerViewFactory:[[TextFieldFactory alloc] init] withId:@"platform_text_field"];
  [registrar registerViewFactory:[[ButtonFactory alloc] init] withId:@"platform_button"];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
