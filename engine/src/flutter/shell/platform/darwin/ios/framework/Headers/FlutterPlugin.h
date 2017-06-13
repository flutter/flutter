// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERPLUGIN_H_
#define FLUTTER_FLUTTERPLUGIN_H_

#import <UIKit/UIKit.h>

#include "FlutterBinaryMessenger.h"
#include "FlutterChannels.h"
#include "FlutterCodecs.h"

NS_ASSUME_NONNULL_BEGIN
@protocol FlutterPluginRegistrar;

/**
 Implemented by the iOS part of a Flutter plugin.

 Defines a set of optional callback methods and a method to set up the plugin
 and register it to be called by other application components.
 */
@protocol FlutterPlugin<NSObject>
@required
/**
 Registers this plugin.

 - Parameters:
   - registrar: A helper providing application context and methods for
     registering callbacks
 */
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
@optional
/**
 Called if this plugin has been registered to receive `FlutterMethodCall`s.

 - Parameters:
   - call: The method call command object.
   - result: A callback for submitting the result of the call.
 */
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.

 - Returns: `NO` if this plugin vetoes application launch.
 */
- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions;
/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.
 */
- (void)applicationDidBecomeActive:(UIApplication*)application;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.
 */
- (void)applicationWillResignActive:(UIApplication*)application;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.
 */
- (void)applicationDidEnterBackground:(UIApplication*)application;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.
 */
- (void)applicationWillEnterForeground:(UIApplication*)application;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.
 */
- (void)applicationWillTerminate:(UIApplication*)application;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.
 */
- (void)application:(UIApplication*)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings*)notificationSettings;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.
 */
- (void)application:(UIApplication*)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.

 - Returns: `YES` if this plugin handles the request.
 */
- (BOOL)application:(UIApplication*)application
    didReceiveRemoteNotification:(NSDictionary*)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.

  - Returns: `YES` if this plugin handles the request.
*/
- (BOOL)application:(UIApplication*)application
            openURL:(NSURL*)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.

 - Returns: `YES` if this plugin handles the request.
 */
- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.

  - Returns: `YES` if this plugin handles the request.
*/
- (BOOL)application:(UIApplication*)application
              openURL:(NSURL*)url
    sourceApplication:(NSString*)sourceApplication
           annotation:(id)annotation;

/**
 Called if this plugin has been registered for `UIApplicationDelegate` callbacks.

  - Returns: `YES` if this plugin handles the request.
*/
- (BOOL)application:(UIApplication*)application
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler;

@end

/**
 Registration context for a single `FlutterPlugin`.
 */
@protocol FlutterPluginRegistrar<NSObject>
/**
 Returns a `FlutterBinaryMessenger` for creating Dart/iOS communication
 channels to be used by the plugin.

 - Returns: The messenger.
 */
- (NSObject<FlutterBinaryMessenger>*)messenger;

/**
 Publishes a value for external use of the plugin.

 Plugins may publish a single value, such as an instance of the
 plugin's main class, for situations where external control or
 interaction is needed.

 The published value will be available from the `FlutterPluginRegistry`.
 Repeated calls overwrite any previous publication.

 - Parameter value: The value to be published.
 */
- (void)publish:(NSObject*)value;

/**
 Registers the plugin as a receiver of incoming method calls from the Dart side
 on the specified `FlutterMethodChannel`.

 - Parameters:
   - delegate: The receiving object, such as the plugin's main class.
   - channel: The channel
 */
- (void)addMethodCallDelegate:(NSObject<FlutterPlugin>*)delegate
                      channel:(FlutterMethodChannel*)channel;

/**
 Registers the plugin as a receiver of `UIApplicationDelegate` calls.

 - Parameters delegate: The receiving object, such as the plugin's main class.
 */
- (void)addApplicationDelegate:(NSObject<FlutterPlugin>*)delegate;
@end

/**
 A registry of Flutter iOS plugins.

 Plugins are identified by unique string keys, typically the name of the
 plugin's main class.
 */
@protocol FlutterPluginRegistry<NSObject>
/**
 Returns a registrar for registering a plugin.

 - Parameter pluginKey: The unique key identifying the plugin.
 */
- (NSObject<FlutterPluginRegistrar>*)registrarForPlugin:(NSString*)pluginKey;
/**
 Returns whether the specified plugin has been registered.

 - Parameter pluginKey: The unique key identifying the plugin.
 - Returns: `YES` if `registrarForPlugin` has been called with `pluginKey`.
 */
- (BOOL)hasPlugin:(NSString*)pluginKey;

/**
 Returns a value published by the specified plugin.

 - Parameter pluginKey: The unique key identifying the plugin.
 - Returns: An object published by the plugin, if any. Will be `NSNull` if
   nothing has been published. Will be `nil` if the plugin has not been
   registered.
 */
- (NSObject*)valuePublishedByPlugin:(NSString*)pluginKey;
@end

NS_ASSUME_NONNULL_END;

#endif  // FLUTTER_FLUTTERPLUGIN_H_
