// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterAppDelegate_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPluginAppLifeCycleDelegate_internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifeCycle_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSharedApplication.h"

FLUTTER_ASSERT_ARC

@interface FlutterPluginSceneLifeCycleDelegate ()

/**
 * An array of weak pointers to `FlutterEngine`s that have views within this scene. Flutter
 * automatically adds engines to this array.
 *
 * This array is lazily cleaned up. `updateFlutterManagedEnginesInScene:` should be called before
 * use to ensure it is up-to-date.
 */
@property(nonatomic, strong) NSPointerArray* flutterManagedEngines;

/**
 * An array of weak pointers to `FlutterEngine`s that have views within this scene. Developers
 * manually add engines to this array.
 *
 * It is up to the developer to keep this list up-to-date.
 */
@property(nonatomic, strong) NSPointerArray* developerManagedEngines;

@property(nonatomic, strong) UISceneConnectionOptions* connectionOptions;
@property(nonatomic, assign) BOOL sceneWillConnectEventHandledByPlugin;
@property(nonatomic, assign) BOOL sceneWillConnectFallbackCalled;

@end

@implementation FlutterPluginSceneLifeCycleDelegate
- (instancetype)init {
  if (self = [super init]) {
    _flutterManagedEngines = [NSPointerArray weakObjectsPointerArray];
    _developerManagedEngines = [NSPointerArray weakObjectsPointerArray];
    _sceneWillConnectFallbackCalled = NO;
    _sceneWillConnectEventHandledByPlugin = NO;
  }
  return self;
}

#pragma mark - Manual Engine Registration

- (BOOL)registerSceneLifeCycleWithFlutterEngine:(FlutterEngine*)engine {
  // If the engine is Flutter-managed, remove it, since the developer as opted to manually register
  // it
  [self removeFlutterManagedEngine:engine];

  // Check if the engine is already in the array to avoid duplicates.
  if ([self manuallyRegisteredEngine:engine]) {
    return NO;
  }

  [self.developerManagedEngines addPointer:(__bridge void*)engine];

  [self compactNSPointerArray:self.developerManagedEngines];

  engine.manuallyRegisteredToScene = YES;

  return YES;
}

- (BOOL)unregisterSceneLifeCycleWithFlutterEngine:(FlutterEngine*)engine {
  NSUInteger index = [self.developerManagedEngines.allObjects indexOfObject:engine];
  if (index != NSNotFound) {
    [self.developerManagedEngines removePointerAtIndex:index];
    return YES;
  }
  return NO;
}

- (BOOL)manuallyRegisteredEngine:(FlutterEngine*)engine {
  return [self.developerManagedEngines.allObjects containsObject:engine];
}

#pragma mark - Automatic Flutter Engine Registration

- (BOOL)addFlutterManagedEngine:(FlutterEngine*)engine {
  // Check if the engine is already in the array to avoid duplicates.
  if ([self.flutterManagedEngines.allObjects containsObject:engine]) {
    return NO;
  }

  // If a manually registered engine, do not add, as it is being handled manually.
  if (engine.manuallyRegisteredToScene) {
    return NO;
  }

  [self.flutterManagedEngines addPointer:(__bridge void*)engine];

  [self compactNSPointerArray:self.flutterManagedEngines];
  return YES;
}

- (BOOL)removeFlutterManagedEngine:(FlutterEngine*)engine {
  NSUInteger index = [self.flutterManagedEngines.allObjects indexOfObject:engine];
  if (index != NSNotFound) {
    [self.flutterManagedEngines removePointerAtIndex:index];
    return YES;
  }
  return NO;
}

