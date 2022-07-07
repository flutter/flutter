// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_LAYER_H_
#define FLUTTER_FLOW_LAYERS_LAYER_H_

#include <algorithm>
#include <memory>
#include <unordered_set>
#include <vector>

#include "flutter/common/graphics/texture.h"
#include "flutter/flow/diff_context.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/flow/instrumentation.h"
#include "flutter/flow/layer_snapshot_store.h"
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
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/utils/SkNWayCanvas.h"
namespace flutter {
namespace testing {
class MockLayer;
}  // namespace testing

class ContainerLayer;
class DisplayListLayer;
class PerformanceOverlayLayer;
class TextureLayer;
class RasterCacheItem;

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
  const float frame_device_pixel_ratio = 1.0f;

  // These allow us to track properties like elevation, opacity, and the
  // prescence of a platform view during Preroll.
  bool has_platform_view = false;
  // These allow us to track properties like elevation, opacity, and the
  // prescence of a texture layer during Preroll.
  bool has_texture_layer = false;

  // This field indicates whether the subtree rooted at this layer can
  // inherit an opacity value and modulate its visibility accordingly.
  //
  // Any layer is free to ignore this flag. Its value will be false upon
  // entry into its Preroll method, it will remain false if it calls
  // PrerollChildren on any children it might have, and it will remain
  // false upon exit from the Preroll method unless it takes specific
  // action compute if it should be true. Thus, this property is "opt-in".
  //
  // If the value is false when the Preroll method exits, then the
  // |PaintContext::inherited_opacity| value should always be set to
  // 1.0 when its |Paint| method is called.
  //
  // Leaf layers need only be concerned with their own rendering and
  // can set the value according to whether they can apply the opacity.
  //
  // For containers, there are 3 ways to interact with this field:
  //
  // 1. If you need to know whether your children are compatible, then
  //    set the field to true before you call PrerollChildren. That
  //    method will then reset the field to false if it detects any
  //    incompatible children.
  //
  // 2. If your decision on whether to inherit the opacity depends on
  //    the answer from the children, then remember the value of the
  //    field when PrerollChildren returns. (eg. OpacityLayer remembers
  //    this value to control whether to set the opacity value into the
  //    |PaintContext::inherited_opacity| field in |Paint| before
  //    recursing to its children in Paint)
  //
  // 3. If you want to indicate to your parents that you can accept
  //    inherited opacity regardless of whether your children were
  //    compatible then set this field to true before returning
  //    from your Preroll method. (eg. layers that always apply a
  //    saveLayer when rendering anyway can apply the opacity there)
  bool subtree_can_inherit_opacity = false;

  std::vector<RasterCacheItem*>* raster_cached_entries;
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
  SkColorSpace* dst_color_space;
  ExternalViewEmbedder* view_embedder;
  const Stopwatch& raster_time;
  const Stopwatch& ui_time;
  TextureRegistry& texture_registry;
  const RasterCache* raster_cache;
  const bool checkerboard_offscreen_layers;
  const float frame_device_pixel_ratio = 1.0f;

  // Snapshot store to collect leaf layer snapshots. The store is non-null
  // only when leaf layer tracing is enabled.
  LayerSnapshotStore* layer_snapshot_store = nullptr;
  bool enable_leaf_layer_tracing = false;

  // The following value should be used to modulate the opacity of the
  // layer during |Paint|. If the layer does not set the corresponding
  // |layer_can_inherit_opacity()| flag, then this value should always
  // be |SK_Scalar1|. The value is to be applied as if by using a
  // |saveLayer| with an |SkPaint| initialized to this alphaf value and
  // a |kSrcOver| blend mode.
  SkScalar inherited_opacity = SK_Scalar1;
  DisplayListBuilder* leaf_nodes_builder = nullptr;
};

// Represents a single composited layer. Created on the UI thread but then
// subquently used on the Rasterizer thread.
class Layer {
 public:
  Layer();
  virtual ~Layer();

  void AssignOldLayer(Layer* old_layer) {
    original_layer_id_ = old_layer->original_layer_id_;
  }

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

  class AutoCachePaint {
   public:
    explicit AutoCachePaint(PaintContext& context) : context_(context) {
      needs_paint_ = context.inherited_opacity < SK_Scalar1;
      if (needs_paint_) {
        sk_paint_.setAlphaf(context.inherited_opacity);
        dl_paint_.setAlpha(SkScalarRoundToInt(context.inherited_opacity * 255));
        context.inherited_opacity = SK_Scalar1;
      }
    }

