// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_PUBLIC_FLUTTER_TEXTURE_REGISTRAR_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_PUBLIC_FLUTTER_TEXTURE_REGISTRAR_H_

#include <stddef.h>
#include <stdint.h>

#include "flutter_export.h"

#if defined(__cplusplus)
extern "C" {
#endif

struct FlutterDesktopTextureRegistrar;
// Opaque reference to a texture registrar.
typedef struct FlutterDesktopTextureRegistrar*
    FlutterDesktopTextureRegistrarRef;

// Possible values for the type specified in FlutterDesktopTextureInfo.
// Additional types may be added in the future.
typedef enum {
  // A Pixel buffer-based texture.
  kFlutterDesktopPixelBufferTexture
} FlutterDesktopTextureType;

// An image buffer object.
typedef struct {
  // The pixel data buffer.
  const uint8_t* buffer;
  // Width of the pixel buffer.
  size_t width;
  // Height of the pixel buffer.
  size_t height;
  // An optional callback that gets invoked when the |buffer| can be released.
  void (*release_callback)(void* release_context);
  // Opaque data passed to |release_callback|.
  void* release_context;
} FlutterDesktopPixelBuffer;

// The pixel buffer copy callback definition provided to
// the Flutter engine to copy the texture.
// It is invoked with the intended surface size specified by |width| and
// |height| and the |user_data| held by FlutterDesktopPixelBufferTextureConfig.
//
// As this is usually called from the render thread, the callee must take
// care of proper synchronization. It also needs to be ensured that the
// returned FlutterDesktopPixelBuffer isn't released prior to unregistering
// the corresponding texture.
typedef const FlutterDesktopPixelBuffer* (
    *FlutterDesktopPixelBufferTextureCallback)(size_t width,
                                               size_t height,
                                               void* user_data);

// An object used to configure pixel buffer textures.
typedef struct {
  // The callback used by the engine to copy the pixel buffer object.
  FlutterDesktopPixelBufferTextureCallback callback;
  // Opaque data that will get passed to the provided |callback|.
  void* user_data;
} FlutterDesktopPixelBufferTextureConfig;

typedef struct {
  FlutterDesktopTextureType type;
  union {
    FlutterDesktopPixelBufferTextureConfig pixel_buffer_config;
  };
} FlutterDesktopTextureInfo;

// Registers a new texture with the Flutter engine and returns the texture ID.
// This function can be called from any thread.
FLUTTER_EXPORT int64_t FlutterDesktopTextureRegistrarRegisterExternalTexture(
    FlutterDesktopTextureRegistrarRef texture_registrar,
    const FlutterDesktopTextureInfo* info);

// Unregisters an existing texture from the Flutter engine for a |texture_id|.
// Returns true on success or false if the specified texture doesn't exist.
// This function can be called from any thread.
// However, textures must not be unregistered while they're in use.
FLUTTER_EXPORT bool FlutterDesktopTextureRegistrarUnregisterExternalTexture(
    FlutterDesktopTextureRegistrarRef texture_registrar,
    int64_t texture_id);

// Marks that a new texture frame is available for a given |texture_id|.
// Returns true on success or false if the specified texture doesn't exist.
// This function can be called from any thread.
FLUTTER_EXPORT bool
FlutterDesktopTextureRegistrarMarkExternalTextureFrameAvailable(
    FlutterDesktopTextureRegistrarRef texture_registrar,
    int64_t texture_id);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_PUBLIC_FLUTTER_TEXTURE_REGISTRAR_H_
