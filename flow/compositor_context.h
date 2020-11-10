// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_
#define FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_

#include <memory>
#include <string>

#include "flutter/common/graphics/texture.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/flow/instrumentation.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/raster_thread_merger.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

class LayerTree;

enum class RasterStatus {
  // Frame has successfully rasterized.
  kSuccess,
  // Frame is submitted twice. This is only used on Android when
  // switching the background surface to FlutterImageView.
  //
  // On Android, the first frame doesn't make the image available
  // to the ImageReader right away. The second frame does.
  //
  // TODO(egarciad): https://github.com/flutter/flutter/issues/65652
  kResubmit,
  // Frame is dropped and a new frame with the same layer tree is
  // attempted.
  //
  // This is currently used to wait for the thread merger to merge
  // the raster and platform threads.
  //
  // Since the thread merger may be disabled,
  kSkipAndRetry,
  // Frame has been successfully rasterized, but "there are additional items in
  // the pipeline waiting to be consumed. This is currently
  // only used when thread configuration change occurs.
  kEnqueuePipeline,
  // Failed to rasterize the frame.
  kFailed,
  // Layer tree was discarded due to LayerTreeDiscardCallback
  kDiscarded
};

class CompositorContext {
 public:
  class ScopedFrame {
   public:
    ScopedFrame(CompositorContext& context,
                GrDirectContext* gr_context,
                SkCanvas* canvas,
                ExternalViewEmbedder* view_embedder,
                const SkMatrix& root_surface_transformation,
                bool instrumentation_enabled,
                bool surface_supports_readback,
                fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger);

    virtual ~ScopedFrame();

    SkCanvas* canvas() { return canvas_; }

    ExternalViewEmbedder* view_embedder() { return view_embedder_; }

    CompositorContext& context() const { return context_; }

    const SkMatrix& root_surface_transformation() const {
      return root_surface_transformation_;
    }

    bool surface_supports_readback() { return surface_supports_readback_; }

    GrDirectContext* gr_context() const { return gr_context_; }

    virtual RasterStatus Raster(LayerTree& layer_tree,
                                bool ignore_raster_cache);

   private:
    CompositorContext& context_;
    GrDirectContext* gr_context_;
    SkCanvas* canvas_;
    ExternalViewEmbedder* view_embedder_;
    const SkMatrix& root_surface_transformation_;
    const bool instrumentation_enabled_;
    const bool surface_supports_readback_;
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger_;

    FML_DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
  };

  CompositorContext(fml::Milliseconds frame_budget = fml::kDefaultFrameBudget);

  virtual ~CompositorContext();

  virtual std::unique_ptr<ScopedFrame> AcquireFrame(
      GrDirectContext* gr_context,
      SkCanvas* canvas,
      ExternalViewEmbedder* view_embedder,
      const SkMatrix& root_surface_transformation,
      bool instrumentation_enabled,
      bool surface_supports_readback,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger);

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
