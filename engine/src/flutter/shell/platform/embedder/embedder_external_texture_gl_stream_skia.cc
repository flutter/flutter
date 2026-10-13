// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_gl_stream_skia.h"

#include <GLES2/gl2.h>
#define GL_GLEXT_PROTOTYPES
#include <GLES2/gl2ext.h>

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/third_party/skia/include/core/SkColorSpace.h"
#include "flutter/third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "flutter/third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "flutter/third_party/skia/include/gpu/ganesh/SkImageGanesh.h"
#include "flutter/third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"

namespace flutter {

EmbedderExternalTextureGLStreamSkia::EmbedderExternalTextureGLStreamSkia(
    int64_t id,
    EmbedderOpenGLTextureStream stream)
    : EmbedderExternalTextureGLStream(id, stream) {}

EmbedderExternalTextureGLStreamSkia::~EmbedderExternalTextureGLStreamSkia() {
  if (texture_name_ != 0) {
    glDeleteTextures(1, &texture_name_);
  }
}

void EmbedderExternalTextureGLStreamSkia::ProcessFrame(PaintContext& context,
                                                       const SkRect& bounds) {
  if (state_ == AttachmentState::kUninitialized) {
    // Generate the texture handle.
    glGenTextures(1, &texture_name_);
    Attach(texture_name_);
  }
  FML_CHECK(state_ == AttachmentState::kAttached);

  // Updates the texture contents and transformation matrix.
  Update();

  GrGLTextureInfo textureInfo = {GL_TEXTURE_EXTERNAL_OES, texture_name_,
                                 GL_RGBA8_OES};
  auto backendTexture =
      GrBackendTextures::MakeGL(1, 1, skgpu::Mipmapped::kNo, textureInfo);
  dl_image_ = DlImageSkia::Make(SkImages::BorrowTextureFrom(
      context.gr_context, backendTexture, kTopLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, kPremul_SkAlphaType, nullptr));
}

void EmbedderExternalTextureGLStreamSkia::Detach() {
  EmbedderExternalTextureGLStream::Detach();
  // Detach will collect the texture handle.
  // See also: https://github.com/flutter/flutter/issues/152459
  texture_name_ = 0;
}

}  // namespace flutter
