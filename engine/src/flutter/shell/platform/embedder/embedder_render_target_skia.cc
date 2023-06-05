// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_render_target_skia.h"

#include "flutter/fml/logging.h"

namespace flutter {

EmbedderRenderTargetSkia::EmbedderRenderTargetSkia(
    FlutterBackingStore backing_store,
    sk_sp<SkSurface> render_surface,
    fml::closure on_release)
    : EmbedderRenderTarget(backing_store, std::move(on_release)),
      render_surface_(std::move(render_surface)) {
  FML_DCHECK(render_surface_);
}

EmbedderRenderTargetSkia::~EmbedderRenderTargetSkia() = default;

sk_sp<SkSurface> EmbedderRenderTargetSkia::GetSkiaSurface() const {
  return render_surface_;
}

impeller::RenderTarget* EmbedderRenderTargetSkia::GetImpellerRenderTarget()
    const {
  return nullptr;
}

std::shared_ptr<impeller::AiksContext>
EmbedderRenderTargetSkia::GetAiksContext() const {
  return nullptr;
}

SkISize EmbedderRenderTargetSkia::GetRenderTargetSize() const {
  return SkISize::Make(render_surface_->width(), render_surface_->height());
}

}  // namespace flutter
