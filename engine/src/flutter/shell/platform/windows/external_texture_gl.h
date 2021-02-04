// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_EXTERNAL_TEXTURE_GL_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_EXTERNAL_TEXTURE_GL_H_

#include <stdint.h>

#include <memory>

#include "flutter/shell/platform/common/public/flutter_texture_registrar.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

typedef struct ExternalTextureGLState ExternalTextureGLState;

// An abstraction of an OpenGL texture.
class ExternalTextureGL {
 public:
  ExternalTextureGL(FlutterDesktopPixelBufferTextureCallback texture_callback,
                    void* user_data);

  virtual ~ExternalTextureGL();

  // Returns the unique id of this texture.
  int64_t texture_id() { return reinterpret_cast<int64_t>(this); }

  void MarkFrameAvailable();

  // Attempts to populate the specified |opengl_texture| with texture details
  // such as the name, width, height and the pixel format upon successfully
  // copying the buffer provided by |texture_callback_|. See |CopyPixelBuffer|.
  // Returns true on success or false if the pixel buffer could not be copied.
  bool PopulateTexture(size_t width,
                       size_t height,
                       FlutterOpenGLTexture* opengl_texture);

 private:
  // Attempts to copy the pixel buffer returned by |texture_callback_| to
  // OpenGL.
  // The |width| and |height| will be set to the actual bounds of the copied
  // pixel buffer.
  // Returns true on success or false if the pixel buffer returned
  // by |texture_callback_| was invalid.
  bool CopyPixelBuffer(size_t& width, size_t& height);

  std::unique_ptr<ExternalTextureGLState> state_;
  FlutterDesktopPixelBufferTextureCallback texture_callback_ = nullptr;
  void* user_data_ = nullptr;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_EXTERNAL_TEXTURE_GL_H_
