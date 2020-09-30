// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_TESTING_LAYER_TEST_H_
#define FLOW_TESTING_LAYER_TEST_H_

#include "flutter/flow/layers/layer.h"

#include <optional>
#include <utility>

#include "flutter/flow/testing/mock_raster_cache.h"
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
// By default the preroll and paint contexts will not use a raster cache.
// If a test needs to verify the proper operation of a layer in the presence
// of a raster cache then a number of options can be enabled by using the
// methods |LayerTestBase::use_null_raster_cache()|,
// |LayerTestBase::use_mock_raster_cache()| or
// |LayerTestBase::use_skia_raster_cache()|
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
            false, /* checkerboard_offscreen_layers */
            1.0f,  /* frame_device_pixel_ratio */
            false, /* has_platform_view */
        }),
        paint_context_({
            TestT::mock_canvas().internal_canvas(), /* internal_nodes_canvas */
            &TestT::mock_canvas(),                  /* leaf_nodes_canvas */
            nullptr,                                /* gr_context */
            nullptr,                                /* external_view_embedder */
            raster_time_, ui_time_, texture_registry_,
            nullptr, /* raster_cache */
            false,   /* checkerboard_offscreen_layers */
            1.0f,    /* frame_device_pixel_ratio */
        }),
        check_board_context_({
            TestT::mock_canvas().internal_canvas(), /* internal_nodes_canvas */
            &TestT::mock_canvas(),                  /* leaf_nodes_canvas */
            nullptr,                                /* gr_context */
            nullptr,                                /* external_view_embedder */
            raster_time_, ui_time_, texture_registry_,
            nullptr, /* raster_cache */
            true,    /* checkerboard_offscreen_layers */
            1.0f,    /* frame_device_pixel_ratio */
        }) {
    use_null_raster_cache();
  }

  /**
   * @brief Use no raster cache in the preroll_context() and
   * paint_context() structures.
   *
   * This method must be called before using the preroll_context() and
   * paint_context() structures in calls to the Layer::Preroll() and
   * Layer::Paint() methods. This is the default mode of operation.
   *
   * @see use_mock_raster_cache()
   * @see use_skia_raster_cache()
   */
  void use_null_raster_cache() { set_raster_cache_(nullptr); }

  /**
   * @brief Use a mock raster cache in the preroll_context() and
   * paint_context() structures.
   *
   * This method must be called before using the preroll_context() and
   * paint_context() structures in calls to the Layer::Preroll() and
   * Layer::Paint() methods. The mock raster cache behaves like a normal
   * raster cache with respect to decisions about when layers and pictures
   * should be cached, but it does not incur the overhead of rendering the
   * layers or caching the resulting pixels.
   *
   * @see use_null_raster_cache()
   * @see use_skia_raster_cache()
   */
  void use_mock_raster_cache() {
    set_raster_cache_(std::make_unique<MockRasterCache>());
  }

  /**
   * @brief Use a normal raster cache in the preroll_context() and
   * paint_context() structures.
   *
   * This method must be called before using the preroll_context() and
   * paint_context() structures in calls to the Layer::Preroll() and
   * Layer::Paint() methods. The Skia raster cache will behave identically
   * to the raster cache typically used when handling a frame on a device
   * including rendering the contents of pictures and layers to an
   * SkImage, but using a software rather than a hardware renderer.
   *
   * @see use_null_raster_cache()
   * @see use_mock_raster_cache()
   */
  void use_skia_raster_cache() {
    set_raster_cache_(std::make_unique<RasterCache>());
  }

  TextureRegistry& texture_regitry() { return texture_registry_; }
  RasterCache* raster_cache() { return raster_cache_.get(); }
  PrerollContext* preroll_context() { return &preroll_context_; }
  Layer::PaintContext& paint_context() { return paint_context_; }
  Layer::PaintContext& check_board_context() { return check_board_context_; }

 private:
  void set_raster_cache_(std::unique_ptr<RasterCache> raster_cache) {
    raster_cache_ = std::move(raster_cache);
    preroll_context_.raster_cache = raster_cache_.get();
    paint_context_.raster_cache = raster_cache_.get();
  }

  Stopwatch raster_time_;
  Stopwatch ui_time_;
  MutatorsStack mutators_stack_;
  TextureRegistry texture_registry_;

  std::unique_ptr<RasterCache> raster_cache_;
  PrerollContext preroll_context_;
  Layer::PaintContext paint_context_;
  Layer::PaintContext check_board_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(LayerTestBase);
};
using LayerTest = LayerTestBase<::testing::Test>;

}  // namespace testing
}  // namespace flutter

#endif  // FLOW_TESTING_LAYER_TEST_H_