- (void)updateFlutterManagedEnginesInScene:(UIScene*)scene {
  // Removes engines that are no longer in the scene or have been deallocated.
  //
  // This also handles the case where a FlutterEngine's view has been moved to a different scene.
  for (NSUInteger i = 0; i < self.flutterManagedEngines.count; i++) {
    FlutterEngine* engine = (FlutterEngine*)[self.flutterManagedEngines pointerAtIndex:i];

    // The engine may be nil if it has been deallocated.
    if (engine == nil) {
      [self.flutterManagedEngines removePointerAtIndex:i];
      i--;
      continue;
    }

    // There aren't any events that inform us when a UIWindow changes scenes.
    // If a developer moves an entire UIWindow to a different scene and that window has a
    // FlutterView inside of it, its engine will still be in its original scene's
    // FlutterPluginSceneLifeCycleDelegate. The best we can do is move the engine to the correct
    // scene here. Due to this, when moving a UIWindow from one scene to another, its first scene
    // event may be lost. Since Flutter does not fully support multi-scene and this is an edge
    // case, this is a loss we can deal with. To workaround this, the developer can move the
    // UIView instead of the UIWindow, which will use willMoveToWindow to add/remove the engine from
    // the scene.
    UIWindowScene* actualScene = engine.viewController.view.window.windowScene;
    if (actualScene != nil && actualScene != scene) {
      [self.flutterManagedEngines removePointerAtIndex:i];
      i--;

      if ([actualScene.delegate conformsToProtocol:@protocol(FlutterSceneLifeCycleProvider)]) {
        id<FlutterSceneLifeCycleProvider> lifeCycleProvider =
            (id<FlutterSceneLifeCycleProvider>)actualScene.delegate;
        [lifeCycleProvider.sceneLifeCycleDelegate addFlutterManagedEngine:engine];
      }
      continue;
    }
  }
}

- (NSArray*)allEngines {
  return [_flutterManagedEngines.allObjects
      arrayByAddingObjectsFromArray:_developerManagedEngines.allObjects];
}

/**
 * Makes a best effort to get the FlutterPluginAppLifeCycleDelegate from the AppDelegate if
 * available. It may not be available if embedded in an iOS app extension or the AppDelegate doesn't
 * subclass FlutterAppDelegate.
 */
- (FlutterPluginAppLifeCycleDelegate*)applicationLifeCycleDelegate {
  id appDelegate = FlutterSharedApplication.application.delegate;
  if ([appDelegate respondsToSelector:@selector(lifeCycleDelegate)]) {
    id lifecycleDelegate = [appDelegate lifeCycleDelegate];
    if ([lifecycleDelegate isKindOfClass:[FlutterPluginAppLifeCycleDelegate class]]) {
      return lifecycleDelegate;
    }
  }
  return nil;
}

#pragma mark - Connecting and disconnecting the scene

- (void)engine:(FlutterEngine*)engine receivedConnectNotificationFor:(UIScene*)scene {
  // Connection options may be nil if the notification was received before the
  // `scene:willConnectToSession:options:` event. In which case, we can wait for the actual event.
  BOOL added = [self addFlutterManagedEngine:engine];
  if (!added) {
    // Don't send willConnectToSession event if engine is already tracked as it will be handled by
    // the actual event.
    return;
  }
  if (self.connectionOptions != nil) {
    [self scene:scene
        willConnectToSession:scene.session
               flutterEngine:engine
                     options:self.connectionOptions];
  }
}

- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
                 options:(UISceneConnectionOptions*)connectionOptions {
  self.connectionOptions = connectionOptions;
  if ([scene.delegate conformsToProtocol:@protocol(UIWindowSceneDelegate)]) {
    NSObject<UIWindowSceneDelegate>* sceneDelegate =
        (NSObject<UIWindowSceneDelegate>*)scene.delegate;
    if ([sceneDelegate.window.rootViewController isKindOfClass:[FlutterViewController class]]) {
      FlutterViewController* rootViewController =
          (FlutterViewController*)sceneDelegate.window.rootViewController;
      [self addFlutterManagedEngine:rootViewController.engine];
    }
  }

  [self updateFlutterManagedEnginesInScene:scene];

  for (FlutterEngine* engine in [self allEngines]) {
    [self scene:scene willConnectToSession:session flutterEngine:engine options:connectionOptions];
  }
}

- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
           flutterEngine:(FlutterEngine*)engine
                 options:(UISceneConnectionOptions*)connectionOptions {
  // Don't send connection options if a plugin has already used them.
  UISceneConnectionOptions* availableOptions = connectionOptions;
  if (self.sceneWillConnectEventHandledByPlugin) {
    availableOptions = nil;
  }
  BOOL handledByPlugin = [engine.sceneLifeCycleDelegate scene:scene
                                         willConnectToSession:session
                                                      options:availableOptions];

  // If no plugins handled this, give the application fallback a chance to handle it.
  // Only call the fallback once since it's per application.
  if (!handledByPlugin && !self.sceneWillConnectFallbackCalled) {
    self.sceneWillConnectFallbackCalled = YES;
    if ([[self applicationLifeCycleDelegate] sceneWillConnectFallback:connectionOptions]) {
      handledByPlugin = YES;
    }
  }
  if (handledByPlugin) {
    self.sceneWillConnectEventHandledByPlugin = YES;
  }

  if (!self.sceneWillConnectEventHandledByPlugin) {
    // Only process deeplinks if a plugin has not already done something to handle this event.
    [self handleDeeplinkingForEngine:engine options:connectionOptions];
  }
}

- (void)sceneDidDisconnect:(UIScene*)scene {
  [self updateFlutterManagedEnginesInScene:scene];
  for (FlutterEngine* engine in [self allEngines]) {
    [engine.sceneLifeCycleDelegate sceneDidDisconnect:scene];
  }
  // There is no application equivalent for this event and therefore no fallback.
}

#pragma mark - Transitioning to the foreground

- (void)sceneWillEnterForeground:(UIScene*)scene {
  [self updateFlutterManagedEnginesInScene:scene];
  for (FlutterEngine* engine in [self allEngines]) {
    [engine.sceneLifeCycleDelegate sceneWillEnterForeground:scene];
  }
  [[self applicationLifeCycleDelegate] sceneWillEnterForegroundFallback];
}

- (void)sceneDidBecomeActive:(UIScene*)scene {
  [self updateFlutterManagedEnginesInScene:scene];
  for (FlutterEngine* engine in [self allEngines]) {
    [engine.sceneLifeCycleDelegate sceneDidBecomeActive:scene];
  }
  [[self applicationLifeCycleDelegate] sceneDidBecomeActiveFallback];
}

#pragma mark - Transitioning to the background

- (void)sceneWillResignActive:(UIScene*)scene {
  [self updateFlutterManagedEnginesInScene:scene];
  for (FlutterEngine* engine in [self allEngines]) {
    [engine.sceneLifeCycleDelegate sceneWillResignActive:scene];
  }
  [[self applicationLifeCycleDelegate] sceneWillResignActiveFallback];
}

- (void)sceneDidEnterBackground:(UIScene*)scene {
  [self updateFlutterManagedEnginesInScene:scene];
  for (FlutterEngine* engine in [self allEngines]) {
    [engine.sceneLifeCycleDelegate sceneDidEnterBackground:scene];
  }
  [[self applicationLifeCycleDelegate] sceneDidEnterBackgroundFallback];
}

#pragma mark - Opening URLs

- (void)scene:(UIScene*)scene openURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts {
  [self updateFlutterManagedEnginesInScene:scene];

  // Track engines that had this event handled by a plugin.
  NSMutableSet<FlutterEngine*>* enginesHandledByPlugin = [NSMutableSet set];
  for (FlutterEngine* engine in [self allEngines]) {
    if ([engine.sceneLifeCycleDelegate scene:scene openURLContexts:URLContexts]) {
      [enginesHandledByPlugin addObject:engine];
    }
  }

  // If no plugins handled this, give the application fallback a chance to handle it.
  if (enginesHandledByPlugin.count == 0) {
    if ([[self applicationLifeCycleDelegate] sceneFallbackOpenURLContexts:URLContexts]) {
      // If the application fallback handles it, don't do any deeplinking.
      return;
    }
  }

  // For any engine that was not handled by a plugin, do deeplinking.
  for (FlutterEngine* engine in [self allEngines]) {
    if ([enginesHandledByPlugin containsObject:engine]) {
      continue;
    }
    for (UIOpenURLContext* urlContext in URLContexts) {
      if ([self handleDeeplink:urlContext.URL flutterEngine:engine relayToSystemIfUnhandled:NO]) {
        break;
      }
    }
  }
}

#pragma mark - Continuing user activities

