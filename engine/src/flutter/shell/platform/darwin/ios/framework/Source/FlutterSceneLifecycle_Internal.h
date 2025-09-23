// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_INTERNAL_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterSceneLifecycle.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

/**
 * Forwards `UIWindowSceneDelegate` callbacks to the `FlutterEngine`'s
 * `FlutterPluginSceneLifeCycleDelegate` to then be forwarded to registered plugins.
 */
@interface FlutterPluginSceneLifeCycleDelegate ()

- (void)addFlutterEngine:(FlutterEngine*)engine scene:(UIScene*)scene;

- (void)removeFlutterEngine:(FlutterEngine*)engine;

@end

/**
 * Forwards callbacks to registered plugins.
 */
@interface FlutterEnginePluginSceneLifeCycleDelegate : NSObject

- (void)addDelegate:(NSObject<FlutterSceneLifeCycleDelegate>*)delegate;

#pragma mark - Connecting and disconnecting the scene

- (void)flutterViewDidConnectTo:(UIScene*)scene
                        options:(UISceneConnectionOptions*)connectionOptions;

- (void)sceneDidDisconnect:(UIScene*)scene;

#pragma mark - Transitioning to the foreground

- (void)sceneWillEnterForeground:(UIScene*)scene;

- (void)sceneDidBecomeActive:(UIScene*)scene;

#pragma mark - Transitioning to the background

- (void)sceneWillResignActive:(UIScene*)scene;

- (void)sceneDidEnterBackground:(UIScene*)scene;

#pragma mark - Opening URLs

- (void)scene:(UIScene*)scene openURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts;

#pragma mark - Continuing user activities

- (void)scene:(UIScene*)scene continueUserActivity:(NSUserActivity*)userActivity;

#pragma mark - Performing tasks

- (void)windowScene:(UIWindowScene*)windowScene
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_INTERNAL_H_
