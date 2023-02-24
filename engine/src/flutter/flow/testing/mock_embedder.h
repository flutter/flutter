// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_TESTING_MOCK_EMBEDDER_H_
#define FLOW_TESTING_MOCK_EMBEDDER_H_

#include "flutter/flow/embedded_views.h"

namespace flutter {
namespace testing {

class MockViewEmbedder : public ExternalViewEmbedder {
 public:
  MockViewEmbedder();

  ~MockViewEmbedder();

  void AddCanvas(DlCanvas* canvas);

  // |ExternalViewEmbedder|
  DlCanvas* GetRootCanvas() override;

  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void BeginFrame(
      SkISize frame_size,
      GrDirectContext* context,
      double device_pixel_ratio,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(
      int64_t view_id,
      std::unique_ptr<EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  DlCanvas* CompositeEmbeddedView(int64_t view_id) override;

  std::vector<int64_t> prerolled_views() const { return prerolled_views_; }
  std::vector<int64_t> painted_views() const { return painted_views_; }

 private:
  std::deque<DlCanvas*> contexts_;
  std::vector<int64_t> prerolled_views_;
  std::vector<int64_t> painted_views_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLOW_TESTING_MOCK_EMBEDDER_H_
