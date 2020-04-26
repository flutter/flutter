// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "MainViewController.h"

@interface AppDelegate ()

@property(nonatomic, strong, readwrite) FlutterEngine* engine;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  MainViewController *mainViewController = [[MainViewController alloc] init];
  UINavigationController *navigationController = [[UINavigationController alloc]
      initWithRootViewController:mainViewController];

  navigationController.navigationBar.translucent = NO;

  self.engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [self.engine runWithEntrypoint:nil];

  self.window.rootViewController = navigationController;
  [self.window makeKeyAndVisible];

  return YES;
}

@end
