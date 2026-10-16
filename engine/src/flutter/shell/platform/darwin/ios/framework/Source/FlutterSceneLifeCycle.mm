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

// Used to determine whether to compact a pointer array.
// Compacting only when `count` is a power of two amortizes the O(n) compaction cost to O(1).
static BOOL IsPowerOfTwo(NSUInteger x) {
  return x != 0 && (x & (x - 1)) == 0;
}

static void CompactNSPointerArray(NSPointerArray* array) {
  // NSPointerArray is clever and assumes that unless a mutation operation has occurred on it that
  // has set one of its values to nil, nothing could have changed and it can skip compaction.
  // That's reasonable behaviour on a regular NSPointerArray but not for a weakObjectPointerArray.
  // As a workaround, we mutate it first. See: http://www.openradar.me/15396578
  [array addPointer:nil];
  [array compact];
}

@interface FlutterPluginSceneLifeCycleDelegate ()

// Developer managed engines registered and unregstered via FlutterSceneLifeCycleEngineRegistry API.
@property(nonatomic, strong) NSMapTable<UIScene*, NSPointerArray*>* developerManagedEngines;

// Developer managed engines registered and unregistered via deprecated
// FlutterSceneLifeCycleEngineRegistration API.
@property(nonatomic, strong) NSPointerArray* legacyDeveloperManagedEngines;

// Tracks the connecting scenes and their connectionOptions within the initial connection runloop.
// Once the connection window ends on the next runloop, entries are removed.
// This is to ensure engines attached after sceneWillConnect (but still in the same runloop)
// still receive their sceneWillConnect event (e.g. viewDidLoad of the root view controller).
@property(nonatomic, strong) NSMapTable<UIScene*, UISceneConnectionOptions*>* connectingScenes;
// To avoid duplicate sceneWillConnect events being sent to the same engine.
@property(nonatomic, strong) NSMapTable<UIScene*, NSPointerArray*>* enginesSentConnectionEvent;

// Tracks whether any plugin handled the sceneWillConnect event for a scene.
@property(nonatomic, strong) NSMapTable<UIScene*, NSNumber*>* sceneWillConnectEventHandledByPlugin;

@end

@implementation FlutterPluginSceneLifeCycleDelegate

// Tracks all engines for single-scene applications.
// Uses a static variable because the FlutterEngine could be created before
// UISceneDelegate object is created.
static NSPointerArray* _enginesForSingleScene = nil;

// Tracks whether the application-level sceneWillConnect fallback (which forwards to
// application:didFinishLaunchingWithOptions:) has already been invoked. This must only be
// called once per application lifetime.
static BOOL _sceneWillConnectFallbackCalled = NO;

+ (void)registerEngineForSingleScene:(FlutterEngine*)engine {
  if (!_enginesForSingleScene) {
    _enginesForSingleScene = [NSPointerArray weakObjectsPointerArray];
  }
  [_enginesForSingleScene addPointer:(__bridge void*)engine];
  if (IsPowerOfTwo(_enginesForSingleScene.count)) {
    CompactNSPointerArray(_enginesForSingleScene);
  }
}

- (void)searchFlutterViewControllersWithResult:(NSMutableArray<FlutterViewController*>*)result
                                       visited:(NSMutableSet<UIViewController*>*)visited
                                viewController:(UIViewController*)viewController {
  if (!viewController) {
    return;
  }
  if ([visited containsObject:viewController]) {
    return;
  }
  [visited addObject:viewController];

  if ([viewController isKindOfClass:[FlutterViewController class]]) {
    [result addObject:(FlutterViewController*)viewController];
  }

  for (UIViewController* childViewController in viewController.childViewControllers) {
    [self searchFlutterViewControllersWithResult:result
                                         visited:visited
                                  viewController:childViewController];
  }

  if (viewController.presentedViewController) {
    [self searchFlutterViewControllersWithResult:result
                                         visited:visited
                                  viewController:viewController.presentedViewController];
  }
}

- (NSArray<FlutterViewController*>*)searchFlutterViewControllersWithinScene:(UIScene*)scene {
  NSMutableArray<FlutterViewController*>* result = [NSMutableArray array];
  NSMutableSet<UIViewController*>* visited = [NSMutableSet set];
  if ([scene isKindOfClass:[UIWindowScene class]]) {
    UIWindowScene* windowScene = (UIWindowScene*)scene;
    for (UIWindow* window in windowScene.windows) {
      [self searchFlutterViewControllersWithResult:result
                                           visited:visited
                                    viewController:window.rootViewController];
    }
  }
  return [result copy];
}

