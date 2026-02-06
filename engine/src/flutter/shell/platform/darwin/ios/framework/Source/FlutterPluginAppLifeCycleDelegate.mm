// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"

#include "flutter/fml/paths.h"
#include "flutter/lib/ui/plugins/callback_cache.h"
#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterCallbackCache_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifeCycle_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSharedApplication.h"

FLUTTER_ASSERT_ARC

static const char* kCallbackCacheSubDir = "Library/Caches/";

static const SEL kSelectorsHandledByPlugins[] = {
    @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:),
    @selector(application:performFetchWithCompletionHandler:)};

@interface FlutterPluginAppLifeCycleDelegate ()
- (void)handleDidEnterBackground:(NSNotification*)notification
    NS_EXTENSION_UNAVAILABLE_IOS("Disallowed in app extensions");
- (void)handleWillEnterForeground:(NSNotification*)notification
    NS_EXTENSION_UNAVAILABLE_IOS("Disallowed in app extensions");
- (void)handleWillResignActive:(NSNotification*)notification
    NS_EXTENSION_UNAVAILABLE_IOS("Disallowed in app extensions");
- (void)handleDidBecomeActive:(NSNotification*)notification
    NS_EXTENSION_UNAVAILABLE_IOS("Disallowed in app extensions");
- (void)handleWillTerminate:(NSNotification*)notification
    NS_EXTENSION_UNAVAILABLE_IOS("Disallowed in app extensions");

@property(nonatomic, assign) BOOL didForwardApplicationWillLaunch;
@property(nonatomic, assign) BOOL didForwardApplicationDidLaunch;
@end

@implementation FlutterPluginAppLifeCycleDelegate {
  UIBackgroundTaskIdentifier _debugBackgroundTask;

  // Weak references to registered plugins.
  NSPointerArray* _delegates;
}

- (void)addObserverFor:(NSString*)name selector:(SEL)selector {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:selector name:name object:nil];
}

- (instancetype)init {
  if (self = [super init]) {
    std::string cachePath = fml::paths::JoinPaths({getenv("HOME"), kCallbackCacheSubDir});
    [FlutterCallbackCache setCachePath:[NSString stringWithUTF8String:cachePath.c_str()]];
    if (FlutterSharedApplication.isAvailable) {
      [self addObserverFor:UIApplicationDidEnterBackgroundNotification
                  selector:@selector(handleDidEnterBackground:)];
      [self addObserverFor:UIApplicationWillEnterForegroundNotification
                  selector:@selector(handleWillEnterForeground:)];
      [self addObserverFor:UIApplicationWillResignActiveNotification
                  selector:@selector(handleWillResignActive:)];
      [self addObserverFor:UIApplicationDidBecomeActiveNotification
                  selector:@selector(handleDidBecomeActive:)];
      [self addObserverFor:UIApplicationWillTerminateNotification
                  selector:@selector(handleWillTerminate:)];
    }
    _delegates = [NSPointerArray weakObjectsPointerArray];
    _debugBackgroundTask = UIBackgroundTaskInvalid;
  }
  return self;
}

static BOOL IsPowerOfTwo(NSUInteger x) {
  return x != 0 && (x & (x - 1)) == 0;
}

- (BOOL)isSelectorAddedDynamically:(SEL)selector {
  for (const SEL& aSelector : kSelectorsHandledByPlugins) {
    if (selector == aSelector) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)hasPluginThatRespondsToSelector:(SEL)selector {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in [_delegates allObjects]) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:selector]) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)appSupportsSceneLifecycle {
  // When UIScene lifecycle is being used, some application lifecycle events are not call by UIKit.
  // However, the notifications are still sent. When a Flutter app has been migrated to UIScene,
  // Flutter should not use the notifications to forward application events to plugins since they
  // are not expected to be called.
  // See https://flutter.dev/go/ios-ui-scene-lifecycle-migration?tab=t.0#heading=h.eq8gyd4ds50u
  return FlutterSharedApplication.hasSceneDelegate;
}

