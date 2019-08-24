// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_
#define FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_

#include <memory>
#include <string>

#include "flutter/flow/embedded_views.h"
#include "flutter/flow/instrumentation.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/texture.h"
#include "flutter/fml/gpu_thread_merger.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace flutter {

class LayerTree;

enum class RasterStatus {
  // Frame has successfully rasterized.
  kSuccess,
  // Frame needs to be resubmitted for rasterization. This is
  // currently only called when thread configuration change occurs.
  kResubmit,
  // Frame has been successfully rasterized, but "there are additional items in
  // the pipeline waiting to be consumed. This is currently
  // only called when thread configuration change occurs.
  kEnqueuePipeline,
  // Failed to rasterize the frame.
  kFailed
};

class CompositorContext {
 public:
  class ScopedFrame {
   public:
    ScopedFrame(CompositorContext& context,
                GrContext* gr_context,
                SkCanvas* canvas,
                ExternalViewEmbedder* view_embedder,
                const SkMatrix& root_surface_transformation,
                bool instrumentation_enabled,
                fml::RefPtr<fml::GpuThreadMerger> gpu_thread_merger);

    virtual ~ScopedFrame();

    SkCanvas* canvas() { return canvas_; }

    ExternalViewEmbedder* view_embedder() { return view_embedder_; }

    CompositorContext& context() const { return context_; }

    const SkMatrix& root_surface_transformation() const {
      return root_surface_transformation_;
    }

    GrContext* gr_context() const { return gr_context_; }

    virtual RasterStatus Raster(LayerTree& layer_tree,
                                bool ignore_raster_cache);

   private:
    CompositorContext& context_;
    GrContext* gr_context_;
    SkCanvas* canvas_;
    ExternalViewEmbedder* view_embedder_;
    const SkMatrix& root_surface_transformation_;
    const bool instrumentation_enabled_;
    fml::RefPtr<fml::GpuThreadMerger> gpu_thread_merger_;

    FML_DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
  };

  CompositorContext(fml::Milliseconds frame_budget = fml::kDefaultFrameBudget);

  virtual ~CompositorContext();

  virtual std::unique_ptr<ScopedFrame> AcquireFrame(
      GrContext* gr_context,
      SkCanvas* canvas,
      ExternalViewEmbedder* view_embedder,
      const SkMatrix& root_surface_transformation,
      bool instrumentation_enabled,
      fml::RefPtr<fml::GpuThreadMerger> gpu_thread_merger);

  void OnGrContextCreated();

  void OnGrContextDestroyed();

  RasterCache& raster_cache() { return raster_cache_; }

  TextureRegistry& texture_registry() { return texture_registry_; }

  const Counter& frame_count() const { return frame_count_; }

  const Stopwatch& raster_time() const { return raster_time_; }

  Stopwatch& ui_time() { return ui_time_; }

 private:
  RasterCache raster_cache_;
  TextureRegistry texture_registry_;
  Counter frame_count_;
  Stopwatch raster_time_;
  Stopwatch ui_time_;

  void BeginFrame(ScopedFrame& frame, bool enable_instrumentation);

  void EndFrame(ScopedFrame& frame, bool enable_instrumentation);

  FML_DISALLOW_COPY_AND_ASSIGN(CompositorContext);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_
