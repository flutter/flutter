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

static NSString* const kRestorationStateAppModificationKey = @"mod-date";

@interface FlutterPluginSceneLifeCycleDelegate ()

/**
 * An array of weak pointers to `FlutterEngine`s that have views within this scene.
 *
 * This array is lazily cleaned up. `updateEnginesInScene:` should be called before use to ensure it
 * is up-to-date.
 */
@property(nonatomic, strong) NSPointerArray* engines;

@property(nonatomic, strong) UISceneConnectionOptions* connectionOptions;
@end

@implementation FlutterPluginSceneLifeCycleDelegate
- (instancetype)init {
  if (self = [super init]) {
    _engines = [NSPointerArray weakObjectsPointerArray];
  }
  return self;
}

- (void)addFlutterEngine:(FlutterEngine*)engine {
  // Check if the engine is already in the array to avoid duplicates.
  if ([self.engines.allObjects containsObject:engine]) {
    return;
  }

  [self.engines addPointer:(__bridge void*)engine];

  // NSPointerArray is clever and assumes that unless a mutation operation has occurred on it that
  // has set one of its values to nil, nothing could have changed and it can skip compaction.
  // That's reasonable behaviour on a regular NSPointerArray but not for a weakObjectPointerArray.
  // As a workaround, we mutate it first. See: http://www.openradar.me/15396578
  [self.engines addPointer:nil];
  [self.engines compact];
}

- (void)removeFlutterEngine:(FlutterEngine*)engine {
  NSUInteger index = [self.engines.allObjects indexOfObject:engine];
  if (index != NSNotFound) {
    [self.engines removePointerAtIndex:index];
  }
}

