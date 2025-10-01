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
@protocol FlutterSceneLifeCycleDelegate <NSObject>

@optional

#pragma mark - Connecting and disconnecting the scene

/**
 * Informs the delegate that a new scene is about to be connected and configured.
 *
 * This corresponds to `-[UISceneDelegate scene:willConnectToSession:options:]`. `connectionOptions`
 * may be nil if another plugin has already handled the connection.
 *
 * @return `YES` if this handled the connection.
 */
- (BOOL)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
                 options:(nullable UISceneConnectionOptions*)connectionOptions;

- (void)sceneDidDisconnect:(UIScene*)scene;

#pragma mark - Transitioning to the foreground

- (void)sceneWillEnterForeground:(UIScene*)scene;

- (void)sceneDidBecomeActive:(UIScene*)scene;

#pragma mark - Transitioning to the background

- (void)sceneWillResignActive:(UIScene*)scene;

- (void)sceneDidEnterBackground:(UIScene*)scene;

#pragma mark - Opening URLs

/**
 * Asks the delegate to open one or more URLs.
 *
 * This corresponds to `-[UISceneDelegate scene:openURLContexts:]`.
 *
 * @return `YES` if this handled one or more of the URLs.
 */
- (BOOL)scene:(UIScene*)scene openURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts;

#pragma mark - Continuing user activities

/**
 * Tells the delegate that the scene is continuing a user activity.
 *
 * This corresponds to `-[UISceneDelegate scene:continueUserActivity:]`.
 *
 * @return `YES` if this handled the activity.
 */
- (BOOL)scene:(UIScene*)scene continueUserActivity:(NSUserActivity*)userActivity;

#pragma mark - Performing tasks

/**
 * Tells the delegate that the user has selected a home screen quick action.
 *
 * This corresponds to `-[UIWindowSceneDelegate
 * windowScene:performActionForShortcutItem:completionHandler:]`.
 *
 * @return `YES` if this handled the shortcut.
 */
- (BOOL)windowScene:(UIWindowScene*)windowScene
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

/**
 * Calls all plugins registered for `UIWindowScene` callbacks in order of registration until
 * a plugin handles the request.
 *
 * @return `YES` if any plugin handles the request.
 */
- (BOOL)scene:(UIScene*)scene
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

/**
 * Calls all plugins registered for `UIWindowScene` callbacks in order of registration until
 * a plugin handles the request.
 *
 * @return `YES` if any plugin handles the request.
 */
- (BOOL)scene:(UIScene*)scene openURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts;

#pragma mark - Continuing user activities

/**
 * Calls all plugins registered for `UIWindowScene` callbacks in order of registration until
 * a plugin handles the request.
 *
 * @return `YES` if any plugin handles the request.
 */
- (BOOL)scene:(UIScene*)scene continueUserActivity:(NSUserActivity*)userActivity;

#pragma mark - Performing tasks

/**
 * Calls all plugins registered for `UIWindowScene` callbacks in order of registration until
 * a plugin handles the request.
 *
 * @return `YES` if any plugin handles the request.
 */
- (BOOL)windowScene:(UIWindowScene*)windowScene
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
