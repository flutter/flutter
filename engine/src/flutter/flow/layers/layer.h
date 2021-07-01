// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_LAYER_H_
#define FLUTTER_FLOW_LAYERS_LAYER_H_

#include <memory>
#include <vector>

#include "flutter/common/graphics/texture.h"
#include "flutter/flow/diff_context.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/flow/instrumentation.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/utils/SkNWayCanvas.h"

namespace flutter {

namespace testing {
class MockLayer;
}  // namespace testing

static constexpr SkRect kGiantRect = SkRect::MakeLTRB(-1E9F, -1E9F, 1E9F, 1E9F);

// This should be an exact copy of the Clip enum in painting.dart.
enum Clip { none, hardEdge, antiAlias, antiAliasWithSaveLayer };

struct PrerollContext {
  RasterCache* raster_cache;
  GrDirectContext* gr_context;
  ExternalViewEmbedder* view_embedder;
  MutatorsStack& mutators_stack;
  SkColorSpace* dst_color_space;
  SkRect cull_rect;
  bool surface_needs_readback;

  // These allow us to paint in the end of subtree Preroll.
  const Stopwatch& raster_time;
  const Stopwatch& ui_time;
  TextureRegistry& texture_registry;
  const bool checkerboard_offscreen_layers;
  const float frame_device_pixel_ratio;

  // These allow us to track properties like elevation, opacity, and the
  // prescence of a platform view during Preroll.
  bool has_platform_view = false;
  // These allow us to track properties like elevation, opacity, and the
  // prescence of a texture layer during Preroll.
  bool has_texture_layer = false;
};

class PictureLayer;
class DisplayListLayer;
class PerformanceOverlayLayer;
class TextureLayer;

// Represents a single composited layer. Created on the UI thread but then
// subquently used on the Rasterizer thread.
class Layer {
 public:
  Layer();
  virtual ~Layer();

  void AssignOldLayer(Layer* old_layer) {
    original_layer_id_ = old_layer->original_layer_id_;
  }

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

  // Used to establish link between old layer and new layer that replaces it.
  // If this method returns true, it is assumed that this layer replaces the old
  // layer in tree and is able to diff with it.
  virtual bool IsReplacing(DiffContext* context, const Layer* old_layer) const {
    return original_layer_id_ == old_layer->original_layer_id_;
  }

  // Performs diff with given layer
  virtual void Diff(DiffContext* context, const Layer* old_layer) {}

  // Used when diffing retained layer; In case the layer is identical, it
  // doesn't need to be diffed, but the paint region needs to be stored in diff
  // context so that it can be used in next frame
  virtual void PreservePaintRegion(DiffContext* context) {
    // retained layer means same instance so 'this' is used to index into both
    // current and old region
    context->SetLayerPaintRegion(this, context->GetOldLayerPaintRegion(this));
  }

#endif  // FLUTTER_ENABLE_DIFF_CONTEXT

  virtual void Preroll(PrerollContext* context, const SkMatrix& matrix);

  // Used during Preroll by layers that employ a saveLayer to manage the
  // PrerollContext settings with values affected by the saveLayer mechanism.
  // This object must be created before calling Preroll on the children to
  // set up the state for the children and then restore the state upon
  // destruction.
  class AutoPrerollSaveLayerState {
   public:
    [[nodiscard]] static AutoPrerollSaveLayerState Create(
        PrerollContext* preroll_context,
        bool save_layer_is_active = true,
        bool layer_itself_performs_readback = false);

    ~AutoPrerollSaveLayerState();

   private:
    AutoPrerollSaveLayerState(PrerollContext* preroll_context,
                              bool save_layer_is_active,
                              bool layer_itself_performs_readback);

    PrerollContext* preroll_context_;
    bool save_layer_is_active_;
    bool layer_itself_performs_readback_;

    bool prev_surface_needs_readback_;
  };

  struct PaintContext {
    // When splitting the scene into multiple canvases (e.g when embedding
    // a platform view on iOS) during the paint traversal we apply the non leaf
    // flow layers to all canvases, and leaf layers just to the "current"
    // canvas. Applying the non leaf layers to all canvases ensures that when
    // we switch a canvas (when painting a PlatformViewLayer) the next canvas
    // has the exact same state as the current canvas.
    // The internal_nodes_canvas is a SkNWayCanvas which is used by non leaf
    // and applies the operations to all canvases.
    // The leaf_nodes_canvas is the "current" canvas and is used by leaf
    // layers.
    SkCanvas* internal_nodes_canvas;
    SkCanvas* leaf_nodes_canvas;
    GrDirectContext* gr_context;
    ExternalViewEmbedder* view_embedder;
    const Stopwatch& raster_time;
    const Stopwatch& ui_time;
    TextureRegistry& texture_registry;
    const RasterCache* raster_cache;
    const bool checkerboard_offscreen_layers;
    const float frame_device_pixel_ratio;
  };