- (void)updateEnginesInScene:(UIScene*)scene {
  // Removes engines that are no longer in the scene or have been deallocated.
  //
  // This also handles the case where a FlutterEngine's view has been moved to a different scene.
  for (NSUInteger i = 0; i < self.engines.count; i++) {
    FlutterEngine* engine = (FlutterEngine*)[self.engines pointerAtIndex:i];

    // The engine may be nil if it has been deallocated.
    if (engine == nil) {
      [self.engines removePointerAtIndex:i];
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
      [self.engines removePointerAtIndex:i];
      i--;

      if ([actualScene.delegate conformsToProtocol:@protocol(FlutterSceneLifeCycleProvider)]) {
        id<FlutterSceneLifeCycleProvider> lifeCycleProvider =
            (id<FlutterSceneLifeCycleProvider>)actualScene.delegate;
        [lifeCycleProvider.sceneLifeCycleDelegate addFlutterEngine:engine];
      }
      continue;
    }
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

- (void)engine:(FlutterEngine*)engine receivedConnectNotificationFor:(UIScene*)scene {
  // Connection options may be nil if the notification was received before the
  // `scene:willConnectToSession:options:` event. In which case, we can wait for the actual event.
  [self addFlutterEngine:engine];
  if (self.connectionOptions != nil) {
    [self scene:scene willConnectToSession:scene.session options:self.connectionOptions];
  }
}

- (BOOL)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
                 options:(UISceneConnectionOptions*)connectionOptions {
  self.connectionOptions = connectionOptions;

  [self updateEnginesInScene:scene];

  BOOL consumedByPlugin = NO;
  for (FlutterEngine* engine in _engines.allObjects) {
    BOOL result = [engine.sceneLifeCycleDelegate scene:scene
                                  willConnectToSession:session
                                               options:connectionOptions];
    if (result) {
      consumedByPlugin = YES;
    }
  }
  return consumedByPlugin;
  // There is no application equivalent for this event and therefore no fallback.
}

- (void)sceneDidDisconnect:(UIScene*)scene {
  [self updateEnginesInScene:scene];
  for (FlutterEngine* engine in _engines.allObjects) {
    [engine.sceneLifeCycleDelegate sceneDidDisconnect:scene];
  }
  // There is no application equivalent for this event and therefore no fallback.
}

#pragma mark - Transitioning to the foreground

- (void)sceneWillEnterForeground:(UIScene*)scene {
  [self updateEnginesInScene:scene];
  for (FlutterEngine* engine in _engines.allObjects) {
    [engine.sceneLifeCycleDelegate sceneWillEnterForeground:scene];
  }
  [[self applicationLifeCycleDelegate] sceneWillEnterForegroundFallback];
}

- (void)sceneDidBecomeActive:(UIScene*)scene {
  [self updateEnginesInScene:scene];
  for (FlutterEngine* engine in _engines.allObjects) {
    [engine.sceneLifeCycleDelegate sceneDidBecomeActive:scene];
  }
  [[self applicationLifeCycleDelegate] sceneDidBecomeActiveFallback];
}

#pragma mark - Transitioning to the background

- (void)sceneWillResignActive:(UIScene*)scene {
  [self updateEnginesInScene:scene];
  for (FlutterEngine* engine in _engines.allObjects) {
    [engine.sceneLifeCycleDelegate sceneWillResignActive:scene];
  }
  [[self applicationLifeCycleDelegate] sceneWillResignActiveFallback];
}

- (void)sceneDidEnterBackground:(UIScene*)scene {
  [self updateEnginesInScene:scene];
  for (FlutterEngine* engine in _engines.allObjects) {
    [engine.sceneLifeCycleDelegate sceneDidEnterBackground:scene];
  }
  [[self applicationLifeCycleDelegate] sceneDidEnterBackgroundFallback];
}

#pragma mark - Opening URLs

- (BOOL)scene:(UIScene*)scene openURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts {
  [self updateEnginesInScene:scene];
  BOOL consumedByPlugin = NO;
  for (FlutterEngine* engine in _engines.allObjects) {
    BOOL result = [engine.sceneLifeCycleDelegate scene:scene openURLContexts:URLContexts];
    if (result) {
      consumedByPlugin = YES;
    }
  }
  if (!consumedByPlugin) {
    BOOL result = [[self applicationLifeCycleDelegate] sceneFallbackOpenURLContexts:URLContexts];
    if (result) {
      consumedByPlugin = YES;
    }
  }
  return consumedByPlugin;
}

#pragma mark - Continuing user activities

- (BOOL)scene:(UIScene*)scene continueUserActivity:(NSUserActivity*)userActivity {
  [self updateEnginesInScene:scene];
  BOOL consumedByPlugin = NO;
  for (FlutterEngine* engine in _engines.allObjects) {
    BOOL result = [engine.sceneLifeCycleDelegate scene:scene continueUserActivity:userActivity];
    if (result) {
      consumedByPlugin = YES;
    }
  }
  if (!consumedByPlugin) {
    BOOL result =
        [[self applicationLifeCycleDelegate] sceneFallbackContinueUserActivity:userActivity];
    if (result) {
      consumedByPlugin = YES;
    }
  }
  return consumedByPlugin;
}

#pragma mark - Saving the state of the scene

- (NSUserActivity*)stateRestorationActivityForScene:(UIScene*)scene {
  // Saves state per FlutterViewController.
  NSUserActivity* activity = scene.userActivity;
  if (!activity) {
    activity = [[NSUserActivity alloc] initWithActivityType:scene.session.configuration.name];
  }

  [self updateEnginesInScene:scene];
  for (FlutterEngine* engine in [_engines allObjects]) {
    UIViewController* vc = (UIViewController*)engine.viewController;
    NSString* restorationId = vc.restorationIdentifier;
    if (restorationId && restorationId.length > 0) {
      NSData* restorationData = [engine.restorationPlugin restorationData];
      if (restorationData) {
        int64_t stateDate = [self lastAppModificationTime];
        [activity addUserInfoEntriesFromDictionary:@{restorationId : restorationData}];
        [activity addUserInfoEntriesFromDictionary:@{
          kRestorationStateAppModificationKey : [NSNumber numberWithLongLong:stateDate]
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
  [self updateEnginesInScene:scene];
  for (FlutterEngine* engine in [_engines allObjects]) {
    UIViewController* vc = (UIViewController*)engine.viewController;
    NSString* restorationId = vc.restorationIdentifier;
    if (restorationId && restorationId.length > 0) {
      NSNumber* stateDateNumber = userInfo[kRestorationStateAppModificationKey];
      int64_t stateDate = 0;
      if (stateDateNumber && [stateDateNumber isKindOfClass:[NSNumber class]]) {
        stateDate = [stateDateNumber longLongValue];
      }
      if (self.lastAppModificationTime != stateDate) {
        // Don't restore state if the app has been re-installed since the state was last saved
        return;
      }
      NSData* restorationData = userInfo[restorationId];
      if ([restorationData isKindOfClass:[NSData class]]) {
        [engine.restorationPlugin setRestorationData:restorationData];
      }
    }
  }
}

- (int64_t)lastAppModificationTime {
  NSDate* fileDate;
  NSError* error = nil;
  [[[NSBundle mainBundle] executableURL] getResourceValue:&fileDate
                                                   forKey:NSURLContentModificationDateKey
                                                    error:&error];
  NSAssert(error == nil, @"Cannot obtain modification date of main bundle: %@", error);
  return [fileDate timeIntervalSince1970];
}

#pragma mark - Performing tasks

- (BOOL)windowScene:(UIWindowScene*)windowScene
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler {
  [self updateEnginesInScene:windowScene];

  BOOL consumedByPlugin = NO;
  for (FlutterEngine* engine in _engines.allObjects) {
    BOOL result = [engine.sceneLifeCycleDelegate windowScene:windowScene
                                performActionForShortcutItem:shortcutItem
                                           completionHandler:completionHandler];
    if (result) {
      consumedByPlugin = YES;
    }
  }
  if (!consumedByPlugin) {
    BOOL result = [[self applicationLifeCycleDelegate]
        sceneFallbackPerformActionForShortcutItem:shortcutItem
                                completionHandler:completionHandler];
    if (result) {
      consumedByPlugin = YES;
    }
  }
  return consumedByPlugin;
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
  BOOL consumedByPlugin = NO;
  for (NSObject<FlutterSceneLifeCycleDelegate>* delegate in _delegates.allObjects) {
    if ([delegate respondsToSelector:_cmd]) {
      // If this event has already been consumed by a plugin, send the event with nil options.
      if (consumedByPlugin) {
        [delegate scene:scene willConnectToSession:session options:nil];
        continue;
      } else if ([delegate scene:scene willConnectToSession:session options:connectionOptions]) {
        // Only allow one plugin to process this event.
        consumedByPlugin = YES;
      }
    }
  }
  return consumedByPlugin;
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
