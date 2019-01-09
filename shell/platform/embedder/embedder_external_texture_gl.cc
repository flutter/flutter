// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_gl.h"

#include "flutter/fml/logging.h"

namespace shell {

EmbedderExternalTextureGL::EmbedderExternalTextureGL(
    int64_t texture_identifier,
    ExternalTextureCallback callback)
    : Texture(texture_identifier), external_texture_callback_(callback) {
  FML_DCHECK(external_texture_callback_);
}

EmbedderExternalTextureGL::~EmbedderExternalTextureGL() = default;

// |flow::Texture|
void EmbedderExternalTextureGL::Paint(SkCanvas& canvas,
                                      const SkRect& bounds,
                                      bool freeze) {
  if (auto image = external_texture_callback_(
          Id(),                                           //
          canvas.getGrContext(),                          //
          SkISize::Make(bounds.width(), bounds.height())  //
          )) {
    last_image_ = image;
  }

  if (last_image_) {
    canvas.drawImage(last_image_, bounds.x(), bounds.y());
  }
}

// |flow::Texture|
void EmbedderExternalTextureGL::OnGrContextCreated() {}

// |flow::Texture|
void EmbedderExternalTextureGL::OnGrContextDestroyed() {}

// |flow::Texture|
void EmbedderExternalTextureGL::MarkNewFrameAvailable() {}

}  // namespace shell
