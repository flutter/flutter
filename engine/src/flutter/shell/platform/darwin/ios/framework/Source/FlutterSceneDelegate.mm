// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterSceneDelegate.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterSceneLifeCycle.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterAppDelegate_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifeCycle_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSharedApplication.h"

FLUTTER_ASSERT_ARC

@interface FlutterSceneDelegate () <FlutterSceneLifeCycleProvider>
@end

@implementation FlutterSceneDelegate

@synthesize sceneLifeCycleDelegate = _sceneLifeCycleDelegate;

- (instancetype)init {
  if (self = [super init]) {
    _sceneLifeCycleDelegate = [[FlutterPluginSceneLifeCycleDelegate alloc] init];
  }
  return self;
}

#pragma mark - Connecting and disconnecting the scene

- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
                 options:(UISceneConnectionOptions*)connectionOptions {
  NSObject<UIApplicationDelegate>* appDelegate = FlutterSharedApplication.application.delegate;
  if ([appDelegate respondsToSelector:@selector(window)] && appDelegate.window.rootViewController) {
    NSLog(@"WARNING - The UIApplicationDelegate is setting up the UIWindow and "
          @"UIWindow.rootViewController at launch. This was deprecated after the "
          @"UISceneDelegate adoption. Setup logic should be moved to a UISceneDelegate.");
    // If this is not nil we are running into a case where someone is manually
    // performing root view controller setup in the UIApplicationDelegate.
    UIWindowScene* windowScene = (UIWindowScene*)scene;
    [self moveRootViewControllerFrom:appDelegate to:windowScene];
  }
  [self.sceneLifeCycleDelegate scene:scene willConnectToSession:session options:connectionOptions];
}

- (void)sceneDidDisconnect:(UIScene*)scene {
  [self.sceneLifeCycleDelegate sceneDidDisconnect:scene];
}

#pragma mark - Transitioning to the foreground

- (void)sceneWillEnterForeground:(UIScene*)scene {
  [self.sceneLifeCycleDelegate sceneWillEnterForeground:scene];
}

- (void)sceneDidBecomeActive:(UIScene*)scene {
  [self.sceneLifeCycleDelegate sceneDidBecomeActive:scene];
}

#pragma mark - Transitioning to the background

- (void)sceneWillResignActive:(UIScene*)scene {
  [self.sceneLifeCycleDelegate sceneWillResignActive:scene];
}

- (void)sceneDidEnterBackground:(UIScene*)scene {
  [self.sceneLifeCycleDelegate sceneDidEnterBackground:scene];
}

#pragma mark - Opening URLs

- (void)scene:(UIScene*)scene openURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts {
  [self.sceneLifeCycleDelegate scene:scene openURLContexts:URLContexts];
}

#pragma mark - Continuing user activities

- (void)scene:(UIScene*)scene continueUserActivity:(NSUserActivity*)userActivity {
  [self.sceneLifeCycleDelegate scene:scene continueUserActivity:userActivity];
}

#pragma mark - Saving the state of the scene

- (NSUserActivity*)stateRestorationActivityForScene:(UIScene*)scene {
  return [self.sceneLifeCycleDelegate stateRestorationActivityForScene:scene];
}

- (void)scene:(UIScene*)scene
    restoreInteractionStateWithUserActivity:(NSUserActivity*)stateRestorationActivity {
  [self.sceneLifeCycleDelegate scene:scene
      restoreInteractionStateWithUserActivity:stateRestorationActivity];
}

#pragma mark - Performing tasks

- (void)windowScene:(UIWindowScene*)windowScene
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler {
  [self.sceneLifeCycleDelegate windowScene:windowScene
              performActionForShortcutItem:shortcutItem
                         completionHandler:completionHandler];
}

#pragma mark - Helpers

- (BOOL)registerSceneLifeCycleWithFlutterEngine:(FlutterEngine*)engine {
  return [self.sceneLifeCycleDelegate registerSceneLifeCycleWithFlutterEngine:engine];
}

- (BOOL)unregisterSceneLifeCycleWithFlutterEngine:(FlutterEngine*)engine {
  return [self.sceneLifeCycleDelegate unregisterSceneLifeCycleWithFlutterEngine:engine];
}

- (void)moveRootViewControllerFrom:(NSObject<UIApplicationDelegate>*)appDelegate
                                to:(UIWindowScene*)windowScene {
  self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
  self.window.rootViewController = appDelegate.window.rootViewController;
  appDelegate.window = self.window;
  [self.window makeKeyAndVisible];
}
@end
