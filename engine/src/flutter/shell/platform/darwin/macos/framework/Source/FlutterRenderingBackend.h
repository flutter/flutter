// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

/**
 * Flutter on macOS currently supports both OpenGL and Metal rendering backends. This class provides
 * utilities for determining the rendering backend and the corresponging layer properties.
 */
@interface FlutterRenderingBackend : NSObject

/**
 * Returns YES if the engine is supposed to use Metal as the rendering backend. On macOS versions
 * >= 10.4 this is YES.
 */
+ (BOOL)renderUsingMetal;

@end
