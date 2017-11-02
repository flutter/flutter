// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterAppDelegate.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#include "lib/fxl/logging.h"

@interface FlutterAppDelegate ()
@property(readonly, nonatomic) NSMutableArray* pluginDelegates;
@property(readonly, nonatomic) NSMutableDictionary* pluginPublications;
@end

@interface FlutterAppDelegateRegistrar : NSObject<FlutterPluginRegistrar>
- (instancetype)initWithPlugin:(NSString*)pluginKey appDelegate:(FlutterAppDelegate*)delegate;
@end

@implementation FlutterAppDelegate {
  UIBackgroundTaskIdentifier _debugBackgroundTask;
}

- (instancetype)init {
  if (self = [super init]) {
    _pluginDelegates = [NSMutableArray new];
    _pluginPublications = [NSMutableDictionary new];
  }
  return self;
}

- (void)dealloc {
  [_pluginDelegates release];
  [_pluginPublications release];
  [super dealloc];
}

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if ([plugin respondsToSelector:_cmd]) {
      if (![plugin application:application didFinishLaunchingWithOptions:launchOptions]) {
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

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  [super touchesBegan:touches withEvent:event];

  // Pass status bar taps to key window Flutter rootViewController.
  if (self.rootFlutterViewController != nil) {
    [self.rootFlutterViewController handleStatusBarTouches:event];
  }
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
                  FXL_LOG(WARNING)
                      << "\nThe OS has terminated the Flutter debug connection for being "
                         "inactive in the background for too long.\n\n"
                         "There are no errors with your Flutter application.\n\n"
                         "To reconnect, launch your application again via 'flutter run'";
                }];
#endif  // FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
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
    if ([plugin respondsToSelector:_cmd]) {
      [plugin applicationWillEnterForeground:application];
    }
  }
}

- (void)applicationWillResignActive:(UIApplication*)application {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if ([plugin respondsToSelector:_cmd]) {
      [plugin applicationWillResignActive:application];
    }
  }
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if ([plugin respondsToSelector:_cmd]) {
      [plugin applicationDidBecomeActive:application];
    }
  }
}

- (void)applicationWillTerminate:(UIApplication*)application {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if ([plugin respondsToSelector:_cmd]) {
      [plugin applicationWillTerminate:application];
    }
  }
}

- (void)application:(UIApplication*)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings*)notificationSettings {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if ([plugin respondsToSelector:_cmd]) {
      [plugin application:application didRegisterUserNotificationSettings:notificationSettings];
    }
  }
}

- (void)application:(UIApplication*)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if ([plugin respondsToSelector:_cmd]) {
      [plugin application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
  }
}

- (void)application:(UIApplication*)application
    didReceiveRemoteNotification:(NSDictionary*)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
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
               completionHandler:(void (^)(BOOL succeeded))completionHandler {
  for (id<FlutterPlugin> plugin in _pluginDelegates) {
    if ([plugin respondsToSelector:_cmd]) {
      if ([plugin application:application
              performActionForShortcutItem:shortcutItem
                         completionHandler:completionHandler]) {
        return;
      }
    }
  }
}

// TODO(xster): move when doing https://github.com/flutter/flutter/issues/3671.
- (NSObject<FlutterBinaryMessenger>*)binaryMessenger {
  UIViewController* rootViewController = _window.rootViewController;
  if ([rootViewController conformsToProtocol:@protocol(FlutterBinaryMessenger)]) {
    return (NSObject<FlutterBinaryMessenger>*)rootViewController;
  }
  return nil;
}

- (NSObject<FlutterTextureRegistry>*)textures {
  UIViewController* rootViewController = _window.rootViewController;
  if ([rootViewController conformsToProtocol:@protocol(FlutterTextureRegistry)]) {
    return (NSObject<FlutterTextureRegistry>*)rootViewController;
  }
  return nil;
}

- (NSObject<FlutterPluginRegistrar>*)registrarForPlugin:(NSString*)pluginKey {
  NSAssert(self.pluginPublications[pluginKey] == nil, @"Duplicate plugin key: %@", pluginKey);
  self.pluginPublications[pluginKey] = [NSNull null];
  return
      [[[FlutterAppDelegateRegistrar alloc] initWithPlugin:pluginKey appDelegate:self] autorelease];
}

- (BOOL)hasPlugin:(NSString*)pluginKey {
  return _pluginPublications[pluginKey] != nil;
}

- (NSObject*)valuePublishedByPlugin:(NSString*)pluginKey {
  return _pluginPublications[pluginKey];
}
@end

@implementation FlutterAppDelegateRegistrar {
  NSString* _pluginKey;
  FlutterAppDelegate* _appDelegate;
}

- (instancetype)initWithPlugin:(NSString*)pluginKey appDelegate:(FlutterAppDelegate*)appDelegate {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _pluginKey = [pluginKey retain];
  _appDelegate = [appDelegate retain];
  return self;
}

- (void)dealloc {
  [_pluginKey release];
  [_appDelegate release];
  [super dealloc];
}

- (NSObject<FlutterBinaryMessenger>*)messenger {
  return [_appDelegate binaryMessenger];
}

- (NSObject<FlutterTextureRegistry>*)textures {
  return [_appDelegate textures];
}

- (void)publish:(NSObject*)value {
  _appDelegate.pluginPublications[_pluginKey] = value;
}

- (void)addMethodCallDelegate:(NSObject<FlutterPlugin>*)delegate
                      channel:(FlutterMethodChannel*)channel {
  [channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    [delegate handleMethodCall:call result:result];
  }];
}

- (void)addApplicationDelegate:(NSObject<FlutterPlugin>*)delegate {
  [_appDelegate.pluginDelegates addObject:delegate];
}
@end
