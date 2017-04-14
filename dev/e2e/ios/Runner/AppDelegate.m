// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "AppDelegate.h"
#include "PluginRegistry.h"

@implementation AppDelegate {
  PluginRegistry *plugins;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  FlutterViewController *flutterController =
      (FlutterViewController *)self.window.rootViewController;
  plugins = [[PluginRegistry alloc] initWithController:flutterController];
  return YES;
}

@end
