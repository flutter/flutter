// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENELIFECYCLE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENELIFECYCLE_H_

#import <UIKit/UIKit.h>
#import "FlutterMacros.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for listener of events from the UIWindowSceneDelegate, typically a FlutterPlugin.
 */
@protocol FlutterSceneLifeCycleDelegate

@optional

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

/**
 * Forwards `UIWindowSceneDelegate` callbacks to the `FlutterEngine`'s
 * `FlutterPluginSceneLifeCycleDelegate` to then be forwarded to registered plugins.
 */
FLUTTER_DARWIN_EXPORT
@interface FlutterPluginSceneLifeCycleDelegate : NSObject

#pragma mark - Connecting and disconnecting the scene

- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
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

/**
 * Implement this in the `UIWindowSceneDelegate` of your app to enable Flutter plugins to register
 * themselves to the scene life cycle events.
 */
@protocol FlutterSceneLifeCycleProvider
@property(nonatomic, strong) FlutterPluginSceneLifeCycleDelegate* sceneLifeCycleDelegate;
@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENELIFECYCLE_H_