- (NSArray<FlutterEngine*>*)searchFlutterEnginesWithinScene:(UIScene*)scene {
  if (!FlutterSharedApplication.application.supportsMultipleScenes) {
    return _enginesForSingleScene.allObjects ?: @[];
  }

  NSMutableSet<FlutterEngine*>* result = [NSMutableSet set];
  NSArray<FlutterViewController*>* flutterViewControllers =
      [self searchFlutterViewControllersWithinScene:scene];
  for (FlutterViewController* flutterViewController in flutterViewControllers) {
    FlutterEngine* engine = flutterViewController.engine;
    if (engine) {
      [result addObject:engine];
    }
  }

  NSPointerArray* developerEngines = [self.developerManagedEngines objectForKey:scene];
  // allObjects already filters out nil objects.
  for (FlutterEngine* engine in developerEngines.allObjects) {
    [result addObject:engine];
  }
  for (FlutterEngine* engine in self.legacyDeveloperManagedEngines.allObjects) {
    [result addObject:engine];
  }
  return result.allObjects;
}

- (instancetype)init {
  if (self = [super init]) {
    _developerManagedEngines = [NSMapTable weakToStrongObjectsMapTable];
    _legacyDeveloperManagedEngines = [NSPointerArray weakObjectsPointerArray];
    _enginesSentConnectionEvent = [NSMapTable weakToStrongObjectsMapTable];
    _connectingScenes = [NSMapTable weakToStrongObjectsMapTable];
    _sceneWillConnectEventHandledByPlugin = [NSMapTable weakToStrongObjectsMapTable];
  }
  return self;
}

#pragma mark - Manual Engine Registration

- (BOOL)addEngine:(FlutterEngine*)engine toPointerArray:(NSPointerArray*)engines {
  if ([engines.allObjects containsObject:engine]) {
    return NO;
  }
  [engines addPointer:(__bridge void*)engine];
  if (IsPowerOfTwo(engines.count)) {
    CompactNSPointerArray(engines);
  }
  return YES;
}

- (BOOL)removeEngine:(FlutterEngine*)engine fromPointerArray:(NSPointerArray*)engines {
  for (NSUInteger i = 0; i < engines.count; i++) {
    if ([engines pointerAtIndex:i] == (__bridge void*)engine) {
      [engines removePointerAtIndex:i];
      if (IsPowerOfTwo(engines.count)) {
        CompactNSPointerArray(engines);
      }
      return YES;
    }
  }
  return NO;
}

/**
 * Adds `engine` to the weak array `mapTable` keeps for `scene`, creating the array if needed.
 *
 * Returns NO if the engine was already tracked for that scene.
 */
- (BOOL)addEngine:(FlutterEngine*)engine
       toMapTable:(NSMapTable<UIScene*, NSPointerArray*>*)mapTable
         forScene:(UIScene*)scene {
  NSPointerArray* engines = [mapTable objectForKey:scene];
  if (!engines) {
    engines = [NSPointerArray weakObjectsPointerArray];
    [mapTable setObject:engines forKey:scene];
  }
  return [self addEngine:engine toPointerArray:engines];
}

- (BOOL)registerSceneLifeCycleWithFlutterEngine:(FlutterEngine*)engine scene:(UIScene*)scene {
  return [self addEngine:engine toMapTable:self.developerManagedEngines forScene:scene];
}

- (BOOL)unregisterSceneLifeCycleWithFlutterEngine:(FlutterEngine*)engine scene:(UIScene*)scene {
  NSPointerArray* engines = [self.developerManagedEngines objectForKey:scene];
  return [self removeEngine:engine fromPointerArray:engines];
}

- (BOOL)registerSceneLifeCycleWithFlutterEngine:(FlutterEngine*)engine {
  return [self addEngine:engine toPointerArray:self.legacyDeveloperManagedEngines];
}

- (BOOL)unregisterSceneLifeCycleWithFlutterEngine:(FlutterEngine*)engine {
  return [self removeEngine:engine fromPointerArray:self.legacyDeveloperManagedEngines];
}

- (void)markConnectionEventSentForEngine:(FlutterEngine*)engine scene:(UIScene*)scene {
  [self addEngine:engine toMapTable:self.enginesSentConnectionEvent forScene:scene];
}

