// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_TEST_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_TEST_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterAppDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"

// Category to add test-only visibility.
@interface FlutterPluginSceneLifeCycleDelegate (Test)
@property(nonatomic, strong) UISceneConnectionOptions* connectionOptions;
@property(nonatomic, strong) NSPointerArray* flutterManagedEngines;
@property(nonatomic, strong) NSPointerArray* developerManagedEngines;

- (void)updateFlutterManagedEnginesInScene:(UIScene*)scene;
- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
           flutterEngine:(FlutterEngine*)engine
                 options:(UISceneConnectionOptions*)connectionOptions;
- (NSArray*)allEngines;

@end

@interface FlutterAppDelegate (Test)
@property(nonatomic, strong) FlutterPluginAppLifeCycleDelegate* lifeCycleDelegate;
@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_TEST_H_
