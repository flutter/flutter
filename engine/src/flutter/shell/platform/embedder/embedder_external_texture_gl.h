// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_H_

#include "flutter/flow/texture.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

class EmbedderExternalTextureGL : public flutter::Texture {
 public:
  using ExternalTextureCallback =
      std::function<sk_sp<SkImage>(int64_t texture_identifier,
                                   GrDirectContext*,
                                   const SkISize&)>;

  EmbedderExternalTextureGL(int64_t texture_identifier,
                            const ExternalTextureCallback& callback);

  ~EmbedderExternalTextureGL();

 private:
  ExternalTextureCallback external_texture_callback_;
  sk_sp<SkImage> last_image_;

  // |flutter::Texture|
  void Paint(SkCanvas& canvas,
             const SkRect& bounds,
             bool freeze,
             GrDirectContext* context,
             SkFilterQuality filter_quality) override;

  // |flutter::Texture|
  void OnGrContextCreated() override;

  // |flutter::Texture|
  void OnGrContextDestroyed() override;

  // |flutter::Texture|
  void MarkNewFrameAvailable() override;

  // |flutter::Texture|
  void OnTextureUnregistered() override;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalTextureGL);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_GL_H_
