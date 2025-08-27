// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterSceneDelegate.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterAppDelegate_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSharedApplication.h"

FLUTTER_ASSERT_ARC

@implementation FlutterSceneDelegate

- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
                 options:(UISceneConnectionOptions*)connectionOptions {
  NSObject<UIApplicationDelegate>* appDelegate = FlutterSharedApplication.application.delegate;
  if (appDelegate.window.rootViewController) {
    NSLog(@"WARNING - The UIApplicationDelegate is setting up the UIWindow and "
          @"UIWindow.rootViewController at launch. This was deprecated after the "
          @"UISceneDelegate adoption. Setup logic should be moved to a UISceneDelegate.");
    // If this is not nil we are running into a case where someone is manually
    // performing root view controller setup in the UIApplicationDelegate.
    UIWindowScene* windowScene = (UIWindowScene*)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = appDelegate.window.rootViewController;
    appDelegate.window = self.window;
    [self.window makeKeyAndVisible];
  }
}

- (void)windowScene:(UIWindowScene*)windowScene
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler {
  id appDelegate = FlutterSharedApplication.application.delegate;
  if ([appDelegate respondsToSelector:@selector(lifeCycleDelegate)]) {
    FlutterPluginAppLifeCycleDelegate* lifeCycleDelegate = [appDelegate lifeCycleDelegate];
    [lifeCycleDelegate application:FlutterSharedApplication.application
        performActionForShortcutItem:shortcutItem
                   completionHandler:completionHandler];
  }
}

static NSDictionary<UIApplicationOpenURLOptionsKey, id>* ConvertOptions(
    UISceneOpenURLOptions* options) {
  if (@available(iOS 14.5, *)) {
    return @{
      UIApplicationOpenURLOptionsSourceApplicationKey : options.sourceApplication
          ? options.sourceApplication
          : [NSNull null],
      UIApplicationOpenURLOptionsAnnotationKey : options.annotation ? options.annotation
                                                                    : [NSNull null],
      UIApplicationOpenURLOptionsOpenInPlaceKey : @(options.openInPlace),
      UIApplicationOpenURLOptionsEventAttributionKey : options.eventAttribution
          ? options.eventAttribution
          : [NSNull null],
    };
  } else {
    return @{
      UIApplicationOpenURLOptionsSourceApplicationKey : options.sourceApplication
          ? options.sourceApplication
          : [NSNull null],
      UIApplicationOpenURLOptionsAnnotationKey : options.annotation ? options.annotation
                                                                    : [NSNull null],
      UIApplicationOpenURLOptionsOpenInPlaceKey : @(options.openInPlace),
    };
  }
}

- (void)scene:(UIScene*)scene openURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts {
  id appDelegate = FlutterSharedApplication.application.delegate;
  if ([appDelegate respondsToSelector:@selector(lifeCycleDelegate)]) {
    FlutterPluginAppLifeCycleDelegate* lifeCycleDelegate = [appDelegate lifeCycleDelegate];
    for (UIOpenURLContext* context in URLContexts) {
      [lifeCycleDelegate application:FlutterSharedApplication.application
                             openURL:context.URL
                             options:ConvertOptions(context.options)];
    };
  }
}

@end
