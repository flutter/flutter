// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/paths.h"
#include "flutter/lib/ui/plugins/callback_cache.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterCallbackCache_Internal.h"

static const char* kCallbackCacheSubDir = "Library/Caches/";

@implementation FlutterPluginAppLifeCycleDelegate {
  UIBackgroundTaskIdentifier _debugBackgroundTask;

  // Weak references to registered plugins.
  NSPointerArray* _pluginDelegates;
}

- (instancetype)init {
  if (self = [super init]) {
    std::string cachePath = fml::paths::JoinPaths({getenv("HOME"), kCallbackCacheSubDir});
    [FlutterCallbackCache setCachePath:[NSString stringWithUTF8String:cachePath.c_str()]];
    _pluginDelegates = [[NSPointerArray weakObjectsPointerArray] retain];
  }
  return self;
}

- (void)dealloc {
  [_pluginDelegates release];
  [super dealloc];
}

static BOOL isPowerOfTwo(NSUInteger x) {
  return x != 0 && (x & (x - 1)) == 0;
}

- (void)addDelegate:(NSObject<FlutterPlugin>*)delegate {
  [_pluginDelegates addPointer:(__bridge void*)delegate];
  if (isPowerOfTwo([_pluginDelegates count])) {
    [_pluginDelegates compact];
  }
}

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  for (id<FlutterPlugin> plugin in [_pluginDelegates allObjects]) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      if (![plugin application:application didFinishLaunchingWithOptions:launchOptions]) {
        return NO;
      }
    }
  }
  return YES;
}

- (BOOL)application:(UIApplication*)application
    willFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  blink::DartCallbackCache::LoadCacheFromDisk();
  for (id<FlutterPlugin> plugin in [_pluginDelegates allObjects]) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      if (![plugin application:application willFinishLaunchingWithOptions:launchOptions]) {
        return NO;
      }
    }
  }
  return YES;
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

- (void)applicationDidEnterBackground:(UIApplication*)application {
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  // The following keeps the Flutter session alive when the device screen locks
  // in debug mode. It allows continued use of features like hot reload and
  // taking screenshots once the device unlocks again.
  //
  // Note the name is not an identifier and multiple instances can exist.
  _debugBackgroundTask = [application
      beginBackgroundTaskWithName:@"Flutter debug task"
                expirationHandler:^{
                  FML_LOG(WARNING)
                      << "\nThe OS has terminated the Flutter debug connection for being "
                         "inactive in the background for too long.\n\n"
                         "There are no errors with your Flutter application.\n\n"
                         "To reconnect, launch your application again via 'flutter run'";
                }];
#endif  // FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      [plugin applicationDidEnterBackground:application];
    }
  }
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  [application endBackgroundTask:_debugBackgroundTask];
#endif  // FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      [plugin applicationWillEnterForeground:application];
    }
  }
}

- (void)applicationWillResignActive:(UIApplication*)application {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      [plugin applicationWillResignActive:application];
    }
  }
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      [plugin applicationDidBecomeActive:application];
    }
  }
}

- (void)applicationWillTerminate:(UIApplication*)application {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      [plugin applicationWillTerminate:application];
    }
  }
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)application:(UIApplication*)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings*)notificationSettings {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      [plugin application:application didRegisterUserNotificationSettings:notificationSettings];
    }
  }
}
#pragma GCC diagnostic pop

- (void)application:(UIApplication*)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      [plugin application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
  }
}

- (void)application:(UIApplication*)application
    didReceiveRemoteNotification:(NSDictionary*)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      if ([plugin application:application
              didReceiveRemoteNotification:userInfo
                    fetchCompletionHandler:completionHandler]) {
        return;
      }
    }
  }
}

- (BOOL)application:(UIApplication*)application
            openURL:(NSURL*)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      if ([plugin application:application openURL:url options:options]) {
        return YES;
      }
    }
  }
  return NO;
}

- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      if ([plugin application:application handleOpenURL:url]) {
        return YES;
      }
    }
  }
  return NO;
}

- (BOOL)application:(UIApplication*)application
              openURL:(NSURL*)url
    sourceApplication:(NSString*)sourceApplication
           annotation:(id)annotation {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      if ([plugin application:application
                        openURL:url
              sourceApplication:sourceApplication
                     annotation:annotation]) {
        return YES;
      }
    }
  }
  return NO;
}

- (void)application:(UIApplication*)application
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler NS_AVAILABLE_IOS(9_0) {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      if ([plugin application:application
              performActionForShortcutItem:shortcutItem
                         completionHandler:completionHandler]) {
        return;
      }
    }
  }
}

- (BOOL)application:(UIApplication*)application
    handleEventsForBackgroundURLSession:(nonnull NSString*)identifier
                      completionHandler:(nonnull void (^)())completionHandler {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      if ([plugin application:application
              handleEventsForBackgroundURLSession:identifier
                                completionHandler:completionHandler]) {
        return YES;
      }
    }
  }
  return NO;
}

- (BOOL)application:(UIApplication*)application
    performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      if ([plugin application:application performFetchWithCompletionHandler:completionHandler]) {
        return YES;
      }
    }
  }
  return NO;
}

- (BOOL)application:(UIApplication*)application
    continueUserActivity:(NSUserActivity*)userActivity
      restorationHandler:(void (^)(NSArray*))restorationHandler {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if (!plugin) {
      continue;
    }
    if ([plugin respondsToSelector:_cmd]) {
      if ([plugin application:application
              continueUserActivity:userActivity
                restorationHandler:restorationHandler]) {
        return YES;
      }
    }
  }
  return NO;
}
@end
