// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_SKIA_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_SKIA_H_

#include <GLES/gl.h>

#include <memory>

#include "flutter/shell/platform/embedder/embedder_external_texture_gl_stream.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Binds the surface texture to a Skia SkImage.
///
class EmbedderExternalTextureGLStreamSkia
    : public EmbedderExternalTextureGLStream {
 public:
  EmbedderExternalTextureGLStreamSkia(int64_t id,
                                      EmbedderOpenGLTextureStream stream);

  // |EmbedderExternalTextureGLStream|
  ~EmbedderExternalTextureGLStreamSkia() override;

 private:
  // |EmbedderExternalTextureGLStream|
  virtual void ProcessFrame(PaintContext& context,
                            const SkRect& bounds) override;

  // |EmbedderExternalTextureGLStream|
  virtual void Detach() override;

  GLuint texture_name_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalTextureGLStreamSkia);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_SKIA_H_
