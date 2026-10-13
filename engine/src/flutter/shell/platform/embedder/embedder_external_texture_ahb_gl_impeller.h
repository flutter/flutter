// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_AHB_GL_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_AHB_GL_IMPELLER_H_

#include <memory>
#include <optional>

#include "flutter/fml/macros.h"
#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_ahb_gl.h"

namespace flutter {

class EmbedderExternalTextureAHBGLImpeller
    : public EmbedderExternalTextureAHBGL {
 public:
  EmbedderExternalTextureAHBGLImpeller(
      const std::shared_ptr<impeller::ContextGLES>& context,
      int64_t id,
      EmbedderAndroidHardwareBufferSource source);

 private:
  // |EmbedderExternalTextureAHB|
  void Attach(PaintContext& context) override;

  // |EmbedderExternalTextureAHB|
  void Detach() override;

  // |EmbedderExternalTextureAHBGL|
  sk_sp<flutter::DlImage> CreateDlImage(
      PaintContext& context,
      const SkRect& bounds,
      std::optional<HardwareBufferKey> id,
      impeller::UniqueEGLImageKHR&& egl_image) override;

  const std::shared_ptr<impeller::ContextGLES> impeller_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalTextureAHBGLImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_TEXTURE_AHB_GL_IMPELLER_H_