- (BOOL)pluginSupportsSceneLifecycle:(NSObject<FlutterApplicationLifeCycleDelegate>*)delegate {
  // The fallback is unnecessary if the plugin conforms to FlutterSceneLifeCycleDelegate.
  // This means that the plugin has migrated to scene lifecycle events and shouldn't require
  // application events. However, the plugin may still have the application event implemented to
  // maintain compatibility with un-migrated apps, which is why the fallback should be checked
  // before checking that the delegate responds to the selector.
  return [delegate conformsToProtocol:@protocol(FlutterSceneLifeCycleDelegate)];
}

- (void)addDelegate:(NSObject<FlutterApplicationLifeCycleDelegate>*)delegate {
  [_delegates addPointer:(__bridge void*)delegate];
  if (IsPowerOfTwo([_delegates count])) {
    [_delegates compact];
  }
}

- (void)sceneFallbackDidFinishLaunchingApplication:(UIApplication*)application {
  // If the application:didFinishingLaunchingWithOptions: event has already been sent to plugins, do
  // not send again.
  if (self.didForwardApplicationDidLaunch) {
    return;
  }
  // Send nil launchOptions since UIKit sends nil when UIScene is enabled.
  [self application:application didFinishLaunchingWithOptions:@{}];
}

- (void)sceneFallbackWillFinishLaunchingApplication:(UIApplication*)application {
  // If the application:willFinishLaunchingWithOptions: event has already been sent to plugins, do
  // not send again.
  if (self.didForwardApplicationWillLaunch) {
    return;
  }
  // If the application:didFinishingLaunchingWithOptions: event has already been sent to plugins, do
  // not send willFinishLaunchingWithOptions since it should happen before, not after.
  if (self.didForwardApplicationDidLaunch) {
    return;
  }
  // Send nil launchOptions since UIKit sends nil when UIScene is enabled.
  [self application:application willFinishLaunchingWithOptions:@{}];
}

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  if (_delegates.count > 0) {
    self.didForwardApplicationDidLaunch = YES;
  }
  return [self application:application
      didFinishLaunchingWithOptions:launchOptions
                 isFallbackForScene:NO];
}

- (BOOL)sceneWillConnectFallback:(UISceneConnectionOptions*)connectionOptions {
  UIApplication* application = FlutterSharedApplication.application;
  if (!application) {
    return NO;
  }
  NSDictionary<UIApplicationLaunchOptionsKey, id>* convertedLaunchOptions =
      ConvertConnectionOptions(connectionOptions);
  if (convertedLaunchOptions.count == 0) {
    // Only use fallback if there are meaningful launch options.
    return NO;
  }
  if (![self application:application
          didFinishLaunchingWithOptions:convertedLaunchOptions
                     isFallbackForScene:YES]) {
    return YES;
  }
  return NO;
}

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
               isFallbackForScene:(BOOL)isFallback {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate || (isFallback && [self pluginSupportsSceneLifecycle:delegate])) {
      continue;
    }
    if ([delegate respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
      if (![delegate application:application didFinishLaunchingWithOptions:launchOptions]) {
        return NO;
      }
    }
  }
  return YES;
}

/* Makes a best attempt to convert UISceneConnectionOptions from the scene event
 * (`scene:willConnectToSession:options:`) to a NSDictionary of options used to the application
 * lifecycle event.
 *
 * For more information on UISceneConnectionOptions, see
 * https://developer.apple.com/documentation/uikit/uiscene/connectionoptions.
 *
 * For information about the possible keys in the NSDictionary and how to handle them, see
 * https://developer.apple.com/documentation/uikit/uiapplication/launchoptionskey
 */
static NSDictionary<UIApplicationLaunchOptionsKey, id>* ConvertConnectionOptions(
    UISceneConnectionOptions* connectionOptions) {
  NSMutableDictionary<UIApplicationLaunchOptionsKey, id>* convertedOptions =
      [NSMutableDictionary dictionary];

  if (connectionOptions.shortcutItem) {
    convertedOptions[UIApplicationLaunchOptionsShortcutItemKey] = connectionOptions.shortcutItem;
  }
  if (connectionOptions.sourceApplication) {
    convertedOptions[UIApplicationLaunchOptionsSourceApplicationKey] =
        connectionOptions.sourceApplication;
  }
  if (connectionOptions.URLContexts.anyObject.URL) {
    convertedOptions[UIApplicationLaunchOptionsURLKey] =
        connectionOptions.URLContexts.anyObject.URL;
  }
  return convertedOptions;
}

