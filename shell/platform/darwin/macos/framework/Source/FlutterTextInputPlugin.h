// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"

/**
 * A plugin to handle text input.
 *
 * Responsible for bridging the native macOS text input system with the Flutter framework text
 * editing classes, via system channels.
 *
 * This is not an FlutterPlugin since it needs access to FlutterViewController internals, so needs
 * to be managed differently.
 */
@interface FlutterTextInputPlugin : NSResponder

/**
 * Initializes a text input plugin that coordinates key event handling with |viewController|.
 */
- (instancetype)initWithViewController:(FlutterViewController*)viewController;

@end
