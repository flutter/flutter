// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "MainViewController.h"

@interface AppDelegate ()
@property(readwrite) FlutterEngine* engine;
@property(readwrite) FlutterBasicMessageChannel* reloadMessageChannel;
@property(nullable) MainViewController* mainViewController;
@property(nullable) UINavigationController* navigationController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  
  self.mainViewController = [[MainViewController alloc] init];
  self.navigationController = [[UINavigationController alloc]
                               initWithRootViewController:_mainViewController];

  self.navigationController.navigationBar.translucent = NO;

  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  self.engine = engine;
  [engine runWithEntrypoint:nil];
  
  self.reloadMessageChannel = [[FlutterBasicMessageChannel alloc]
                               initWithName:@"reload"
                               binaryMessenger:engine.binaryMessenger
                               codec:[FlutterStringCodec sharedInstance]];

  self.window.rootViewController = _navigationController;
  [self.window makeKeyAndVisible];

  return YES;
}

@end
