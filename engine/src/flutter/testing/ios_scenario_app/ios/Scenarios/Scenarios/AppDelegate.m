// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"

#import "ContinuousTexture.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  NSArray<NSString*>* processArguments = NSProcessInfo.processInfo.arguments;
  if ([processArguments containsObject:@"--enable-software-rendering"]) {
    @throw @"--enable-software-rendering is unsupported in iOS scenario tests";
  }

  // The window and its root view controller are set up by SceneDelegate.
  if ([processArguments containsObject:@"--with-continuous-texture"]) {
    [ContinuousTexture
        registerWithRegistrar:[self registrarForPlugin:@"com.constant.firing.texture"]];
  }
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
