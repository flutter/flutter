// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_LAYERS_LAYER_H_
#define FLOW_LAYERS_LAYER_H_

#include <memory>
#include <vector>

#include "base/logging.h"
#include "base/macros.h"
#include "base/trace_event/trace_event.h"
#include "flow/instrumentation.h"
#include "flow/raster_cache.h"
#include "skia/ext/refptr.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkXfermode.h"

namespace mojo {
namespace gfx {
namespace composition {
class SceneUpdate;
class Node;
}  // composition
}  // namespace gfx
}  // namespace mojo

namespace flow {

class ContainerLayer;
class Layer {
 public:
  Layer();
  virtual ~Layer();

  struct PrerollContext {
    RasterCache& raster_cache;
    GrContext* gr_context;
    SkRect child_paint_bounds;
  };

  virtual void Preroll(PrerollContext* context, const SkMatrix& matrix);

  struct PaintContext {
    SkCanvas& canvas;
    const Stopwatch& frame_time;
    const Stopwatch& engine_time;
  };

  virtual void Paint(PaintContext& context) = 0;
  virtual void UpdateScene(mojo::gfx::composition::SceneUpdate* update,
                           mojo::gfx::composition::Node* container);

  ContainerLayer* parent() const { return parent_; }

  void set_parent(ContainerLayer* parent) { parent_ = parent; }

  // subclasses should assume this will be true by the time Paint() is called
  bool has_paint_bounds() const { return has_paint_bounds_; }

  const SkRect& paint_bounds() const {
    DCHECK(has_paint_bounds_);
    return paint_bounds_;
  }

  void set_paint_bounds(const SkRect& paint_bounds) {
    has_paint_bounds_ = true;
    paint_bounds_ = paint_bounds;
  }

 private:
  ContainerLayer* parent_;
  bool has_paint_bounds_; // if false, paint_bounds_ is not valid
  SkRect paint_bounds_;

  DISALLOW_COPY_AND_ASSIGN(Layer);
};

}  // namespace flow

#endif  // FLOW_LAYERS_LAYER_H_
