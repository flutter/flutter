// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "SceneDelegate.h"
#import "MainViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
  UIWindowScene *windowScene = (UIWindowScene *)scene;
  self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

  MainViewController *mainViewController = [[MainViewController alloc] init];
  UINavigationController *navigationController =
      [[UINavigationController alloc] initWithRootViewController:mainViewController];

  navigationController.navigationBar.translucent = NO;

  self.window.rootViewController = navigationController;
  [self.window makeKeyAndVisible];
}

@end
