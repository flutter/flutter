// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_hb.h"

#include <utility>

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkAlphaType.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {

EmbedderExternalTextureHB::EmbedderExternalTextureHB(
    int64_t texture_identifier,
    ExternalTextureCallback callback)
    : Texture(texture_identifier),
      external_texture_callback_(std::move(callback)) {
  FML_DCHECK(external_texture_callback_);
}

EmbedderExternalTextureHB::~EmbedderExternalTextureHB() {
  TRACE_EVENT0("flutter",
               "EmbedderExternalTextureHB::~EmbedderExternalTextureHB");
  ReleaseLatestFrame();
}

void EmbedderExternalTextureHB::Paint(PaintContext& context,
                                      const DlRect& bounds,
                                      bool freeze,
                                      const DlImageSampling sampling) {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::Paint");
  if (!freeze && (has_new_frame_ || last_image_ == nullptr)) {
    sk_sp<DlImage> new_image =
        ResolveTexture(Id(), context.gr_context, context.aiks_context,
                       SkISize::Make(bounds.GetWidth(), bounds.GetHeight()));
    if (new_image) {
      last_image_ = std::move(new_image);
    }
    has_new_frame_ = false;
  }

  DlCanvas* canvas = context.canvas;
  const DlPaint* paint = context.paint;

  if (last_image_ && canvas) {
    DlRect image_bounds = DlRect::Make(last_image_->GetBounds());
    if (bounds != image_bounds) {
      canvas->DrawImageRect(last_image_, image_bounds, bounds, sampling, paint);
    } else {
      canvas->DrawImage(last_image_, bounds.GetOrigin(), sampling, paint);
    }
  }
}

sk_sp<DlImage> EmbedderExternalTextureHB::ResolveTexture(
    int64_t texture_id,
    GrDirectContext* context,
    impeller::AiksContext* aiks_context,
    const SkISize& size) {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::ResolveTexture");

  std::unique_ptr<FlutterHardwareBufferExternalTexture> texture =
      external_texture_callback_(texture_id, size.width(), size.height());

  if (!texture) {
    return nullptr;
  }

  ReleaseLatestFrame();
  last_texture_frame_ = std::move(texture);

  size_t width = last_texture_frame_->width != 0 ? last_texture_frame_->width
                                                 : size.width();
  size_t height = last_texture_frame_->height != 0 ? last_texture_frame_->height
                                                   : size.height();

  if (width == 0 || height == 0) {
    width = 1;
    height = 1;
  }

  auto info = SkImageInfo::Make(width, height, kRGBA_8888_SkColorType,
                                kPremul_SkAlphaType);
  auto sk_surface = SkSurfaces::Raster(info);
  if (sk_surface) {
    return DlImageSkia::Make(sk_surface->makeImageSnapshot());
  }

  return nullptr;
}

void EmbedderExternalTextureHB::ReleaseLatestFrame() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::ReleaseLatestFrame");
  if (last_texture_frame_) {
    if (last_texture_frame_->destruction_callback) {
      TRACE_EVENT0("flutter",
                   "HardwareBufferExternalTextureDestructionCallback");
      last_texture_frame_->destruction_callback(last_texture_frame_->user_data);
    }
    last_texture_frame_.reset();
  }
  last_image_ = nullptr;
}

void EmbedderExternalTextureHB::OnGrContextCreated() {}

void EmbedderExternalTextureHB::OnGrContextDestroyed() {}

void EmbedderExternalTextureHB::MarkNewFrameAvailable() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::MarkNewFrameAvailable");
  has_new_frame_ = true;
}

void EmbedderExternalTextureHB::OnTextureUnregistered() {
  TRACE_EVENT0("flutter", "EmbedderExternalTextureHB::OnTextureUnregistered");
  ReleaseLatestFrame();
}

}  // namespace flutter
