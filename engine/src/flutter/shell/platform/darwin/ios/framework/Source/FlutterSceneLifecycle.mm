// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifecycle.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

@interface FlutterPluginSceneLifeCycleDelegate ()

/**
 * An array of weak pointers to `FlutterEngine`s that have views within this scene.
 *
 * This array is lazily cleaned up. `updateEnginesInScene:` should be called before use to ensure it
 * is up-to-date.
 */
@property(nonatomic, strong) NSPointerArray* engines;
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
    UIWindowScene* engineScene = engine.viewController.view.window.windowScene;
    if (engineScene != nil && engineScene != scene) {
      [self.engines removePointerAtIndex:i];
      i--;

      if ([engineScene.delegate conformsToProtocol:@protocol(FlutterSceneLifeCycleProvider)]) {
        id<FlutterSceneLifeCycleProvider> lifeCycleProvider =
            (id<FlutterSceneLifeCycleProvider>)engineScene.delegate;
        [lifeCycleProvider.sceneLifeCycleDelegate addFlutterEngine:engine];
      }
      continue;
    }
  }
}
@end
