// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_embedder.h"

namespace flutter {
namespace testing {

MockViewEmbedder::MockViewEmbedder() = default;

MockViewEmbedder::~MockViewEmbedder() = default;

void MockViewEmbedder::AddCanvas(SkCanvas* canvas) {
  contexts_.emplace_back(EmbedderPaintContext{canvas, nullptr});
}

void MockViewEmbedder::AddRecorder(DisplayListCanvasRecorder* recorder) {
  contexts_.emplace_back(
      EmbedderPaintContext{recorder, recorder->builder().get()});
}

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
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  prerolled_views_.emplace_back(view_id);
}

// |ExternalViewEmbedder|
std::vector<SkCanvas*> MockViewEmbedder::GetCurrentCanvases() {
  return std::vector<SkCanvas*>({});
}

// |ExternalViewEmbedder|
std::vector<DisplayListBuilder*> MockViewEmbedder::GetCurrentBuilders() {
  return std::vector<DisplayListBuilder*>({});
}

// |ExternalViewEmbedder|
EmbedderPaintContext MockViewEmbedder::CompositeEmbeddedView(int64_t view_id) {
  painted_views_.emplace_back(view_id);
  EmbedderPaintContext context = contexts_.front();
  contexts_.pop_front();
  return context;
}

}  // namespace testing
}  // namespace flutter
