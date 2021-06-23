// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "MainViewController.h"

@interface AppDelegate ()

@end

static NSString *_kReloadChannelName = @"reload";

@implementation AppDelegate {
  MainViewController *_mainViewController;
  UINavigationController *_navigationController;
  FlutterEngine *_engine;
  FlutterBasicMessageChannel *_reloadMessageChannel;
}

- (FlutterEngine *)engine {
  return _engine;
}

- (FlutterBasicMessageChannel *)reloadMessageChannel {
  return _reloadMessageChannel;
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  _mainViewController = [[MainViewController alloc] init];
  _navigationController = [[UINavigationController alloc]
      initWithRootViewController:_mainViewController];

  _navigationController.navigationBar.translucent = NO;

  _engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [_engine runWithEntrypoint:nil];

  _reloadMessageChannel = [[FlutterBasicMessageChannel alloc]
         initWithName:_kReloadChannelName
      binaryMessenger:_engine.binaryMessenger
                codec:[FlutterStringCodec sharedInstance]];

  self.window.rootViewController = _navigationController;
  [self.window makeKeyAndVisible];

  return YES;
}

@end