- (BOOL)alreadySentSceneConnectionForScene:(UIScene*)scene engine:(FlutterEngine*)engine {
  NSArray<FlutterEngine*>* engines =
      [self.enginesSentConnectionEvent objectForKey:scene].allObjects ?: @[];
  return [engines containsObject:engine];
}

- (void)connectEngineIfNeeded:(FlutterEngine*)engine scene:(UIScene*)scene {
  UISceneConnectionOptions* connectionOptions = [self.connectingScenes objectForKey:scene];
  if (connectionOptions == nil) {
    return;
  }
  if ([self alreadySentSceneConnectionForScene:scene engine:engine]) {
    return;
  }
  [self markConnectionEventSentForEngine:engine scene:scene];
  [self scene:scene
      willConnectToSession:scene.session
             flutterEngine:engine
                   options:connectionOptions];
}

+ (void)resetSceneWillConnectFallbackCalledForTesting {
  _sceneWillConnectFallbackCalled = NO;
}

+ (void)resetEnginesForSingleSceneForTesting {
  _enginesForSingleScene = nil;
}

- (BOOL)sceneWillConnectEventHandledByPluginForScene:(UIScene*)scene {
  return [[self.sceneWillConnectEventHandledByPlugin objectForKey:scene] boolValue];
}

- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
           flutterEngine:(FlutterEngine*)engine
                 options:(UISceneConnectionOptions*)connectionOptions {
  // Don't send connection options if a plugin has already used them.
  UISceneConnectionOptions* availableOptions = connectionOptions;
  if ([self sceneWillConnectEventHandledByPluginForScene:scene]) {
    availableOptions = nil;
  }
  BOOL handledByPlugin = [engine.sceneLifeCycleDelegate scene:scene
                                         willConnectToSession:session
                                                      options:availableOptions];

  // If no plugins handled this, give the application fallback a chance to handle it.
  // Only call the fallback once since it's per application.
  if (!handledByPlugin && !_sceneWillConnectFallbackCalled) {
    _sceneWillConnectFallbackCalled = YES;
    if ([[self applicationLifeCycleDelegate] sceneWillConnectFallback:connectionOptions]) {
      handledByPlugin = YES;
    }
  }
  if (handledByPlugin) {
    [self.sceneWillConnectEventHandledByPlugin setObject:@YES forKey:scene];
  }

  if (![self sceneWillConnectEventHandledByPluginForScene:scene]) {
    // Only process deeplinks if a plugin has not already done something to handle this event.
    [self handleDeeplinkingForEngine:engine options:connectionOptions];
  }
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

- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
                 options:(UISceneConnectionOptions*)connectionOptions {
  if (connectionOptions != nil) {
    [self.connectingScenes setObject:connectionOptions forKey:scene];
  }

  NSArray<FlutterEngine*>* engines = [self searchFlutterEnginesWithinScene:scene];
  for (FlutterEngine* engine in engines) {
    [self connectEngineIfNeeded:engine scene:scene];
  }

  // Keep `connectionOptions` in `connectingScenes` for the remainder of the current run loop so
  // that engines attached after `sceneWillConnect` (e.g. in the root view controller's
  // `viewDidLoad`, before `sceneWillEnterForeground` or `sceneDidEnterBackground`) still receive
  // the initial connection event. Remove it on the next run loop turn so that engines attached or
  // foregrounded later do not receive a stale connection event.
  __weak __typeof(self) weakSelf = self;
  __weak __typeof(scene) weakScene = scene;
  dispatch_async(dispatch_get_main_queue(), ^{
    __typeof(self) strongSelf = weakSelf;
    __typeof(scene) strongScene = weakScene;
    if (strongSelf && strongScene) {
      [strongSelf.connectingScenes removeObjectForKey:strongScene];
    }
  });
}

- (void)sceneDidDisconnect:(UIScene*)scene {
  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:scene]) {
    [engine.sceneLifeCycleDelegate sceneDidDisconnect:scene];
  }
  // There is no application equivalent for this event and therefore no fallback.
}

#pragma mark - Transitioning to the foreground

