// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if defined(FLUTTER_FRAMEWORK)
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterMacros.h"
#else
#import "FlutterMacros.h"
#endif

/**
 * Protocol for views owned by FLEViewController to handle context changes, specifically relating to
 * OpenGL context changes.
 */
FLUTTER_EXPORT
@protocol FLEOpenGLContextHandling

/**
 * Sets the receiver as the current context object.
 */
- (void)makeCurrentContext;

/**
 * Called when the display is updated. In an NSOpenGLView this is best handled via a flushBuffer
 * call.
 */
- (void)onPresent;

@end
