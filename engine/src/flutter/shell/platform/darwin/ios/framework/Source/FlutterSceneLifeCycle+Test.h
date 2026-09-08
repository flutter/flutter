// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_TEST_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_TEST_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterAppDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"

@class FlutterViewController;

// Category to add test-only visibility.
@interface FlutterPluginSceneLifeCycleDelegate (Test)
@property(nonatomic, strong) NSMapTable<UIScene*, NSPointerArray*>* developerManagedEngines;
@property(nonatomic, strong)
    NSMapTable<UIScene*, UISceneConnectionOptions*>* connectingScenes;
@property(nonatomic, strong) NSMapTable<UIScene*, NSPointerArray*>* enginesSentConnectionEvent;
@property(nonatomic, strong)
    NSMapTable<UIScene*, NSNumber*>* sceneWillConnectEventHandledByPlugin;

- (NSArray<FlutterViewController*>*)searchFlutterViewControllersWithScene:(UIScene*)scene;
- (NSArray<FlutterEngine*>*)searchFlutterEnginesWithScene:(UIScene*)scene;
- (void)connectEngineIfNeeded:(FlutterEngine*)engine scene:(UIScene*)scene;

- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
           flutterEngine:(FlutterEngine*)engine
                 options:(UISceneConnectionOptions*)connectionOptions;

+ (void)resetSceneWillConnectFallbackCalledForTesting;
+ (void)resetEnginesForSingleSceneForTesting;

@end

@interface FlutterAppDelegate (Test)
@property(nonatomic, strong) FlutterPluginAppLifeCycleDelegate* lifeCycleDelegate;
@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_TEST_H_
