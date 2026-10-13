// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_gl_stream_impeller.h"

#include "flutter/impeller/display_list/dl_image_impeller.h"

namespace flutter {

EmbedderExternalTextureGLStreamImpeller::
    EmbedderExternalTextureGLStreamImpeller(
        const std::shared_ptr<impeller::ContextGLES>& context,
        int64_t id,
        EmbedderOpenGLTextureStream stream)
    : EmbedderExternalTextureGLStream(id, stream), impeller_context_(context) {}

EmbedderExternalTextureGLStreamImpeller::
    ~EmbedderExternalTextureGLStreamImpeller() = default;

void EmbedderExternalTextureGLStreamImpeller::ProcessFrame(
    PaintContext& context,
    const SkRect& bounds) {
  if (state_ == AttachmentState::kUninitialized) {
    // Generate the texture handle.
    impeller::TextureDescriptor desc;
    desc.type = impeller::TextureType::kTextureExternalOES;
    desc.storage_mode = impeller::StorageMode::kDevicePrivate;
    desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
    desc.size = {1, 1};
    desc.mip_count = 1;
    texture_ = std::make_shared<impeller::TextureGLES>(
        impeller_context_->GetReactor(), desc);
    // The contents will be initialized later in the call to `Attach` instead of
    // by Impeller.
    texture_->MarkContentsInitialized();
    auto maybe_handle = texture_->GetGLHandle();
    if (!maybe_handle.has_value()) {
      FML_LOG(ERROR) << "Could not get GL handle from impeller::TextureGLES!";
      return;
    }
    Attach(maybe_handle.value());
  }
  FML_CHECK(state_ == AttachmentState::kAttached);

  // Updates the texture contents and transformation matrix.
  Update();

  dl_image_ = impeller::DlImageImpeller::Make(texture_);
}

void EmbedderExternalTextureGLStreamImpeller::Detach() {
  EmbedderExternalTextureGLStream::Detach();
  // Detach will collect the texture handle.
  // See also: https://github.com/flutter/flutter/issues/152459
  texture_->Leak();
  texture_.reset();
}

}  // namespace flutter