- (void)scene:(UIScene*)scene continueUserActivity:(NSUserActivity*)userActivity {
  [self updateFlutterManagedEnginesInScene:scene];

  // Track engines that had this event handled by a plugin.
  NSMutableSet<FlutterEngine*>* enginesHandledByPlugin = [NSMutableSet set];
  for (FlutterEngine* engine in [self allEngines]) {
    if ([engine.sceneLifeCycleDelegate scene:scene continueUserActivity:userActivity]) {
      [enginesHandledByPlugin addObject:engine];
    }
  }

  // If no plugins handled this, give the application fallback a chance to handle it.
  if (enginesHandledByPlugin.count == 0) {
    if ([[self applicationLifeCycleDelegate] sceneFallbackContinueUserActivity:userActivity]) {
      // If the application fallback handles it, don't do any deeplinking.
      return;
    }
  }

  // For any engine that was not handled by a plugin, do deeplinking.
  for (FlutterEngine* engine in [self allEngines]) {
    if ([enginesHandledByPlugin containsObject:engine]) {
      continue;
    }
    [self handleDeeplink:userActivity.webpageURL flutterEngine:engine relayToSystemIfUnhandled:YES];
  }
}

#pragma mark - Saving the state of the scene

- (NSUserActivity*)stateRestorationActivityForScene:(UIScene*)scene {
  // Saves state per FlutterViewController.
  NSUserActivity* activity = scene.userActivity;
  if (!activity) {
    activity = [[NSUserActivity alloc] initWithActivityType:scene.session.configuration.name];
  }

  [self updateFlutterManagedEnginesInScene:scene];
  int64_t appBundleModifiedTime = FlutterSharedApplication.lastAppModificationTime;
  for (FlutterEngine* engine in [self allEngines]) {
    FlutterViewController* vc = (FlutterViewController*)engine.viewController;
    NSString* restorationId = vc.restorationIdentifier;
    if (restorationId) {
      NSData* restorationData = [engine.restorationPlugin restorationData];
      if (restorationData) {
        [activity addUserInfoEntriesFromDictionary:@{restorationId : restorationData}];
        [activity addUserInfoEntriesFromDictionary:@{
          kRestorationStateAppModificationKey : [NSNumber numberWithLongLong:appBundleModifiedTime]
        }];
      }
    }
  }

  return activity;
}

- (void)scene:(UIScene*)scene
    restoreInteractionStateWithUserActivity:(NSUserActivity*)stateRestorationActivity {
  // Restores state per FlutterViewController.
  NSDictionary<NSString*, id>* userInfo = stateRestorationActivity.userInfo;
  [self updateFlutterManagedEnginesInScene:scene];
  int64_t appBundleModifiedTime = FlutterSharedApplication.lastAppModificationTime;
  NSNumber* stateDateNumber = userInfo[kRestorationStateAppModificationKey];
  int64_t stateDate = 0;
  if (stateDateNumber && [stateDateNumber isKindOfClass:[NSNumber class]]) {
    stateDate = [stateDateNumber longLongValue];
  }
  if (appBundleModifiedTime != stateDate) {
    // Don't restore state if the app has been re-installed since the state was last saved
    return;
  }

  for (FlutterEngine* engine in [self allEngines]) {
    UIViewController* vc = (UIViewController*)engine.viewController;
    NSString* restorationId = vc.restorationIdentifier;
    if (restorationId) {
      NSData* restorationData = userInfo[restorationId];
      if ([restorationData isKindOfClass:[NSData class]]) {
        [engine.restorationPlugin setRestorationData:restorationData];
      }
    }
  }
}

#pragma mark - Performing tasks

- (void)windowScene:(UIWindowScene*)windowScene
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler {
  [self updateFlutterManagedEnginesInScene:windowScene];

  BOOL handledByPlugin = NO;
  for (FlutterEngine* engine in [self allEngines]) {
    BOOL result = [engine.sceneLifeCycleDelegate windowScene:windowScene
                                performActionForShortcutItem:shortcutItem
                                           completionHandler:completionHandler];
    if (result) {
      handledByPlugin = YES;
    }
  }
  if (!handledByPlugin) {
    [[self applicationLifeCycleDelegate]
        sceneFallbackPerformActionForShortcutItem:shortcutItem
                                completionHandler:completionHandler];
  }
}

