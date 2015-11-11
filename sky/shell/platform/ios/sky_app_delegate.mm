// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_app_delegate.h"
#import "sky_view_controller.h"

@implementation SkyAppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {

  CGRect frame = [UIScreen mainScreen].bounds;
  UIWindow* window = [[UIWindow alloc] initWithFrame:frame];
  SkyViewController* viewController = [[SkyViewController alloc] init];
  window.rootViewController = viewController;
  [viewController release];
  self.window = window;
  [window release];
  [self.window makeKeyAndVisible];

  return YES;
}

@end
