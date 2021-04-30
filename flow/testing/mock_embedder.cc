// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_embedder.h"

namespace flutter {
namespace testing {

MockViewEmbedder::MockViewEmbedder() = default;

MockViewEmbedder::~MockViewEmbedder() = default;

// |ExternalViewEmbedder|
SkCanvas* MockViewEmbedder::GetRootCanvas() {
  return nullptr;
}

// |ExternalViewEmbedder|
void MockViewEmbedder::CancelFrame() {}

// |ExternalViewEmbedder|
void MockViewEmbedder::BeginFrame(
    SkISize frame_size,
    GrDirectContext* context,
    double device_pixel_ratio,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {}

// |ExternalViewEmbedder|
void MockViewEmbedder::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<EmbeddedViewParams> params) {}

// |ExternalViewEmbedder|
std::vector<SkCanvas*> MockViewEmbedder::GetCurrentCanvases() {
  return std::vector<SkCanvas*>({});
}

// |ExternalViewEmbedder|
SkCanvas* MockViewEmbedder::CompositeEmbeddedView(int view_id) {
  return nullptr;
}

}  // namespace testing
}  // namespace flutter
