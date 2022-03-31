// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMenuPlugin.h"

/**
 * Internal methods used in testing.
 */
@interface FlutterMenuPlugin ()

// Handles method calls received from the framework.
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

@end
