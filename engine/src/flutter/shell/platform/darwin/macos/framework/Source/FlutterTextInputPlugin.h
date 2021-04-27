// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeySecondaryResponder.h"

/**
 * A plugin to handle text input.
 *
 * Responsible for bridging the native macOS text input system with the Flutter framework text
 * editing classes, via system channels.
 *
 * This is not an FlutterPlugin since it needs access to FlutterViewController internals, so needs
 * to be managed differently.
 */
@interface FlutterTextInputPlugin : NSObject <FlutterKeySecondaryResponder>

/**
 * Initializes a text input plugin that coordinates key event handling with |viewController|.
 */
- (instancetype)initWithViewController:(FlutterViewController*)viewController;

@end

// Private methods made visible for testing
@interface FlutterTextInputPlugin (TestMethods)
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;
- (NSRect)firstRectForCharacterRange:(NSRange)range actualRange:(NSRangePointer)actualRange;
@end