- (BOOL)application:(UIApplication*)application
    willFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  if (_delegates.count > 0) {
    self.didForwardApplicationWillLaunch = YES;
  }
  flutter::DartCallbackCache::LoadCacheFromDisk();
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in [_delegates allObjects]) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:_cmd]) {
      if (![delegate application:application willFinishLaunchingWithOptions:launchOptions]) {
        return NO;
      }
    }
  }
  return YES;
}

- (void)handleDidEnterBackground:(NSNotification*)notification
    NS_EXTENSION_UNAVAILABLE_IOS("Disallowed in app extensions") {
  if ([self appSupportsSceneLifecycle]) {
    return;
  }
  UIApplication* application = [UIApplication sharedApplication];
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  // The following keeps the Flutter session alive when the device screen locks
  // in debug mode. It allows continued use of features like hot reload and
  // taking screenshots once the device unlocks again.
  //
  // Note the name is not an identifier and multiple instances can exist.
  _debugBackgroundTask = [application
      beginBackgroundTaskWithName:@"Flutter debug task"
                expirationHandler:^{
                  if (_debugBackgroundTask != UIBackgroundTaskInvalid) {
                    [application endBackgroundTask:_debugBackgroundTask];
                    _debugBackgroundTask = UIBackgroundTaskInvalid;
                  }
                  [FlutterLogger
                      logWarning:@"\nThe OS has terminated the Flutter debug connection for being "
                                  "inactive in the background for too long.\n\n"
                                  "There are no errors with your Flutter application.\n\n"
                                  "To reconnect, launch your application again via 'flutter run'"];
                }];
#endif  // FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  [self applicationDidEnterBackground:application isFallbackForScene:NO];
}

- (void)sceneDidEnterBackgroundFallback {
  UIApplication* application = FlutterSharedApplication.application;
  if (!application) {
    return;
  }
  [self applicationDidEnterBackground:application isFallbackForScene:YES];
}

- (void)applicationDidEnterBackground:(UIApplication*)application
                   isFallbackForScene:(BOOL)isFallback {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate || (isFallback && [self pluginSupportsSceneLifecycle:delegate])) {
      continue;
    }
    if ([delegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
      [delegate applicationDidEnterBackground:application];
    }
  }
}

- (void)handleWillEnterForeground:(NSNotification*)notification
    NS_EXTENSION_UNAVAILABLE_IOS("Disallowed in app extensions") {
  if ([self appSupportsSceneLifecycle]) {
    return;
  }
  UIApplication* application = [UIApplication sharedApplication];
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  if (_debugBackgroundTask != UIBackgroundTaskInvalid) {
    [application endBackgroundTask:_debugBackgroundTask];
    _debugBackgroundTask = UIBackgroundTaskInvalid;
  }
#endif  // FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  [self applicationWillEnterForeground:application isFallbackForScene:NO];
}

- (void)sceneWillEnterForegroundFallback {
  UIApplication* application = FlutterSharedApplication.application;
  if (!application) {
    return;
  }
  [self applicationWillEnterForeground:application isFallbackForScene:YES];
}

- (void)applicationWillEnterForeground:(UIApplication*)application
                    isFallbackForScene:(BOOL)isFallback {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate || (isFallback && [self pluginSupportsSceneLifecycle:delegate])) {
      continue;
    }
    if ([delegate respondsToSelector:@selector(applicationWillEnterForeground:)]) {
      [delegate applicationWillEnterForeground:application];
    }
  }
}

- (void)handleWillResignActive:(NSNotification*)notification
    NS_EXTENSION_UNAVAILABLE_IOS("Disallowed in app extensions") {
  if ([self appSupportsSceneLifecycle]) {
    return;
  }
  UIApplication* application = [UIApplication sharedApplication];
  [self applicationWillResignActive:application isFallbackForScene:NO];
}

- (void)sceneWillResignActiveFallback {
  UIApplication* application = FlutterSharedApplication.application;
  if (!application) {
    return;
  }
  [self applicationWillResignActive:application isFallbackForScene:YES];
}

- (void)applicationWillResignActive:(UIApplication*)application
                 isFallbackForScene:(BOOL)isFallback {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate || (isFallback && [self pluginSupportsSceneLifecycle:delegate])) {
      continue;
    }
    if ([delegate respondsToSelector:@selector(applicationWillResignActive:)]) {
      [delegate applicationWillResignActive:application];
    }
  }
}

