// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_

#include "flutter/fml/memory/weak_ptr.h"

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterKeySecondaryResponder.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterKeyboardManager.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterRestorationPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterUIPressProxy.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewResponder.h"

namespace flutter {
class FlutterPlatformViewsController;
}

FLUTTER_DARWIN_EXPORT
extern NSNotificationName const FlutterViewControllerWillDealloc;

FLUTTER_DARWIN_EXPORT
extern NSNotificationName const FlutterViewControllerHideHomeIndicator;

FLUTTER_DARWIN_EXPORT
extern NSNotificationName const FlutterViewControllerShowHomeIndicator;

typedef NS_ENUM(NSInteger, FlutterKeyboardMode) {
  FlutterKeyboardModeHidden = 0,
  FlutterKeyboardModeDocked = 1,
  FlutterKeyboardModeFloating = 2,
};

typedef void (^FlutterKeyboardAnimationCallback)(fml::TimePoint);

@interface FlutterViewController () <FlutterViewResponder>

@property(class, nonatomic, readonly) BOOL accessibilityIsOnOffSwitchLabelsEnabled;
@property(nonatomic, readonly) BOOL isPresentingViewController;
@property(nonatomic, readonly) BOOL isVoiceOverRunning;
@property(nonatomic, retain) FlutterKeyboardManager* keyboardManager;

/**
 * @brief Whether the status bar is preferred hidden.
 *
 *        This overrides the |UIViewController:prefersStatusBarHidden|.
 *        This is ignored when `UIViewControllerBasedStatusBarAppearance` in info.plist
 *        of the app project is `false`.
 */
@property(nonatomic, assign, readwrite) BOOL prefersStatusBarHidden;

- (fml::WeakPtr<FlutterViewController>)getWeakPtr;
- (std::shared_ptr<flutter::FlutterPlatformViewsController>&)platformViewsController;
- (FlutterRestorationPlugin*)restorationPlugin;
// Send touches to the Flutter Engine while forcing the change type to be cancelled.
// The `phase`s in `touches` are ignored.
- (void)forceTouchesCancelled:(NSSet*)touches;

// Accepts keypress events, and then calls |nextAction| if the event was not
// handled.
- (void)handlePressEvent:(FlutterUIPressProxy*)press
              nextAction:(void (^)())nextAction API_AVAILABLE(ios(13.4));
- (void)addInternalPlugins;
- (void)deregisterNotifications;
- (int32_t)accessibilityFlags;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_
