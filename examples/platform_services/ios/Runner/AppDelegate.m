// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"

#import <Flutter/Flutter.h>

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  FlutterDartProject* project = [[FlutterDartProject alloc] initFromDefaultSourceForConfiguration];
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  FlutterViewController* controller = [[FlutterViewController alloc] initWithProject:project
                                                                             nibName:nil
                                                                              bundle:nil];
  FlutterMethodChannel* batteryChannel =
    [FlutterMethodChannel withController:controller
                                    name:@"battery"
                                   codec:[FlutterStandardMethodCodec shared]];
  [batteryChannel handleMethodCallsWith:
   ^(FlutterMethodCall* call, FlutterResultReceiver result) {
      if ([@"getBatteryLevel" isEqualToString:call.method]) {
        [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
        int batterLevel = (int)([[UIDevice currentDevice] batteryLevel] * 100);
        result([NSNumber numberWithInt:batterLevel], nil);
      } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Unknown method"
                                     userInfo:nil];
      }
    }
  ];

  self.window.rootViewController = controller;
  [self.window makeKeyAndVisible];
  return YES;
}

@end
