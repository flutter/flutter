// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterAppDelegate.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

@implementation FlutterAppDelegate {
  FlutterPluginAppLifeCycleDelegate* _lifeCycleDelegate;
}

- (instancetype)init {
  if (self = [super init]) {
    _lifeCycleDelegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  }
  return self;
}

- (void)dealloc {
  [_lifeCycleDelegate release];
  [super dealloc];
}

- (BOOL)application:(UIApplication*)application
    willFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  return [_lifeCycleDelegate application:application willFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  return [_lifeCycleDelegate application:application didFinishLaunchingWithOptions:launchOptions];
}

// Returns the key window's rootViewController, if it's a FlutterViewController.
// Otherwise, returns nil.
- (FlutterViewController*)rootFlutterViewController {
  UIViewController* viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
  if ([viewController isKindOfClass:[FlutterViewController class]]) {
    return (FlutterViewController*)viewController;
  }
  return nil;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  [super touchesBegan:touches withEvent:event];

  // Pass status bar taps to key window Flutter rootViewController.
  if (self.rootFlutterViewController != nil) {
    [self.rootFlutterViewController handleStatusBarTouches:event];
  }
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
  [_lifeCycleDelegate applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
  [_lifeCycleDelegate applicationWillEnterForeground:application];
}

- (void)applicationWillResignActive:(UIApplication*)application {
  [_lifeCycleDelegate applicationWillResignActive:application];
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
  [_lifeCycleDelegate applicationDidBecomeActive:application];
}

- (void)applicationWillTerminate:(UIApplication*)application {
  [_lifeCycleDelegate applicationWillTerminate:application];
}

- (void)application:(UIApplication*)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings*)notificationSettings {
  [_lifeCycleDelegate application:application
      didRegisterUserNotificationSettings:notificationSettings];
}

- (void)application:(UIApplication*)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
  [_lifeCycleDelegate application:application
      didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication*)application
    didReceiveRemoteNotification:(NSDictionary*)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
  [_lifeCycleDelegate application:application
      didReceiveRemoteNotification:userInfo
            fetchCompletionHandler:completionHandler];
}

- (BOOL)application:(UIApplication*)application
            openURL:(NSURL*)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options {
  return [_lifeCycleDelegate application:application openURL:url options:options];
}

- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url {
  return [_lifeCycleDelegate application:application handleOpenURL:url];
}

- (BOOL)application:(UIApplication*)application
              openURL:(NSURL*)url
    sourceApplication:(NSString*)sourceApplication
           annotation:(id)annotation {
  return [_lifeCycleDelegate application:application
                                 openURL:url
                       sourceApplication:sourceApplication
                              annotation:annotation];
}

- (void)application:(UIApplication*)application
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler NS_AVAILABLE_IOS(9_0) {
  [_lifeCycleDelegate application:application
      performActionForShortcutItem:shortcutItem
                 completionHandler:completionHandler];
}

- (void)application:(UIApplication*)application
    handleEventsForBackgroundURLSession:(nonnull NSString*)identifier
                      completionHandler:(nonnull void (^)())completionHandler {
  [_lifeCycleDelegate application:application
      handleEventsForBackgroundURLSession:identifier
                        completionHandler:completionHandler];
}

- (void)application:(UIApplication*)application
    performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
  [_lifeCycleDelegate application:application performFetchWithCompletionHandler:completionHandler];
}

- (BOOL)application:(UIApplication*)application
    continueUserActivity:(NSUserActivity*)userActivity
      restorationHandler:(void (^)(NSArray*))restorationHandler {
  return [_lifeCycleDelegate application:application
                    continueUserActivity:userActivity
                      restorationHandler:restorationHandler];
}

#pragma mark - FlutterPluginRegistry methods. All delegating to the rootViewController

- (NSObject<FlutterPluginRegistrar>*)registrarForPlugin:(NSString*)pluginKey {
  UIViewController* rootViewController = _window.rootViewController;
  if ([rootViewController isKindOfClass:[FlutterViewController class]]) {
    return
        [[(FlutterViewController*)rootViewController pluginRegistry] registrarForPlugin:pluginKey];
  }
  return nil;
}

- (BOOL)hasPlugin:(NSString*)pluginKey {
  UIViewController* rootViewController = _window.rootViewController;
  if ([rootViewController isKindOfClass:[FlutterViewController class]]) {
    return [[(FlutterViewController*)rootViewController pluginRegistry] hasPlugin:pluginKey];
  }
  return false;
}

- (NSObject*)valuePublishedByPlugin:(NSString*)pluginKey {
  UIViewController* rootViewController = _window.rootViewController;
  if ([rootViewController isKindOfClass:[FlutterViewController class]]) {
    return [[(FlutterViewController*)rootViewController pluginRegistry]
        valuePublishedByPlugin:pluginKey];
  }
  return nil;
}

#pragma mark - FlutterAppLifeCycleProvider methods

- (void)addApplicationLifeCycleDelegate:(NSObject<FlutterPlugin>*)delegate {
  [_lifeCycleDelegate addDelegate:delegate];
}

@end
