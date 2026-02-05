// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERVIEW_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERVIEW_INTERNAL_H_

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

@interface FlutterView ()

/**
 * Updates the wide gamut setting on the surface manager. Called when
 * the window moves to a screen with different gamut support.
 *
 * Must be called on the platform thread.
 */
- (void)setEnableWideGamut:(BOOL)enableWideGamut;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERVIEW_INTERNAL_H_
