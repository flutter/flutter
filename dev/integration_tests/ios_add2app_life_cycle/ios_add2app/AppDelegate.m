// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "MainViewController.h"

@implementation GREYHostApplicationDistantObject (AppDelegate)

- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}

@end

@interface AppDelegate ()

@property(nonatomic, strong, readwrite) FlutterEngine* engine;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [self.engine runWithEntrypoint:nil];

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                                   options:(UISceneConnectionOptions *)options {
  return [[UISceneConfiguration alloc] initWithName:@"Default Configuration"
                                        sessionRole:connectingSceneSession.role];
}

@end
