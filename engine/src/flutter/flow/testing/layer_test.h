// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_TESTING_LAYER_TEST_H_
#define FLOW_TESTING_LAYER_TEST_H_

#include "flutter/flow/layer_snapshot_store.h"
#include "flutter/flow/layers/layer.h"

#include <optional>
#include <utility>
#include <vector>

#include "flutter/flow/testing/mock_raster_cache.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/canvas_test.h"
#include "flutter/testing/display_list_testing.h"
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

  const SkRect kDlBounds = SkRect::MakeWH(500, 500);

 public:
  LayerTestBase()
      : preroll_context_{
            // clang-format off
            .raster_cache                  = nullptr,
            .gr_context                    = nullptr,
            .view_embedder                 = nullptr,
            .mutators_stack                = mutators_stack_,
            .dst_color_space               = TestT::mock_color_space(),
            .cull_rect                     = kGiantRect,
            .surface_needs_readback        = false,
            .raster_time                   = raster_time_,
            .ui_time                       = ui_time_,
            .texture_registry              = texture_registry_,
            .checkerboard_offscreen_layers = false,
            .frame_device_pixel_ratio      = 1.0f,
            .has_platform_view             = false,
            .raster_cached_entries         = &cacheable_items_,
            // clang-format on
        },
        paint_context_{
            // clang-format off
            .internal_nodes_canvas         = TestT::mock_internal_canvas(),
            .leaf_nodes_canvas             = &TestT::mock_canvas(),
            .gr_context                    = nullptr,
            .view_embedder                 = nullptr,
            .raster_time                   = raster_time_,
            .ui_time                       = ui_time_,
            .texture_registry              = texture_registry_,
            .raster_cache                  = nullptr,
            .checkerboard_offscreen_layers = false,
            .frame_device_pixel_ratio      = 1.0f,
            // clang-format on
        },
        display_list_recorder_(kDlBounds),
        internal_display_list_canvas_(kDlBounds.width(), kDlBounds.height()),
        display_list_paint_context_{
            // clang-format off
            .internal_nodes_canvas         = &internal_display_list_canvas_,
            .leaf_nodes_canvas             = &display_list_recorder_,
            .gr_context                    = nullptr,
            .view_embedder                 = nullptr,
            .raster_time                   = raster_time_,
            .ui_time                       = ui_time_,
            .texture_registry              = texture_registry_,
            .raster_cache                  = nullptr,
            .checkerboard_offscreen_layers = false,
            .frame_device_pixel_ratio      = 1.0f,
            .leaf_nodes_builder            = display_list_recorder_.builder().get(),
            // clang-format on
        },
        check_board_context_{
            // clang-format off
            .internal_nodes_canvas         = TestT::mock_internal_canvas(),
            .leaf_nodes_canvas             = &TestT::mock_canvas(),
            .gr_context                    = nullptr,
            .view_embedder                 = nullptr,
            .raster_time                   = raster_time_,
            .ui_time                       = ui_time_,
            .texture_registry              = texture_registry_,
            .raster_cache                  = nullptr,
            .checkerboard_offscreen_layers = true,
            .frame_device_pixel_ratio      = 1.0f,
            // clang-format on
        } {
    internal_display_list_canvas_.addCanvas(&display_list_recorder_);
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

  std::vector<RasterCacheItem*>& cacheable_items() { return cacheable_items_; }

  TextureRegistry& texture_regitry() { return texture_registry_; }
  RasterCache* raster_cache() { return raster_cache_.get(); }
  PrerollContext* preroll_context() { return &preroll_context_; }
  PaintContext& paint_context() { return paint_context_; }
  PaintContext& display_list_paint_context() {
    return display_list_paint_context_;
  }
  PaintContext& check_board_context() { return check_board_context_; }
  LayerSnapshotStore& layer_snapshot_store() { return snapshot_store_; }

  sk_sp<DisplayList> display_list() {
    if (display_list_ == nullptr) {
      display_list_ = display_list_recorder_.Build();
      // null out the canvas and recorder fields of the PaintContext
      // to prevent future use.
      display_list_paint_context_.leaf_nodes_canvas = nullptr;
      display_list_paint_context_.internal_nodes_canvas = nullptr;
      display_list_paint_context_.leaf_nodes_builder = nullptr;
    }
    return display_list_;
  }

  void enable_leaf_layer_tracing() {
    paint_context_.enable_leaf_layer_tracing = true;
    paint_context_.layer_snapshot_store = &snapshot_store_;
  }

  void disable_leaf_layer_tracing() {
    paint_context_.enable_leaf_layer_tracing = false;
    paint_context_.layer_snapshot_store = nullptr;
  }

 private:
  void set_raster_cache_(std::unique_ptr<RasterCache> raster_cache) {
    raster_cache_ = std::move(raster_cache);
    preroll_context_.raster_cache = raster_cache_.get();
    paint_context_.raster_cache = raster_cache_.get();
    display_list_paint_context_.raster_cache = raster_cache_.get();
  }

  FixedRefreshRateStopwatch raster_time_;
  FixedRefreshRateStopwatch ui_time_;
  MutatorsStack mutators_stack_;
  TextureRegistry texture_registry_;

  std::unique_ptr<RasterCache> raster_cache_;
  PrerollContext preroll_context_;
  PaintContext paint_context_;
  DisplayListCanvasRecorder display_list_recorder_;
  sk_sp<DisplayList> display_list_;
  SkNWayCanvas internal_display_list_canvas_;
  PaintContext display_list_paint_context_;
  PaintContext check_board_context_;
  LayerSnapshotStore snapshot_store_;

  std::vector<RasterCacheItem*> cacheable_items_;

  FML_DISALLOW_COPY_AND_ASSIGN(LayerTestBase);
};
using LayerTest = LayerTestBase<::testing::Test>;

}  // namespace testing
}  // namespace flutter

#endif  // FLOW_TESTING_LAYER_TEST_H_
