// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_COMPOSITOR_CONTEXT_H_
#define FLOW_COMPOSITOR_CONTEXT_H_

#include <memory>
#include <string>

#include "base/logging.h"
#include "base/macros.h"
#include "flow/instrumentation.h"
#include "flow/raster_cache.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace flow {
class Layer;
class LayerTree;

class CompositorContext {
 public:
  class Scope {
   public:
    explicit Scope(CompositorContext& context);
    ~Scope();

   private:
    CompositorContext& context_;

    DISALLOW_COPY_AND_ASSIGN(Scope);
  };

  CompositorContext();
  ~CompositorContext();

  void Preroll(GrContext* gr_context, LayerTree* layer_tree);
  sk_sp<SkPicture> Record(const SkRect& bounds, Layer* layer);

  void OnGrContextDestroyed();

  const Stopwatch& frame_time() { return frame_time_; }

 private:
  RasterCache raster_cache_;
  Stopwatch frame_time_;
  Stopwatch engine_time_;

  DISALLOW_COPY_AND_ASSIGN(CompositorContext);
};

}  // namespace flow

#endif  // FLOW_COMPOSITOR_CONTEXT_H_
