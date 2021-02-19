// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#import "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMacOSExternalTexture.h"

/**
 * Used to bridge FlutterTexture object and handle the texture copy request the
 * Flutter engine.
 */
@interface FlutterExternalTextureMetal : NSObject <FlutterMacOSExternalTexture>

/**
 * Initializes a texture adapter with |texture|.
 */
- (nonnull instancetype)initWithFlutterTexture:(nonnull id<FlutterTexture>)texture
                            darwinMetalContext:(nonnull FlutterDarwinContextMetal*)context;

/**
 * Accepts texture buffer copy request from the Flutter engine.
 * When the user side marks the textureID as available, the Flutter engine will
 * callback to this method and ask for populate the |metalTexture| object,
 * such as the texture type and the format of the pixel buffer and the texture object.
 */
- (BOOL)populateTexture:(nonnull FlutterMetalExternalTexture*)metalTexture;

@end
