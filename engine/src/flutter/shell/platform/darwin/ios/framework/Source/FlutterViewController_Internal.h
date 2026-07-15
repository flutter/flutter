// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

#import "flutter/shell/platform/darwin/ios/InternalFlutterSwift/InternalFlutterSwift.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterKeySecondaryResponder.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterKeyboardInsetManager.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterKeyboardManager.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewsController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterRestorationPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewResponder.h"

namespace flutter {
class PlatformViewsController;
}

FLUTTER_DARWIN_EXPORT
// NOLINTNEXTLINE(readability-identifier-naming)
extern NSNotificationName const FlutterViewControllerWillDealloc;

FLUTTER_DARWIN_EXPORT
// NOLINTNEXTLINE(readability-identifier-naming)
extern NSNotificationName const FlutterViewControllerHideHomeIndicator;

FLUTTER_DARWIN_EXPORT
// NOLINTNEXTLINE(readability-identifier-naming)
extern NSNotificationName const FlutterViewControllerShowHomeIndicator;

typedef NS_ENUM(NSInteger, FlutterKeyboardMode) {
  // NOLINTBEGIN(readability-identifier-naming)
  FlutterKeyboardModeHidden = 0,
  FlutterKeyboardModeDocked = 1,
  FlutterKeyboardModeFloating = 2,
  // NOLINTEND(readability-identifier-naming)
};

typedef void (^FlutterKeyboardAnimationCallback)(NSTimeInterval);

@interface FlutterViewController () <FlutterViewResponder>

@property(nonatomic, readonly) BOOL isPresentingViewController;
@property(nonatomic, readonly) BOOL isVoiceOverRunning;
@property(nonatomic, strong) FlutterKeyboardManager* keyboardManager;
@property(nonatomic, strong) FlutterKeyboardInsetManager* keyboardInsetManager;
@property(nonatomic, readwrite) NSString* applicationLocale;

/**
 * @brief Whether the status bar is preferred hidden.
 *
 *        This overrides the |UIViewController:prefersStatusBarHidden|.
 *        This is ignored when `UIViewControllerBasedStatusBarAppearance` in info.plist
 *        of the app project is `false`.
 */
@property(nonatomic, assign, readwrite) BOOL prefersStatusBarHidden;

@property(nonatomic, readonly) FlutterPlatformViewsController* platformViewsController;

@property(nonatomic, strong) FlutterAccessibilityFeatures* accessibilityFeatures;

- (FlutterRestorationPlugin*)restorationPlugin;
- (FlutterTextInputPlugin*)textInputPlugin;

// Accepts keypress events, and then calls |nextAction| if the event was not
// handled.
- (void)handlePressEvent:(FlutterUIPressProxy*)press
              nextAction:(void (^)())nextAction API_AVAILABLE(ios(13.4));
- (void)addInternalPlugins;
- (void)deregisterNotifications;

- (BOOL)supportsShowingSystemContextMenu;
- (BOOL)stateIsActive;
- (BOOL)stateIsBackground;
- (void)setupViewIdentifier:(FlutterViewIdentifier)viewIdentifier;

/**
 * Determines whether a UIScene notification should be handled by this view controller.
 *
 * In multi-scene environments (such as iPadOS split view, macOS Catalyst multi-window, or App
 * Extensions), multiple UIWindowScene instances can exist in the same process space. Because the
 * scene observers register to listen for all targets, they may receive lifecycle notifications
 * from unrelated auxiliary or secondary scenes.
 *
 * @param notification The UIScene notification containing the transitioning UIScene in its object.
 * @return YES if the notification matches this view controller's scene context.
 *         NO if it originates from an unrelated scene and should be ignored.
 */
- (BOOL)shouldHandleSceneNotification:(NSNotification*)notification API_AVAILABLE(ios(13.0));
@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_
