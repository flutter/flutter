// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_IMPELLER_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/impeller/renderer/backend/gles/texture_gles.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_gl_stream.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Binds the surface texture to an Impeller texture.
///
class EmbedderExternalTextureGLStreamImpeller
    : public EmbedderExternalTextureGLStream {
 public:
  EmbedderExternalTextureGLStreamImpeller(
      const std::shared_ptr<impeller::ContextGLES>& context,
      int64_t id,
      EmbedderOpenGLTextureStream stream);

  // |EmbedderExternalTextureGLStream|
  ~EmbedderExternalTextureGLStreamImpeller() override;

 private:
  // |EmbedderExternalTextureGLStream|
  virtual void ProcessFrame(PaintContext& context,
                            const SkRect& bounds) override;

  // |EmbedderExternalTextureGLStream|
  virtual void Detach() override;

  const std::shared_ptr<impeller::ContextGLES> impeller_context_;
  std::shared_ptr<impeller::TextureGLES> texture_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalTextureGLStreamImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_STREAM_IMPELLER_H_
