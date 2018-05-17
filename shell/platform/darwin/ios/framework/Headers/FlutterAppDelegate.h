// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERAPPDELEGATE_H_
#define FLUTTER_FLUTTERAPPDELEGATE_H_

#import <UIKit/UIKit.h>

#include "FlutterMacros.h"
#include "FlutterPlugin.h"

/**
 * UIApplicationDelegate subclass for simple apps that want default behavior.
 *
 * This class provides the following behaviors:
 *   * Status bar touches are forwarded to the key window's root view
 *     FlutterViewController, in order to trigger scroll to top.
 *   * Keeps the Flutter connection open in debug mode when the phone screen
 *     locks.
 *
 * App delegates for Flutter applications are *not* required to inherit from
 * this class. Developers of custom app delegate classes should copy and paste
 * code as necessary from FlutterAppDelegate.mm.
 */
FLUTTER_EXPORT
@interface FlutterAppDelegate : UIResponder<UIApplicationDelegate, FlutterPluginRegistry, FlutterAppLifeCycleProvider>

@property(strong, nonatomic) UIWindow* window;

@end

#endif  // FLUTTER_FLUTTERDARTPROJECT_H_
