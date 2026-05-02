// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_HEADERS_FLUTTERTEXTURE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_HEADERS_FLUTTERTEXTURE_H_

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

#import "FlutterMacros.h"

@protocol MTLEvent;

NS_ASSUME_NONNULL_BEGIN

FLUTTER_DARWIN_EXPORT
/**
 * Represents a texture that can be shared with Flutter.
 *
 * See also: https://github.com/flutter/plugins/tree/master/packages/camera
 */
@protocol FlutterTexture <NSObject>
/**
 * Copy the contents of the texture into a `CVPixelBuffer`.
 *
 * The type of the pixel buffer is one of the following:
 * - `kCVPixelFormatType_32BGRA`
 * - `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`
 * - `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange`
 */
- (CVPixelBufferRef _Nullable)copyPixelBuffer;

/**
 * Called when the texture is unregistered.
 *
 * Called on the raster thread.
 */
@optional

/**
 * Optional MTLEvent to synchronize the texture with Flutter rendering.
 * When provided, raster thread will wait for the event to be signalled
 * to provided value before using the texture.
 * After the raster thread is done with the texture, the event will be
 * signalled to value + 1.
 *
 * When MTLEvent is provided, the pixel buffer and event are requested
 * on subsequent frame, even if [FlutterTextureRegistry textureFrameAvailable]
 * is not called before.
 */
- (id<MTLEvent> _Nullable)copyEventWithValue:(uint64_t*)value;

- (void)onTextureUnregistered:(NSObject<FlutterTexture>*)texture;
@end

FLUTTER_DARWIN_EXPORT
/**
 * A collection of registered `FlutterTexture`'s.
 */
@protocol FlutterTextureRegistry <NSObject>
/**
 * Registers a `FlutterTexture` for usage in Flutter and returns an id that can be used to reference
 * that texture when calling into Flutter with channels. Textures must be registered on the
 * platform thread. On success returns the pointer to the registered texture, else returns 0.
 */
- (int64_t)registerTexture:(NSObject<FlutterTexture>*)texture;
/**
 * Notifies Flutter that the content of the previously registered texture has been updated.
 *
 * This will trigger a call to `-[FlutterTexture copyPixelBuffer]` on the raster thread.
 */
- (void)textureFrameAvailable:(int64_t)textureId;
/**
 * Unregisters a `FlutterTexture` that has previously regeistered with `registerTexture:`. Textures
 * must be unregistered on the platform thread.
 *
 * @param textureId The result that was previously returned from `registerTexture:`.
 */
- (void)unregisterTexture:(int64_t)textureId;
@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_HEADERS_FLUTTERTEXTURE_H_
