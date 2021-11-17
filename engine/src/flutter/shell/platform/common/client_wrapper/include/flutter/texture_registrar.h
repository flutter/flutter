// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_TEXTURE_REGISTRAR_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_TEXTURE_REGISTRAR_H_

#include <flutter_texture_registrar.h>

#include <cstdint>
#include <functional>
#include <memory>
#include <variant>

namespace flutter {

// A pixel buffer texture.
class PixelBufferTexture {
 public:
  // A callback used for retrieving pixel buffers.
  typedef std::function<const FlutterDesktopPixelBuffer*(size_t width,
                                                         size_t height)>
      CopyBufferCallback;

  // Creates a pixel buffer texture that uses the provided |copy_buffer_cb| to
  // retrieve the buffer.
  // As the callback is usually invoked from the render thread, the callee must
  // take care of proper synchronization. It also needs to be ensured that the
  // returned buffer isn't released prior to unregistering this texture.
  explicit PixelBufferTexture(CopyBufferCallback copy_buffer_callback)
      : copy_buffer_callback_(copy_buffer_callback) {}

  // Returns the callback-provided FlutterDesktopPixelBuffer that contains the
  // actual pixel data. The intended surface size is specified by |width| and
  // |height|.
  const FlutterDesktopPixelBuffer* CopyPixelBuffer(size_t width,
                                                   size_t height) const {
    return copy_buffer_callback_(width, height);
  }

 private:
  const CopyBufferCallback copy_buffer_callback_;
};

// The available texture variants.
// Only PixelBufferTexture is currently implemented.
// Other variants are expected to be added in the future.
typedef std::variant<PixelBufferTexture> TextureVariant;

// An object keeping track of external textures.
//
// Thread safety:
// It's safe to call the member methods from any thread.
class TextureRegistrar {
 public:
  virtual ~TextureRegistrar() = default;

  // Registers a |texture| object and returns the ID for that texture.
  virtual int64_t RegisterTexture(TextureVariant* texture) = 0;

  // Notifies the flutter engine that the texture object corresponding
  // to |texure_id| needs to render a new frame.
  //
  // For PixelBufferTextures, this will effectively make the engine invoke
  // the callback that was provided upon creating the texture.
  virtual bool MarkTextureFrameAvailable(int64_t texture_id) = 0;

  // Unregisters an existing Texture object.
  // Textures must not be unregistered while they're in use.
  virtual bool UnregisterTexture(int64_t texture_id) = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_TEXTURE_REGISTRAR_H_