- (void)sceneWillEnterForeground:(UIScene*)scene {
  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:scene]) {
    // If the engine is added after sceneWillConnect but before sceneWillEnterForeground
    // (e.g. viewDidLoad of the root view controller), we still want to send connection event.
    // Before UIScene, storyboard's rootVC is loaded before didFinishLaunching is called.
    // After UIScene, it's deferred until after sceneWillConnect (but still within the same
    // run loop). However, if developers set up FlutterViewController in rootVC's viewDidLoad,
    // the intention to receive lifecycle events remains the same.
    [self connectEngineIfNeeded:engine scene:scene];
    [engine.sceneLifeCycleDelegate sceneWillEnterForeground:scene];
  }

  [[self applicationLifeCycleDelegate] sceneWillEnterForegroundFallback];
}

- (void)sceneDidBecomeActive:(UIScene*)scene {
  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:scene]) {
    [engine.sceneLifeCycleDelegate sceneDidBecomeActive:scene];
  }

  [[self applicationLifeCycleDelegate] sceneDidBecomeActiveFallback];
}

#pragma mark - Transitioning to the background

- (void)sceneWillResignActive:(UIScene*)scene {
  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:scene]) {
    [engine.sceneLifeCycleDelegate sceneWillResignActive:scene];
  }
  [[self applicationLifeCycleDelegate] sceneWillResignActiveFallback];
}

- (void)sceneDidEnterBackground:(UIScene*)scene {
  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:scene]) {
    // A scene could start in background mode.
    // See sceneWillEnterForeground for rational behind sending connection event.
    [self connectEngineIfNeeded:engine scene:scene];
    [engine.sceneLifeCycleDelegate sceneDidEnterBackground:scene];
  }
  [[self applicationLifeCycleDelegate] sceneDidEnterBackgroundFallback];
}

#pragma mark - Opening URLs

- (void)scene:(UIScene*)scene openURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts {
  // Track engines that had this event handled by a plugin.
  NSMutableSet<FlutterEngine*>* enginesHandledByPlugin = [NSMutableSet set];
  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:scene]) {
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
  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:scene]) {
    if ([enginesHandledByPlugin containsObject:engine]) {
      continue;
    }
    for (UIOpenURLContext* urlContext in URLContexts) {
      if ([self handleDeeplink:urlContext.URL flutterEngine:engine]) {
        break;
      }
    }
  }
}

#pragma mark - Continuing user activities

- (void)scene:(UIScene*)scene continueUserActivity:(NSUserActivity*)userActivity {
  // Track engines that had this event handled by a plugin.
  NSMutableSet<FlutterEngine*>* enginesHandledByPlugin = [NSMutableSet set];
  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:scene]) {
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
  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:scene]) {
    if ([enginesHandledByPlugin containsObject:engine]) {
      continue;
    }
    [self handleDeeplink:userActivity.webpageURL flutterEngine:engine];
  }
}

#pragma mark - Saving the state of the scene

- (NSUserActivity*)stateRestorationActivityForScene:(UIScene*)scene {
  // Saves state per FlutterViewController.
  NSUserActivity* activity = scene.userActivity;
  if (!activity) {
    activity = [[NSUserActivity alloc] initWithActivityType:scene.session.configuration.name];
  }

  int64_t appBundleModifiedTime = FlutterSharedApplication.lastAppModificationTime;
  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:scene]) {
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

  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:scene]) {
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
  BOOL handledByPlugin = NO;
  for (FlutterEngine* engine in [self searchFlutterEnginesWithinScene:windowScene]) {
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
    if ([self handleDeeplink:userActivity.webpageURL flutterEngine:engine]) {
      return;
    }
  }

  //  If your app has opted into Scenes, and your app isn’t running, the system delivers the URL to
  //  the scene:willConnectToSession:options: delegate method after launch, and to
  //  scene:openURLContexts: when your app opens a URL while running or suspended in memory.
  for (UIOpenURLContext* urlContext in connectionOptions.URLContexts) {
    if ([self handleDeeplink:urlContext.URL flutterEngine:engine]) {
      return;
    }
  }
}

- (BOOL)handleDeeplink:(NSURL*)url flutterEngine:(FlutterEngine*)engine {
  if (!url) {
    return NO;
  }
  // Don't process the link if deep linking is disabled.
  if (!FlutterSharedApplication.isFlutterDeepLinkingEnabled) {
    return NO;
  }
  // if deep linking is enabled, send it to the framework
  [engine sendDeepLinkToFramework:url
                completionHandler:^(BOOL success){
                    // no-op.
                }];
  return YES;
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
  CompactNSPointerArray(_delegates);
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
