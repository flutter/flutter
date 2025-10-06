// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLUGINAPPLIFECYCLEDELEGATE_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLUGINAPPLIFECYCLEDELEGATE_INTERNAL_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"

@interface FlutterPluginAppLifeCycleDelegate ()

/**
 * Check whether the selector should be handled dynamically.
 */
- (BOOL)isSelectorAddedDynamically:(SEL)selector;

/**
 * Check whether there is at least one plugin responds to the selector.
 */
- (BOOL)hasPluginThatRespondsToSelector:(SEL)selector;

/**
 * Forwards the `application:didFinishLaunchingWithOptions:` lifecycle event to plugins if they have
 * not received it yet. This compensates for the UIScene migration, which causes storyboards (and
 * thus the plugin registration via `FlutterImplicitEngineDelegate`) to be instantiated after the
 * application launch events.
 */
- (void)sceneFallbackDidFinishLaunchingApplication:(UIApplication*)application;

/**
 * Forwards the `application:willFinishLaunchingWithOptions:` lifecycle event to plugins if they
 * have not received it yet. This compensates for the UIScene migration, which causes storyboards
 * (and thus the plugin registration via `FlutterImplicitEngineDelegate`) to be instantiated after
 * the application launch events.
 */
- (void)sceneFallbackWillFinishLaunchingApplication:(UIApplication*)application;

/**
 * Forwards the application equivalent lifecycle event of
 * `scene:willConnectToSession:options:` -> `application:didFinishLaunchingWithOptions:` to plugins
 * that have not adopted the FlutterSceneLifeCycleDelegate protocol.
 */
- (BOOL)sceneWillConnectFallback:(UISceneConnectionOptions*)connectionOptions;

/**
 * Forwards the application equivalent lifecycle event of
 * `sceneWillEnterForeground:` -> `applicationWillEnterForeground:` to plugins that have not adopted
 * the FlutterSceneLifeCycleDelegate protocol.
 */
- (void)sceneWillEnterForegroundFallback;

/**
 * Forwards the application equivalent lifecycle event of
 * `sceneDidBecomeActive:` -> `applicationDidBecomeActive:` to plugins that have not adopted the
 * FlutterSceneLifeCycleDelegate protocol.
 */
- (void)sceneDidBecomeActiveFallback;

/**
 * Forwards the application equivalent lifecycle event of
 * `sceneWillResignActive:` -> `applicationWillResignActive:` to plugins that have not
 * adopted the FlutterSceneLifeCycleDelegate protocol.
 */
- (void)sceneWillResignActiveFallback;

/**
 * Forwards the application equivalent lifecycle event of
 * `sceneDidEnterBackground:` -> `applicationDidEnterBackground:` to plugins that have not adopted
 * the FlutterSceneLifeCycleDelegate protocol.
 */
- (void)sceneDidEnterBackgroundFallback;

/**
 * Forwards the application equivalent lifecycle event of
 * `scene:openURLContexts:` -> `application:openURL:options:completionHandler:` to plugins that have
 * not adopted the FlutterSceneLifeCycleDelegate protocol.
 */
- (BOOL)sceneFallbackOpenURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts;

/**
 * Forwards the application equivalent lifecycle event of
 * `scene:continueUserActivity:` -> `application:continueUserActivity:restorationHandler:` to
 * plugins that have not adopted the FlutterSceneLifeCycleDelegate protocol.
 */
- (BOOL)sceneFallbackContinueUserActivity:(NSUserActivity*)userActivity;

/**
 * Forwards the application equivalent lifecycle event of
 * `windowScene:performActionForShortcutItem:completionHandler:` ->
 * `application:performActionForShortcutItem:completionHandler:` to plugins that have not adopted
 * the FlutterSceneLifeCycleDelegate protocol.
 */
- (BOOL)sceneFallbackPerformActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
                                completionHandler:(void (^)(BOOL succeeded))completionHandler;

@end
;

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLUGINAPPLIFECYCLEDELEGATE_INTERNAL_H_
