// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENELIFECYCLE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENELIFECYCLE_H_

#import <UIKit/UIKit.h>
#import "FlutterMacros.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A protocol for delegates that handle `UISceneDelegate` and `UIWindowSceneDelegate` life-cycle
 * events.
 *
 * This protocol provides a way for Flutter plugins to observe and react to scene-based life-cycle
 * events. The methods in this protocol correspond to methods in `UISceneDelegate` and
 * `UIWindowSceneDelegate`.
 *
 * See also:
 *
 *  * `UISceneDelegate`, core methods you use to respond to life-cycle events occurring within a
 *    scene: https://developer.apple.com/documentation/uikit/uiscenedelegate
 *  * `UIWindowSceneDelegate`, additional methods that you use to manage app-specific tasks
 *    occurring in a scene: https://developer.apple.com/documentation/uikit/uiwindowscenedelegate
 */
API_AVAILABLE(ios(13.0))
@protocol FlutterSceneLifeCycleDelegate

@optional

#pragma mark - Connecting and disconnecting the scene

/**
 * A Flutter-specific equivalent of `-[UISceneDelegate scene:willConnectToSession:options:]`.
 *
 * This method is called when a `FlutterViewController`'s view is able to access the scene.
 *
 * @param scene The scene that is being connected.
 * @param connectionOptions The options that were passed to the scene.
 */
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
 * Forwards `UISceneDelegate` and `UIWindowSceneDelegate` callbacks to plugins that register for
 * them.
 *
 * This class is responsible for receiving `UISceneDelegate` and `UIWindowSceneDelegate` callbacks
 * and forwarding them to any plugins.
 */
FLUTTER_DARWIN_EXPORT
API_AVAILABLE(ios(13.0))
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
 * A protocol for `UIWindowSceneDelegate` objects that vend a `FlutterPluginSceneLifeCycleDelegate`.
 *
 * By conforming to this protocol, a `UIWindowSceneDelegate` can vend a
 * `FlutterPluginSceneLifeCycleDelegate` that can be used to forward scene life-cycle events to
 * Flutter plugins.
 *
 * This is typically implemented by the app's `SceneDelegate`.
 */
API_AVAILABLE(ios(13.0))
@protocol FlutterSceneLifeCycleProvider
@property(nonatomic, strong) FlutterPluginSceneLifeCycleDelegate* sceneLifeCycleDelegate;
@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENELIFECYCLE_H_
