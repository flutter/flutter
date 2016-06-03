// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"

#import <Flutter/Flutter.h>
#import "LocationProvider.h"

@implementation AppDelegate {
    LocationProvider* _locationProvider;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    FlutterDartProject* project = [[FlutterDartProject alloc] initFromDefaultSourceForConfiguration];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    FlutterViewController* controller = [[FlutterViewController alloc] initWithProject:project
                                                                               nibName:nil
                                                                                bundle:nil];
    _locationProvider = [[LocationProvider alloc] init];
    [controller addMessageListener: _locationProvider];

    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