#pragma mark - Helpers

- (void)handleDeeplinkingForEngine:(FlutterEngine*)engine
                           options:(UISceneConnectionOptions*)connectionOptions {
  //  If your app has opted into Scenes, and your app is not running, the system delivers the
  //  universal link to the scene(_:willConnectTo:options:) delegate method after launch, and to
  //  scene(_:continue:) when the universal link is tapped while your app is running or suspended in
  //  memory.
  for (NSUserActivity* userActivity in connectionOptions.userActivities) {
    if ([self handleDeeplink:userActivity.webpageURL
                       flutterEngine:engine
            relayToSystemIfUnhandled:YES]) {
      return;
    }
  }

  //  If your app has opted into Scenes, and your app isn’t running, the system delivers the URL to
  //  the scene:willConnectToSession:options: delegate method after launch, and to
  //  scene:openURLContexts: when your app opens a URL while running or suspended in memory.
  for (UIOpenURLContext* urlContext in connectionOptions.URLContexts) {
    if ([self handleDeeplink:urlContext.URL flutterEngine:engine relayToSystemIfUnhandled:YES]) {
      return;
    }
  }
}

- (BOOL)handleDeeplink:(NSURL*)url
               flutterEngine:(FlutterEngine*)engine
    relayToSystemIfUnhandled:(BOOL)throwBack {
  if (!url) {
    return NO;
  }
  // Don't process the link if deep linking is disabled.
  if (!FlutterSharedApplication.isFlutterDeepLinkingEnabled) {
    return NO;
  }
  // if deep linking is enabled, send it to the framework
  [engine sendDeepLinkToFramework:url
                completionHandler:^(BOOL success) {
                  if (!success && throwBack) {
                    // throw it back to iOS
                    [FlutterSharedApplication.application openURL:url
                                                          options:@{}
                                                completionHandler:nil];
                  }
                }];
  return YES;
}

+ (FlutterPluginSceneLifeCycleDelegate*)fromScene:(UIScene*)scene {
  if ([scene.delegate conformsToProtocol:@protocol(FlutterSceneLifeCycleProvider)]) {
    NSObject<FlutterSceneLifeCycleProvider>* sceneProvider =
        (NSObject<FlutterSceneLifeCycleProvider>*)scene.delegate;
    return sceneProvider.sceneLifeCycleDelegate;
  }

  // When embedded in a SwiftUI app, the scene delegate does not conform to
  // FlutterSceneLifeCycleProvider even if it does. However, after force casting it,
  // selectors respond and can be used.
  NSObject<FlutterSceneLifeCycleProvider>* sceneProvider =
      (NSObject<FlutterSceneLifeCycleProvider>*)scene.delegate;
  if ([sceneProvider respondsToSelector:@selector(sceneLifeCycleDelegate)]) {
    id sceneLifeCycleDelegate = sceneProvider.sceneLifeCycleDelegate;
    // Double check that the selector is the expected class.
    if ([sceneLifeCycleDelegate isKindOfClass:[FlutterPluginSceneLifeCycleDelegate class]]) {
      return (FlutterPluginSceneLifeCycleDelegate*)sceneLifeCycleDelegate;
    }
  }
  return nil;
}

- (void)compactNSPointerArray:(NSPointerArray*)array {
  // NSPointerArray is clever and assumes that unless a mutation operation has occurred on it that
  // has set one of its values to nil, nothing could have changed and it can skip compaction.
  // That's reasonable behaviour on a regular NSPointerArray but not for a weakObjectPointerArray.
  // As a workaround, we mutate it first. See: http://www.openradar.me/15396578
  [array addPointer:nil];
  [array compact];
}
@end

@implementation FlutterEnginePluginSceneLifeCycleDelegate {
  // Weak references to registered plugins.
  NSPointerArray* _delegates;
}

- (instancetype)init {
  if (self = [super init]) {
    _delegates = [NSPointerArray weakObjectsPointerArray];
  }
  return self;
}

