// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_
#define FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_

#include <memory>
#include <string>

#include "flutter/flow/instrumentation.h"
#include "flutter/flow/process_info.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/texture.h"
#include "lib/fxl/macros.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace flow {

class CompositorContext {
 public:
  class ScopedFrame {
   public:
    SkCanvas* canvas() { return canvas_; }

    CompositorContext& context() const { return context_; }

    GrContext* gr_context() const { return gr_context_; }

    ScopedFrame(ScopedFrame&& frame);

    ~ScopedFrame();

   private:
    CompositorContext& context_;
    GrContext* gr_context_;
    SkCanvas* canvas_;
    const bool instrumentation_enabled_;

    ScopedFrame(CompositorContext& context,
                GrContext* gr_context,
                SkCanvas* canvas,
                bool instrumentation_enabled);

    friend class CompositorContext;

    FXL_DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
  };

  CompositorContext(std::unique_ptr<ProcessInfo> info);

  ~CompositorContext();

  ScopedFrame AcquireFrame(GrContext* gr_context,
                           SkCanvas* canvas,
                           bool instrumentation_enabled = true);

  void OnGrContextCreated();

  void OnGrContextDestroyed();

  RasterCache& raster_cache() { return raster_cache_; }

  TextureRegistry& texture_registry() { return *texture_registry_; }

  const Counter& frame_count() const { return frame_count_; }

  const Stopwatch& frame_time() const { return frame_time_; }

  Stopwatch& engine_time() { return engine_time_; }

  const CounterValues& memory_usage() const { return memory_usage_; }

  void SetTextureRegistry(TextureRegistry* textureRegistry) {
    texture_registry_ = textureRegistry;
  }

 private:
  RasterCache raster_cache_;
  TextureRegistry* texture_registry_;
  std::unique_ptr<ProcessInfo> process_info_;
  Counter frame_count_;
  Stopwatch frame_time_;
  Stopwatch engine_time_;
  CounterValues memory_usage_;

  void BeginFrame(ScopedFrame& frame, bool enable_instrumentation);

  void EndFrame(ScopedFrame& frame, bool enable_instrumentation);

  FXL_DISALLOW_COPY_AND_ASSIGN(CompositorContext);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_
