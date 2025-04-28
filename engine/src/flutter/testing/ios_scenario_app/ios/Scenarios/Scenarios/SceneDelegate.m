// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "SceneDelegate.h"
#import "AppDelegate.h"

@implementation SceneDelegate

- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
                 options:(UISceneConnectionOptions*)connectionOptions API_AVAILABLE(ios(13.0)) {
  if (![[[UIApplication sharedApplication] delegate] isKindOfClass:[AppDelegate class]]) {
    return;
  }
  AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  UIWindowScene* windowScene = (UIWindowScene*)scene;
  self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
  self.window.rootViewController = appDelegate.window.rootViewController;
  appDelegate.window = self.window;
  [self.window makeKeyAndVisible];
}

@end
