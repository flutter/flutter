// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_LAYER_H_
#define FLUTTER_FLOW_LAYERS_LAYER_H_

#include <memory>
#include <vector>

#include "flutter/flow/embedded_views.h"
#include "flutter/flow/instrumentation.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/scene_update_context.h"
#include "flutter/flow/texture.h"
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

static constexpr SkRect kGiantRect = SkRect::MakeLTRB(-1E9F, -1E9F, 1E9F, 1E9F);

// This should be an exact copy of the Clip enum in painting.dart.
enum Clip { none, hardEdge, antiAlias, antiAliasWithSaveLayer };

class ContainerLayer;
class SceneUpdateContext;

struct PrerollContext {
  RasterCache* raster_cache;
  GrContext* gr_context;
  ExternalViewEmbedder* view_embedder;
  MutatorsStack& mutators_stack;
  SkColorSpace* dst_color_space;
  SkRect cull_rect;

  // The following allows us to paint in the end of subtree preroll
  const Stopwatch& raster_time;
  const Stopwatch& ui_time;
  TextureRegistry& texture_registry;
  const bool checkerboard_offscreen_layers;

  // The folllowing allow us to make use of the scene metrics during Preroll.
  float frame_physical_depth;
  float frame_device_pixel_ratio;

  // The following allow us to track properties like elevation and opacity
  // which stack with each other during Preroll.
  float total_elevation = 0.0f;
  bool is_opaque = true;
};

// Represents a single composited layer. Created on the UI thread but then
// subquently used on the Rasterizer thread.
class Layer {
 public:
  Layer();
  virtual ~Layer() = default;

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
    GrContext* gr_context;
    ExternalViewEmbedder* view_embedder;
    const Stopwatch& raster_time;
    const Stopwatch& ui_time;
    TextureRegistry& texture_registry;
    const RasterCache* raster_cache;
    const bool checkerboard_offscreen_layers;

    // The folllowing allow us to make use of the scene metrics during Paint.
    float frame_physical_depth;
    float frame_device_pixel_ratio;
  };

  // Calls SkCanvas::saveLayer and restores the layer upon destruction. Also
  // draws a checkerboard over the layer if that is enabled in the PaintContext.
  class AutoSaveLayer {
   public:
    FML_WARN_UNUSED_RESULT static AutoSaveLayer Create(
        const PaintContext& paint_context,
        const SkRect& bounds,
        const SkPaint* paint);

    FML_WARN_UNUSED_RESULT static AutoSaveLayer Create(
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

  // Performs pre-paint optimizations, including bounds calculation.  Called
  // before |Paint|.  If the |paint_bounds| calculated in this method is empty,
  // then |Paint| will not be called.
  virtual void Preroll(PrerollContext* context, const SkMatrix& matrix) {}

  // Paints this layer onto a canvas.  Not called if |paint_bounds| is empty.
  virtual void Paint(PaintContext& context) const = 0;

  // Updates the system composited scene.
  virtual void UpdateScene(SceneUpdateContext& context) {}

  ContainerLayer* parent() const { return parent_; }
  void set_parent(ContainerLayer* parent) { parent_ = parent; }

  bool needs_system_composite() const { return needs_system_composite_; }
  void set_needs_system_composite(bool value) {
    needs_system_composite_ = value;
  }

  const SkRect& paint_bounds() const { return paint_bounds_; }
  void set_paint_bounds(const SkRect& paint_bounds) {
    paint_bounds_ = paint_bounds;
  }

  bool needs_painting() const { return !paint_bounds_.isEmpty(); }

  uint64_t unique_id() const { return unique_id_; }

 private:
  ContainerLayer* parent_;
  SkRect paint_bounds_;
  uint64_t unique_id_;
  bool needs_system_composite_;

  FML_DISALLOW_COPY_AND_ASSIGN(Layer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_LAYER_H_
