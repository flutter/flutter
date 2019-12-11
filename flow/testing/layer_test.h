// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_TESTING_LAYER_TEST_H_
#define FLOW_TESTING_LAYER_TEST_H_

#include "flutter/flow/layers/layer.h"

#include <optional>
#include <utility>

#include "flutter/fml/macros.h"
#include "flutter/testing/canvas_test.h"
#include "flutter/testing/mock_canvas.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/utils/SkNWayCanvas.h"

namespace flutter {
namespace testing {

// This fixture allows generating tests which can |Paint()| and |Preroll()|
// |Layer|'s.
// |LayerTest| is a default implementation based on |::testing::Test|.
//
// |BaseT| should be the base test type, such as |::testing::Test| below.
template <typename BaseT>
class LayerTestBase : public CanvasTestBase<BaseT> {
  using TestT = CanvasTestBase<BaseT>;

 public:
  LayerTestBase()
      : preroll_context_({
            nullptr, /* raster_cache */
            nullptr, /* gr_context */
            nullptr, /* external_view_embedder */
            mutators_stack_, TestT::mock_canvas().imageInfo().colorSpace(),
            kGiantRect, /* cull_rect */
            false,      /* layer reads from surface */
            raster_time_, ui_time_, texture_registry_,
            false,  /* checkerboard_offscreen_layers */
            100.0f, /* frame_physical_depth */
            1.0f,   /* frame_device_pixel_ratio */
            0.0f,   /* total_elevation */
            false,  /* has_platform_view */
        }),
        paint_context_({
            TestT::mock_canvas().internal_canvas(), /* internal_nodes_canvas */
            &TestT::mock_canvas(),                  /* leaf_nodes_canvas */
            nullptr,                                /* gr_context */
            nullptr,                                /* external_view_embedder */
            raster_time_, ui_time_, texture_registry_,
            nullptr, /* raster_cache */
            false,   /* checkerboard_offscreen_layers */
            100.0f,  /* frame_physical_depth */
            1.0f,    /* frame_device_pixel_ratio */
        }) {}

  TextureRegistry& texture_regitry() { return texture_registry_; }
  PrerollContext* preroll_context() { return &preroll_context_; }
  Layer::PaintContext& paint_context() { return paint_context_; }

 private:
  Stopwatch raster_time_;
  Stopwatch ui_time_;
  MutatorsStack mutators_stack_;
  TextureRegistry texture_registry_;

  PrerollContext preroll_context_;
  Layer::PaintContext paint_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(LayerTestBase);
};
using LayerTest = LayerTestBase<::testing::Test>;

}  // namespace testing
}  // namespace flutter

#endif  // FLOW_TESTING_LAYER_TEST_H_
