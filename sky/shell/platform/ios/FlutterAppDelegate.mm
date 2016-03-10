// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/ios/FlutterAppDelegate.h"
#include "sky/shell/platform/ios/public/FlutterViewController.h"
#include "base/trace_event/trace_event.h"

@implementation FlutterAppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  TRACE_EVENT0("flutter", "applicationDidFinishLaunchingWithOptions");

  NSBundle* dartBundle = [NSBundle
      bundleWithIdentifier:@"io.flutter.application.FlutterApplication"];

  CGRect frame = [UIScreen mainScreen].bounds;
  UIWindow* window = [[UIWindow alloc] initWithFrame:frame];
  FlutterViewController* viewController =
      [[FlutterViewController alloc] initWithDartBundle:dartBundle];
  window.rootViewController = viewController;
  [viewController release];
  self.window = window;
  [window release];
  [self.window makeKeyAndVisible];

  return YES;
}

@end