- (void)addDelegate:(NSObject<FlutterSceneLifeCycleDelegate>*)delegate {
  [_delegates addPointer:(__bridge void*)delegate];

  // NSPointerArray is clever and assumes that unless a mutation operation has occurred on it that
  // has set one of its values to nil, nothing could have changed and it can skip compaction.
  // That's reasonable behaviour on a regular NSPointerArray but not for a weakObjectPointerArray.
  // As a workaround, we mutate it first. See: http://www.openradar.me/15396578
  [_delegates addPointer:nil];
  [_delegates compact];
}

#pragma mark - Connecting and disconnecting the scene

- (BOOL)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
                 options:(UISceneConnectionOptions*)connectionOptions {
  BOOL handledByPlugin = NO;
  for (NSObject<FlutterSceneLifeCycleDelegate>* delegate in _delegates.allObjects) {
    if ([delegate respondsToSelector:_cmd]) {
      // If this event has already been consumed by a plugin, send the event with nil options.
      // Only allow one plugin to process the connection options.
      if ([delegate scene:scene
              willConnectToSession:session
                           options:(handledByPlugin ? nil : connectionOptions)]) {
        handledByPlugin = YES;
      }
    }
  }
  return handledByPlugin;
}

- (void)sceneDidDisconnect:(UIScene*)scene {
  for (NSObject<FlutterSceneLifeCycleDelegate>* delegate in _delegates.allObjects) {
    if ([delegate respondsToSelector:_cmd]) {
      [delegate sceneDidDisconnect:scene];
    }
  }
}

#pragma mark - Transitioning to the foreground

- (void)sceneWillEnterForeground:(UIScene*)scene {
  for (NSObject<FlutterSceneLifeCycleDelegate>* delegate in _delegates.allObjects) {
    if ([delegate respondsToSelector:_cmd]) {
      [delegate sceneWillEnterForeground:scene];
    }
  }
}

- (void)sceneDidBecomeActive:(UIScene*)scene {
  for (NSObject<FlutterSceneLifeCycleDelegate>* delegate in _delegates.allObjects) {
    if ([delegate respondsToSelector:_cmd]) {
      [delegate sceneDidBecomeActive:scene];
    }
  }
}

#pragma mark - Transitioning to the background

- (void)sceneWillResignActive:(UIScene*)scene {
  for (NSObject<FlutterSceneLifeCycleDelegate>* delegate in _delegates.allObjects) {
    if ([delegate respondsToSelector:_cmd]) {
      [delegate sceneWillResignActive:scene];
    }
  }
}

- (void)sceneDidEnterBackground:(UIScene*)scene {
  for (NSObject<FlutterSceneLifeCycleDelegate>* delegate in _delegates.allObjects) {
    if ([delegate respondsToSelector:_cmd]) {
      [delegate sceneDidEnterBackground:scene];
    }
  }
}

#pragma mark - Opening URLs

- (BOOL)scene:(UIScene*)scene openURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts {
  for (NSObject<FlutterSceneLifeCycleDelegate>* delegate in _delegates.allObjects) {
    if ([delegate respondsToSelector:_cmd]) {
      if ([delegate scene:scene openURLContexts:URLContexts]) {
        // Only allow one plugin to process this event.
        return YES;
      }
    }
  }
  return NO;
}

#pragma mark - Continuing user activities

- (BOOL)scene:(UIScene*)scene continueUserActivity:(NSUserActivity*)userActivity {
  for (NSObject<FlutterSceneLifeCycleDelegate>* delegate in _delegates.allObjects) {
    if ([delegate respondsToSelector:_cmd]) {
      if ([delegate scene:scene continueUserActivity:userActivity]) {
        // Only allow one plugin to process this event.
        return YES;
      }
    }
  }
  return NO;
}

#pragma mark - Performing tasks

- (BOOL)windowScene:(UIWindowScene*)windowScene
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler {
  for (NSObject<FlutterSceneLifeCycleDelegate>* delegate in _delegates.allObjects) {
    if ([delegate respondsToSelector:_cmd]) {
      if ([delegate windowScene:windowScene
              performActionForShortcutItem:shortcutItem
                         completionHandler:completionHandler]) {
        // Only allow one plugin to process this event.
        return YES;
      }
    }
  }
  return NO;
}
@end
