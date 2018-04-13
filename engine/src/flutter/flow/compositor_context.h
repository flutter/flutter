// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_
#define FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_

#include <memory>
#include <string>

#include "flutter/flow/instrumentation.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/texture.h"
#include "lib/fxl/macros.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace flow {

class LayerTree;

class CompositorContext {
 public:
  class ScopedFrame {
   public:
    ScopedFrame(CompositorContext& context,
                GrContext* gr_context,
                SkCanvas* canvas,
                bool instrumentation_enabled);

    virtual ~ScopedFrame();

    SkCanvas* canvas() { return canvas_; }

    CompositorContext& context() const { return context_; }

    GrContext* gr_context() const { return gr_context_; }

    virtual bool Raster(LayerTree& layer_tree, bool ignore_raster_cache);

   private:
    CompositorContext& context_;
    GrContext* gr_context_;
    SkCanvas* canvas_;
    const bool instrumentation_enabled_;

    FXL_DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
  };

  CompositorContext();

  virtual ~CompositorContext();

  virtual std::unique_ptr<ScopedFrame> AcquireFrame(
      GrContext* gr_context,
      SkCanvas* canvas,
      bool instrumentation_enabled);

  void OnGrContextCreated();

  void OnGrContextDestroyed();

  RasterCache& raster_cache() { return raster_cache_; }

  TextureRegistry& texture_registry() { return texture_registry_; }

  const Counter& frame_count() const { return frame_count_; }

  const Stopwatch& frame_time() const { return frame_time_; }

  Stopwatch& engine_time() { return engine_time_; }

 private:
  RasterCache raster_cache_;
  TextureRegistry texture_registry_;
  Counter frame_count_;
  Stopwatch frame_time_;
  Stopwatch engine_time_;

  void BeginFrame(ScopedFrame& frame, bool enable_instrumentation);

  void EndFrame(ScopedFrame& frame, bool enable_instrumentation);

  FXL_DISALLOW_COPY_AND_ASSIGN(CompositorContext);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_
