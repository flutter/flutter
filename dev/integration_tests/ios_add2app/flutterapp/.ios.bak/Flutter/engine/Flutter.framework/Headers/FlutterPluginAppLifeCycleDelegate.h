// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERPLUGINAPPLIFECYCLEDELEGATE_H_
#define FLUTTER_FLUTTERPLUGINAPPLIFECYCLEDELEGATE_H_

#include "FlutterPlugin.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Propagates `UIAppDelegate` callbacks to registered plugins.
 */
FLUTTER_EXPORT
@interface FlutterPluginAppLifeCycleDelegate : NSObject
/**
 * Registers `delegate` to receive life cycle callbacks via this FlutterPluginAppLifecycleDelegate
 * as long as it is alive.
 *
 * `delegate` will only referenced weakly.
 */
- (void)addDelegate:(NSObject<FlutterPlugin>*)delegate;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks.
 *
 * @return `NO` if any plugin vetoes application launch.
 */
- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks.
 *
 * @return `NO` if any plugin vetoes application launch.
 */
- (BOOL)application:(UIApplication*)application
    willFinishLaunchingWithOptions:(NSDictionary*)launchOptions;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks.
 */
- (void)applicationDidBecomeActive:(UIApplication*)application;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks.
 */
- (void)applicationWillResignActive:(UIApplication*)application;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks.
 */
- (void)applicationDidEnterBackground:(UIApplication*)application;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks.
 */
- (void)applicationWillEnterForeground:(UIApplication*)application;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks.
 */
- (void)applicationWillTerminate:(UIApplication*)application;

/**
 * Called if this plugin has been registered for `UIApplicationDelegate` callbacks.
 */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)application:(UIApplication*)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings*)notificationSettings;
#pragma GCC diagnostic pop

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks.
 */
- (void)application:(UIApplication*)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks.
 */
- (void)application:(UIApplication*)application
    didReceiveRemoteNotification:(NSDictionary*)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks.
 */
- (void)application:(UIApplication*)application
    didReceiveLocalNotification:(UILocalNotification*)notification;

/**
 * Calls all plugins registered for `UNUserNotificationCenterDelegate` callbacks.
 */
- (void)userNotificationCenter:(UNUserNotificationCenter*)center
       willPresentNotification:(UNNotification*)notification
         withCompletionHandler:
             (void (^)(UNNotificationPresentationOptions options))completionHandler
    API_AVAILABLE(ios(10));

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks in order of registration until
 * some plugin handles the request.
 *
 *  @return `YES` if any plugin handles the request.
 */
- (BOOL)application:(UIApplication*)application
            openURL:(NSURL*)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks in order of registration until
 * some plugin handles the request.
 *
 * @return `YES` if any plugin handles the request.
 */
- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks in order of registration until
 * some plugin handles the request.
 *
 * @return `YES` if any plugin handles the request.
 */
- (BOOL)application:(UIApplication*)application
              openURL:(NSURL*)url
    sourceApplication:(NSString*)sourceApplication
           annotation:(id)annotation;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks.
 */
- (void)application:(UIApplication*)application
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler
    API_AVAILABLE(ios(9.0));

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks in order of registration until
 * some plugin handles the request.
 *
 * @return `YES` if any plugin handles the request.
 */
- (BOOL)application:(UIApplication*)application
    handleEventsForBackgroundURLSession:(nonnull NSString*)identifier
                      completionHandler:(nonnull void (^)(void))completionHandler;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks in order of registration until
 * some plugin handles the request.
 *
 * @returns `YES` if any plugin handles the request.
 */
- (BOOL)application:(UIApplication*)application
    performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;

/**
 * Calls all plugins registered for `UIApplicationDelegate` callbacks in order of registration until
 * some plugin handles the request.
 *
 * @return `YES` if any plugin handles the request.
 */
- (BOOL)application:(UIApplication*)application
    continueUserActivity:(NSUserActivity*)userActivity
      restorationHandler:(void (^)(NSArray*))restorationHandler;
@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_FLUTTERPLUGINAPPLIFECYCLEDELEGATE_H_
