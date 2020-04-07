// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterAppDelegate.h"
#include "flutter/fml/logging.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterPluginAppLifeCycleDelegate_internal.h"

static NSString* kUIBackgroundMode = @"UIBackgroundModes";
static NSString* kRemoteNotificationCapabitiliy = @"remote-notification";
static NSString* kBackgroundFetchCapatibility = @"fetch";

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
+ (FlutterViewController*)rootFlutterViewController {
  UIViewController* viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
  if ([viewController isKindOfClass:[FlutterViewController class]]) {
    return (FlutterViewController*)viewController;
  }
  return nil;
}

// Do not remove, some clients may be calling these via `super`.
- (void)applicationDidEnterBackground:(UIApplication*)application {
}

// Do not remove, some clients may be calling these via `super`.
- (void)applicationWillEnterForeground:(UIApplication*)application {
}

// Do not remove, some clients may be calling these via `super`.
- (void)applicationWillResignActive:(UIApplication*)application {
}

// Do not remove, some clients may be calling these via `super`.
- (void)applicationDidBecomeActive:(UIApplication*)application {
}

// Do not remove, some clients may be calling these via `super`.
- (void)applicationWillTerminate:(UIApplication*)application {
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)application:(UIApplication*)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings*)notificationSettings {
  [_lifeCycleDelegate application:application
      didRegisterUserNotificationSettings:notificationSettings];
}
#pragma GCC diagnostic pop

- (void)application:(UIApplication*)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
  [_lifeCycleDelegate application:application
      didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)application:(UIApplication*)application
    didReceiveLocalNotification:(UILocalNotification*)notification {
  [_lifeCycleDelegate application:application didReceiveLocalNotification:notification];
}
#pragma GCC diagnostic pop

- (void)userNotificationCenter:(UNUserNotificationCenter*)center
       willPresentNotification:(UNNotification*)notification
         withCompletionHandler:
             (void (^)(UNNotificationPresentationOptions options))completionHandler
    NS_AVAILABLE_IOS(10_0) {
  if (@available(iOS 10.0, *)) {
    if ([_lifeCycleDelegate respondsToSelector:_cmd]) {
      [_lifeCycleDelegate userNotificationCenter:center
                         willPresentNotification:notification
                           withCompletionHandler:completionHandler];
    }
  }
}

/**
 * Calls all plugins registered for `UNUserNotificationCenterDelegate` callbacks.
 */
- (void)userNotificationCenter:(UNUserNotificationCenter*)center
    didReceiveNotificationResponse:(UNNotificationResponse*)response
             withCompletionHandler:(void (^)(void))completionHandler NS_AVAILABLE_IOS(10_0) {
  if (@available(iOS 10.0, *)) {
    if ([_lifeCycleDelegate respondsToSelector:_cmd]) {
      [_lifeCycleDelegate userNotificationCenter:center
                  didReceiveNotificationResponse:response
                           withCompletionHandler:completionHandler];
    }
  }
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

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000
- (BOOL)application:(UIApplication*)application
    continueUserActivity:(NSUserActivity*)userActivity
      restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>>* __nullable
                                       restorableObjects))restorationHandler {
#else
- (BOOL)application:(UIApplication*)application
    continueUserActivity:(NSUserActivity*)userActivity
      restorationHandler:(void (^)(NSArray* __nullable restorableObjects))restorationHandler {
#endif
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

#pragma mark - Selectors handling

- (void)addApplicationLifeCycleDelegate:(NSObject<FlutterApplicationLifeCycleDelegate>*)delegate {
  [_lifeCycleDelegate addDelegate:delegate];
}

#pragma mark - UIApplicationDelegate method dynamic implementation

- (BOOL)respondsToSelector:(SEL)selector {
  if ([_lifeCycleDelegate isSelectorAddedDynamically:selector]) {
    return [self delegateRespondsSelectorToPlugins:selector];
  }
  return [super respondsToSelector:selector];
}

- (BOOL)delegateRespondsSelectorToPlugins:(SEL)selector {
  if ([_lifeCycleDelegate hasPluginThatRespondsToSelector:selector]) {
    return [_lifeCycleDelegate respondsToSelector:selector];
  } else {
    return NO;
  }
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
  if ([_lifeCycleDelegate isSelectorAddedDynamically:aSelector]) {
    [self logCapabilityConfigurationWarningIfNeeded:aSelector];
    return _lifeCycleDelegate;
  }
  return [super forwardingTargetForSelector:aSelector];
}

// Mimic the logging from Apple when the capability is not set for the selectors.
// However the difference is that Apple logs these message when the app launches, we only
// log it when the method is invoked. We can possibly also log it when the app launches, but
// it will cause an additional scan over all the plugins.
- (void)logCapabilityConfigurationWarningIfNeeded:(SEL)selector {
  NSArray* backgroundModesArray =
      [[NSBundle mainBundle] objectForInfoDictionaryKey:kUIBackgroundMode];
  NSSet* backgroundModesSet = [[[NSSet alloc] initWithArray:backgroundModesArray] autorelease];
  if (selector == @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)) {
    if (![backgroundModesSet containsObject:kRemoteNotificationCapabitiliy]) {
      NSLog(
          @"You've implemented -[<UIApplicationDelegate> "
          @"application:didReceiveRemoteNotification:fetchCompletionHandler:], but you still need "
          @"to add \"remote-notification\" to the list of your supported UIBackgroundModes in your "
          @"Info.plist.");
    }
  } else if (selector == @selector(application:performFetchWithCompletionHandler:)) {
    if (![backgroundModesSet containsObject:kBackgroundFetchCapatibility]) {
      NSLog(@"You've implemented -[<UIApplicationDelegate> "
            @"application:performFetchWithCompletionHandler:], but you still need to add \"fetch\" "
            @"to the list of your supported UIBackgroundModes in your Info.plist.");
    }
  }
}

@end