- (void)handleDidBecomeActive:(NSNotification*)notification
    NS_EXTENSION_UNAVAILABLE_IOS("Disallowed in app extensions") {
  if ([self appSupportsSceneLifecycle]) {
    return;
  }
  UIApplication* application = [UIApplication sharedApplication];
  [self applicationDidBecomeActive:application isFallbackForScene:NO];
}

- (void)sceneDidBecomeActiveFallback {
  UIApplication* application = FlutterSharedApplication.application;
  if (!application) {
    return;
  }
  [self applicationDidBecomeActive:application isFallbackForScene:YES];
}

- (void)applicationDidBecomeActive:(UIApplication*)application isFallbackForScene:(BOOL)isFallback {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate || (isFallback && [self pluginSupportsSceneLifecycle:delegate])) {
      continue;
    }
    if ([delegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
      [delegate applicationDidBecomeActive:application];
    }
  }
}

- (void)handleWillTerminate:(NSNotification*)notification
    NS_EXTENSION_UNAVAILABLE_IOS("Disallowed in app extensions") {
  UIApplication* application = [UIApplication sharedApplication];
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:@selector(applicationWillTerminate:)]) {
      [delegate applicationWillTerminate:application];
    }
  }
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)application:(UIApplication*)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings*)notificationSettings {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:_cmd]) {
      [delegate application:application didRegisterUserNotificationSettings:notificationSettings];
    }
  }
}
#pragma GCC diagnostic pop

- (void)application:(UIApplication*)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:_cmd]) {
      [delegate application:application
          didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
  }
}

- (void)application:(UIApplication*)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:_cmd]) {
      [delegate application:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
  }
}

- (void)application:(UIApplication*)application
    didReceiveRemoteNotification:(NSDictionary*)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:_cmd]) {
      if ([delegate application:application
              didReceiveRemoteNotification:userInfo
                    fetchCompletionHandler:completionHandler]) {
        return;
      }
    }
  }
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)application:(UIApplication*)application
    didReceiveLocalNotification:(UILocalNotification*)notification {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:_cmd]) {
      [delegate application:application didReceiveLocalNotification:notification];
    }
  }
}
#pragma GCC diagnostic pop

- (void)userNotificationCenter:(UNUserNotificationCenter*)center
       willPresentNotification:(UNNotification*)notification
         withCompletionHandler:
             (void (^)(UNNotificationPresentationOptions options))completionHandler {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if ([delegate respondsToSelector:_cmd]) {
      [delegate userNotificationCenter:center
               willPresentNotification:notification
                 withCompletionHandler:completionHandler];
    }
  }
}

- (void)userNotificationCenter:(UNUserNotificationCenter*)center
    didReceiveNotificationResponse:(UNNotificationResponse*)response
             withCompletionHandler:(void (^)(void))completionHandler {
  for (id<FlutterApplicationLifeCycleDelegate> delegate in _delegates) {
    if ([delegate respondsToSelector:_cmd]) {
      [delegate userNotificationCenter:center
          didReceiveNotificationResponse:response
                   withCompletionHandler:completionHandler];
    }
  }
}

- (BOOL)application:(UIApplication*)application
            openURL:(NSURL*)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options {
  return [self application:application openURL:url options:options isFallbackForScene:NO];
}

- (BOOL)sceneFallbackOpenURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts {
  for (UIOpenURLContext* context in URLContexts) {
    if ([self application:FlutterSharedApplication.application
                       openURL:context.URL
                       options:ConvertOptions(context.options)
            isFallbackForScene:YES]) {
      return YES;
    };
  };
  return NO;
}

- (BOOL)application:(UIApplication*)application
               openURL:(NSURL*)url
               options:(NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options
    isFallbackForScene:(BOOL)isFallback {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate || (isFallback && [self pluginSupportsSceneLifecycle:delegate])) {
      continue;
    }
    if ([delegate respondsToSelector:@selector(application:openURL:options:)]) {
      if ([delegate application:application openURL:url options:options]) {
        return YES;
      }
    }
  }
  return NO;
}

