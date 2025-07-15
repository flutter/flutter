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
 * The `FlutterPluginRegistrant` that will be used when FlutterViewControllers
 * are instantiated from nibs.
 *
 * The `FlutterAppDelegate` itself can be passed in without creating a retain
 * cycle.
 *
 * This was introduced to help users migrate code from the FlutterAppDelegate
 * when UISceneDelegate was adopted. Using
 * FlutterViewController.pluginRegistrant should be preferred since it doesn't
 * rely on the FlutterAppDelegate.
 */
@property(nonatomic, strong, nullable) NSObject<FlutterPluginRegistrant>* pluginRegistrant;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERAPPDELEGATE_H_
