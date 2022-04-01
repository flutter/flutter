// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_gl.h"

#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkAlphaType.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

EmbedderExternalTextureGL::EmbedderExternalTextureGL(
    int64_t texture_identifier,
    const ExternalTextureCallback& callback)
    : Texture(texture_identifier), external_texture_callback_(callback) {
  FML_DCHECK(external_texture_callback_);
}

EmbedderExternalTextureGL::~EmbedderExternalTextureGL() = default;

// |flutter::Texture|
void EmbedderExternalTextureGL::Paint(SkCanvas& canvas,
                                      const SkRect& bounds,
                                      bool freeze,
                                      GrDirectContext* context,
                                      const SkSamplingOptions& sampling,
                                      const SkPaint* paint) {
  if (last_image_ == nullptr) {
    last_image_ =
        ResolveTexture(Id(),                                           //
                       context,                                        //
                       SkISize::Make(bounds.width(), bounds.height())  //
        );
  }

  if (last_image_) {
    if (bounds != SkRect::Make(last_image_->bounds())) {
      canvas.drawImageRect(last_image_, bounds, sampling, paint);
    } else {
      canvas.drawImage(last_image_, bounds.x(), bounds.y(), sampling, paint);
    }
  }
}

sk_sp<SkImage> EmbedderExternalTextureGL::ResolveTexture(
    int64_t texture_id,
    GrDirectContext* context,
    const SkISize& size) {
  context->flushAndSubmit();
  context->resetContext(kAll_GrBackendState);
  std::unique_ptr<FlutterOpenGLTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture) {
    return nullptr;
  }

  GrGLTextureInfo gr_texture_info = {texture->target, texture->name,
                                     texture->format};

  size_t width = size.width();
  size_t height = size.height();

  if (texture->width != 0 && texture->height != 0) {
    width = texture->width;
    height = texture->height;
  }

  GrBackendTexture gr_backend_texture(width, height, GrMipMapped::kNo,
                                      gr_texture_info);
  SkImage::TextureReleaseProc release_proc = texture->destruction_callback;
  auto image =
      SkImage::MakeFromTexture(context,                   // context
                               gr_backend_texture,        // texture handle
                               kTopLeft_GrSurfaceOrigin,  // origin
                               kRGBA_8888_SkColorType,    // color type
                               kPremul_SkAlphaType,       // alpha type
                               nullptr,                   // colorspace
                               release_proc,       // texture release proc
                               texture->user_data  // texture release context
      );

  if (!image) {
    // In case Skia rejects the image, call the release proc so that
    // embedders can perform collection of intermediates.
    if (release_proc) {
      release_proc(texture->user_data);
    }
    FML_LOG(ERROR) << "Could not create external texture->";
    return nullptr;
  }

  return image;
}

// |flutter::Texture|
void EmbedderExternalTextureGL::OnGrContextCreated() {}

// |flutter::Texture|
void EmbedderExternalTextureGL::OnGrContextDestroyed() {}

// |flutter::Texture|
void EmbedderExternalTextureGL::MarkNewFrameAvailable() {
  last_image_ = nullptr;
}

// |flutter::Texture|
void EmbedderExternalTextureGL::OnTextureUnregistered() {}

}  // namespace flutter