    ~AutoCachePaint() { context_.inherited_opacity = sk_paint_.getAlphaf(); }

    void setImageFilter(sk_sp<SkImageFilter> filter) {
      sk_paint_.setImageFilter(filter);
      dl_paint_.setImageFilter(DlImageFilter::From(filter));
      update_needs_paint();
    }

    void setColorFilter(sk_sp<SkColorFilter> filter) {
      sk_paint_.setColorFilter(filter);
      dl_paint_.setColorFilter(DlColorFilter::From(filter));
      update_needs_paint();
    }

    void setBlendMode(DlBlendMode mode) {
      sk_paint_.setBlendMode(ToSk(mode));
      dl_paint_.setBlendMode(mode);
      update_needs_paint();
    }

    const SkPaint* sk_paint() { return needs_paint_ ? &sk_paint_ : nullptr; }
    const DlPaint* dl_paint() { return needs_paint_ ? &dl_paint_ : nullptr; }

   private:
    PaintContext& context_;
    SkPaint sk_paint_;
    DlPaint dl_paint_;
    bool needs_paint_;

    void update_needs_paint() {
      needs_paint_ = sk_paint_.getImageFilter() != nullptr ||
                     sk_paint_.getColorFilter() != nullptr ||
                     !sk_paint_.isSrcOver() ||
                     sk_paint_.getAlphaf() < SK_Scalar1;
    }
  };

  // Calls SkCanvas::saveLayer and restores the layer upon destruction. Also
  // draws a checkerboard over the layer if that is enabled in the PaintContext.
  class AutoSaveLayer {
   public:
    // Indicates which canvas the layer should be saved on.
    //
    // Usually layers are saved on the internal_nodes_canvas, so that all
    // the canvas keep track of the current state of the layer tree.
    // In some special cases, layers should only save on the leaf_nodes_canvas,
    // See https:://flutter.dev/go/backdrop-filter-with-overlay-canvas for why
    // it is the case for Backdrop filter layer.
    enum SaveMode {
      // The layer is saved on the internal_nodes_canvas.
      kInternalNodesCanvas,
      // The layer is saved on the leaf_nodes_canvas.
      kLeafNodesCanvas
    };

    // Create a layer and save it on the canvas.
    //
    // The layer is restored from the canvas in destructor.
    //
    // By default, the layer is saved on and restored from
    // `internal_nodes_canvas`. The `save_mode` parameter can be modified to
    // save the layer on other canvases.
    [[nodiscard]] static AutoSaveLayer Create(
        const PaintContext& paint_context,
        const SkRect& bounds,
        const SkPaint* paint,
        SaveMode save_mode = SaveMode::kInternalNodesCanvas);
    // Create a layer and save it on the canvas.
    //
    // The layer is restored from the canvas in destructor.
    //
    // By default, the layer is saved on and restored from
    // `internal_nodes_canvas`. The `save_mode` parameter can be modified to
    // save the layer on other canvases.
    [[nodiscard]] static AutoSaveLayer Create(
        const PaintContext& paint_context,
        const SkCanvas::SaveLayerRec& layer_rec,
        SaveMode save_mode = SaveMode::kInternalNodesCanvas);

    ~AutoSaveLayer();

   private:
    AutoSaveLayer(const PaintContext& paint_context,
                  const SkRect& bounds,
                  const SkPaint* paint,
                  SaveMode save_mode = SaveMode::kInternalNodesCanvas);

    AutoSaveLayer(const PaintContext& paint_context,
                  const SkCanvas::SaveLayerRec& layer_rec,
                  SaveMode save_mode = SaveMode::kInternalNodesCanvas);

    const PaintContext& paint_context_;
    const SkRect bounds_;
    // The canvas that this layer is saved on and popped from.
    SkCanvas& canvas_;
  };

  virtual void Paint(PaintContext& context) const = 0;

  virtual void PaintChildren(PaintContext& context) const { FML_DCHECK(false); }

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
    if (context.inherited_opacity == 0) {
      return false;
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

  virtual const ContainerLayer* as_container_layer() const { return nullptr; }
  virtual const DisplayListLayer* as_display_list_layer() const {
    return nullptr;
  }
  virtual const TextureLayer* as_texture_layer() const { return nullptr; }
  virtual const PerformanceOverlayLayer* as_performance_overlay_layer() const {
    return nullptr;
  }
  virtual const testing::MockLayer* as_mock_layer() const { return nullptr; }

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