  // Calls SkCanvas::saveLayer and restores the layer upon destruction. Also
  // draws a checkerboard over the layer if that is enabled in the PaintContext.
  class AutoSaveLayer {
   public:
    [[nodiscard]] static AutoSaveLayer Create(const PaintContext& paint_context,
                                              const SkRect& bounds,
                                              const SkPaint* paint);

    [[nodiscard]] static AutoSaveLayer Create(
        const PaintContext& paint_context,
        const SkCanvas::SaveLayerRec& layer_rec);

    ~AutoSaveLayer();

   private:
    AutoSaveLayer(const PaintContext& paint_context,
                  const SkRect& bounds,
                  const SkPaint* paint);

    AutoSaveLayer(const PaintContext& paint_context,
                  const SkCanvas::SaveLayerRec& layer_rec);

    const PaintContext& paint_context_;
    const SkRect bounds_;
  };

  virtual void Paint(PaintContext& context) const = 0;

  bool subtree_has_platform_view() const { return subtree_has_platform_view_; }
  void set_subtree_has_platform_view(bool value) {
    subtree_has_platform_view_ = value;
  }

  // Returns the paint bounds in the layer's local coordinate system
  // as determined during Preroll().  The bounds should include any
  // transform, clip or distortions performed by the layer itself,
  // but not any similar modifications inherited from its ancestors.
  const SkRect& paint_bounds() const { return paint_bounds_; }

  // This must be set by the time Preroll() returns otherwise the layer will
  // be assumed to have empty paint bounds (paints no content).
  // The paint bounds should be independent of the context outside of this
  // layer as the layer may be painted under different conditions than
  // the Preroll context. The most common example of this condition is
  // that we might Preroll the layer with a cull_rect established by a
  // clip layer above it but then we might be asked to paint anyway if
  // another layer above us needs to cache its children. During the
  // paint operation that arises due to the caching, the clip will
  // be the bounds of the layer needing caching, not the cull_rect
  // that we saw in the overall Preroll operation.
  void set_paint_bounds(const SkRect& paint_bounds) {
    paint_bounds_ = paint_bounds;
  }

  // Determines if the layer has any content.
  bool is_empty() const { return paint_bounds_.isEmpty(); }

  // Determines if the Paint() method is necessary based on the properties
  // of the indicated PaintContext object.
  bool needs_painting(PaintContext& context) const {
    if (subtree_has_platform_view_) {
      // Workaround for the iOS embedder. The iOS embedder expects that
      // if we preroll it, then we will later call its Paint() method.
      // Now that we preroll all layers without any culling, we may
      // call its Preroll() without calling its Paint(). For now, we
      // will not perform paint culling on any subtree that has a
      // platform view.
      // See https://github.com/flutter/flutter/issues/81419
      return true;
    }
    // Workaround for Skia bug (quickReject does not reject empty bounds).
    // https://bugs.chromium.org/p/skia/issues/detail?id=10951
    if (paint_bounds_.isEmpty()) {
      return false;
    }
    return !context.leaf_nodes_canvas->quickReject(paint_bounds_);
  }

  // Propagated unique_id of the first layer in "chain" of replacement layers
  // that can be diffed.
  uint64_t original_layer_id() const { return original_layer_id_; }

  uint64_t unique_id() const { return unique_id_; }

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

  virtual const PictureLayer* as_picture_layer() const { return nullptr; }
  virtual const DisplayListLayer* as_display_list_layer() const {
    return nullptr;
  }
  virtual const TextureLayer* as_texture_layer() const { return nullptr; }
  virtual const PerformanceOverlayLayer* as_performance_overlay_layer() const {
    return nullptr;
  }
  virtual const testing::MockLayer* as_mock_layer() const { return nullptr; }

#endif  // FLUTTER_ENABLE_DIFF_CONTEXT

 private:
  SkRect paint_bounds_;
  uint64_t unique_id_;
  uint64_t original_layer_id_;
  bool subtree_has_platform_view_;

  static uint64_t NextUniqueID();

  FML_DISALLOW_COPY_AND_ASSIGN(Layer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_LAYER_H_
