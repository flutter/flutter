// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"

/**
 * A plugin to handle mouse cursor.
 *
 * Responsible for bridging the native macOS mouse cursor system with the
 * Flutter framework mouse cursor classes, via system channels.
 */
@interface FlutterMouseCursorPlugin : NSObject <FlutterPlugin>

@end
