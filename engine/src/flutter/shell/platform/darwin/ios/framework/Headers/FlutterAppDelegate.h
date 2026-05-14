// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERAPPDELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERAPPDELEGATE_H_

#import <UIKit/UIKit.h>

#import "FlutterMacros.h"
#import "FlutterPlugin.h"

/**
 * `UIApplicationDelegate` subclass for simple apps that want default behavior.
 *
 * This class implements the following behaviors:
 *   * Status bar touches are forwarded to the key window's root view
 *     `FlutterViewController`, in order to trigger scroll to top.
 *   * Keeps the Flutter connection open in debug mode when the phone screen
 *     locks.
 *
 * App delegates for Flutter applications are *not* required to inherit from
 * this class. Developers of custom app delegate classes should copy and paste
 * code as necessary from FlutterAppDelegate.mm.
 */
FLUTTER_DARWIN_EXPORT
@interface FlutterAppDelegate
    : UIResponder <UIApplicationDelegate, FlutterPluginRegistry, FlutterAppLifeCycleProvider>

@property(nonatomic, strong, nullable) UIWindow* window;

/**
 * A user-assignable `FlutterPluginRegistrant` for deferred plugin registration.
 *
 * For applications adopting the `UISceneDelegate` lifecycle, the recommended approach is to update
 * the application's `UIApplicationDelegate` to conform to `FlutterImplicitEngineDelegate` and
 * perform plugin registration via the generated plugin registrant in the
 * `didInitializeImplicitFlutterEngine` callback.
 *
 * Alternatively, assigning a `FlutterPluginRegistrant` to this property allows Flutter to
 * automatically handle plugin registration when a `FlutterEngine` becomes available, avoiding
 * the need to implement delegate callbacks.
 *
 * The `FlutterAppDelegate` itself can be assigned to this property without creating a
 * retain cycle (e.g., `self.pluginRegistrant = self;`).
 *
 * @see |FlutterImplicitEngineDelegate|
 * @see https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
 */
@property(nonatomic, strong, nullable) NSObject<FlutterPluginRegistrant>* pluginRegistrant;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERAPPDELEGATE_H_
