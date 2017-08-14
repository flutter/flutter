// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/null_rasterizer.h"

namespace shell {

NullRasterizer::NullRasterizer() : weak_factory_(this) {}

void NullRasterizer::Setup(
    std::unique_ptr<Surface> surface_or_null,
    ftl::Closure rasterizer_continuation,
    ftl::AutoResetWaitableEvent* setup_completion_event) {
  surface_ = std::move(surface_or_null);
  rasterizer_continuation();
  setup_completion_event->Signal();
}

void NullRasterizer::Teardown(
    ftl::AutoResetWaitableEvent* teardown_completion_event) {
  if (surface_) {
    surface_.reset();
  }
  teardown_completion_event->Signal();
}

ftl::WeakPtr<Rasterizer> NullRasterizer::GetWeakRasterizerPtr() {
  return weak_factory_.GetWeakPtr();
}

flow::LayerTree* NullRasterizer::GetLastLayerTree() {
  return nullptr;
}

void NullRasterizer::Clear(SkColor color, const SkISize& size) {
  // Null rasterizer. Nothing to do.
}

void NullRasterizer::Draw(
    ftl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) {
  FTL_ALLOW_UNUSED_LOCAL(
      pipeline->Consume([](std::unique_ptr<flow::LayerTree>) {
        // Drop the layer tree on the floor. We only need the pipeline empty so
        // that frame requests are not deferred indefinitely due to
        // backpressure.
      }));
}

void NullRasterizer::AddNextFrameCallback(ftl::Closure nextFrameCallback) {
  // Null rasterizer. Nothing to do.
}

}  // namespace shell