/* Converts UISceneOpenURLOptions from the scene event (`sceneFallbackOpenURLContexts`) to a
 * NSDictionary of options used to the application lifecycle event.
 *
 * For more information on UISceneOpenURLOptions, see
 * https://developer.apple.com/documentation/uikit/uiopenurlcontext/options.
 *
 * For information about the possible keys in the NSDictionary and how to handle them, see
 * https://developer.apple.com/documentation/uikit/uiapplication/openurloptionskey
 */
static NSDictionary<UIApplicationOpenURLOptionsKey, id>* ConvertOptions(
    UISceneOpenURLOptions* options) {
  NSMutableDictionary<UIApplicationOpenURLOptionsKey, id>* convertedOptions =
      [NSMutableDictionary dictionary];
  if (options.sourceApplication) {
    convertedOptions[UIApplicationOpenURLOptionsSourceApplicationKey] = options.sourceApplication;
  }
  if (options.annotation) {
    convertedOptions[UIApplicationOpenURLOptionsAnnotationKey] = options.annotation;
  }
  convertedOptions[UIApplicationOpenURLOptionsOpenInPlaceKey] = @(options.openInPlace);
  if (@available(iOS 14.5, *)) {
    if (options.eventAttribution) {
      convertedOptions[UIApplicationOpenURLOptionsEventAttributionKey] = options.eventAttribution;
    }
  }
  return convertedOptions;
}

- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:_cmd]) {
      if ([delegate application:application handleOpenURL:url]) {
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
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:_cmd]) {
      if ([delegate application:application
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
  [self application:application
      performActionForShortcutItem:shortcutItem
                 completionHandler:completionHandler
                isFallbackForScene:NO];
}

- (BOOL)sceneFallbackPerformActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
                                completionHandler:(void (^)(BOOL succeeded))completionHandler {
  UIApplication* application = FlutterSharedApplication.application;
  if (!application) {
    return NO;
  }
  return [self application:application
      performActionForShortcutItem:shortcutItem
                 completionHandler:completionHandler
                isFallbackForScene:YES];
}

- (BOOL)application:(UIApplication*)application
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler
              isFallbackForScene:(BOOL)isFallback {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate || (isFallback && [self pluginSupportsSceneLifecycle:delegate])) {
      continue;
    }
    if ([delegate respondsToSelector:@selector(application:
                                         performActionForShortcutItem:completionHandler:)]) {
      if ([delegate application:application
              performActionForShortcutItem:shortcutItem
                         completionHandler:completionHandler]) {
        return YES;
      }
    }
  }
  return NO;
}

- (BOOL)application:(UIApplication*)application
    handleEventsForBackgroundURLSession:(nonnull NSString*)identifier
                      completionHandler:(nonnull void (^)())completionHandler {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:_cmd]) {
      if ([delegate application:application
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
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate) {
      continue;
    }
    if ([delegate respondsToSelector:_cmd]) {
      if ([delegate application:application performFetchWithCompletionHandler:completionHandler]) {
        return YES;
      }
    }
  }
  return NO;
}

- (BOOL)application:(UIApplication*)application
    continueUserActivity:(NSUserActivity*)userActivity
      restorationHandler:(void (^)(NSArray*))restorationHandler {
  return [self application:application
      continueUserActivity:userActivity
        restorationHandler:restorationHandler
        isFallbackForScene:NO];
}

- (BOOL)sceneFallbackContinueUserActivity:(NSUserActivity*)userActivity {
  UIApplication* application = FlutterSharedApplication.application;
  if (!application) {
    return NO;
  }
  return [self application:application
      continueUserActivity:userActivity
        restorationHandler:nil
        isFallbackForScene:YES];
}

- (BOOL)application:(UIApplication*)application
    continueUserActivity:(NSUserActivity*)userActivity
      restorationHandler:(void (^)(NSArray*))restorationHandler
      isFallbackForScene:(BOOL)isFallback {
  for (NSObject<FlutterApplicationLifeCycleDelegate>* delegate in _delegates) {
    if (!delegate || (isFallback && [self pluginSupportsSceneLifecycle:delegate])) {
      continue;
    }
    if ([delegate respondsToSelector:@selector(application:
                                         continueUserActivity:restorationHandler:)]) {
      if ([delegate application:application
              continueUserActivity:userActivity
                restorationHandler:restorationHandler]) {
        return YES;
      }
    }
  }
  return NO;
}
@end
