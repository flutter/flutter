// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_PAINT_CONTEXT_H_
#define SKY_COMPOSITOR_PAINT_CONTEXT_H_

#include <memory>
#include <string>

#include "base/macros.h"
#include "base/logging.h"
#include "sky/compositor/instrumentation.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "ui/gfx/geometry/size.h"

namespace sky {
namespace compositor {

class PaintContext {
 public:
  class ScopedFrame {
   public:
    SkCanvas& canvas() { return *canvas_; }

    PaintContext& context() const { return context_; }

    ScopedFrame(ScopedFrame&& frame);

    ~ScopedFrame();

   private:
    PaintContext& context_;
    SkCanvas* canvas_;
    std::string trace_file_name_;
    std::unique_ptr<SkPictureRecorder> trace_recorder_;
    const bool instrumentation_enabled_;

    ScopedFrame(PaintContext& context, SkCanvas& canvas);

    ScopedFrame(PaintContext& context,
                const std::string& trace_file_name,
                gfx::Size frame_size);

    friend class PaintContext;

    DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
  };

  PaintContext();
  ~PaintContext();

  ScopedFrame AcquireFrame(SkCanvas& canvas);

  ScopedFrame AcquireFrame(const std::string& trace_file_name,
                           gfx::Size frame_size);

  const instrumentation::Counter& frame_count() const { return frame_count_; }

  const instrumentation::Stopwatch& frame_time() const { return frame_time_; }

  instrumentation::Stopwatch& engine_time() { return engine_time_; };

 private:
  instrumentation::Counter frame_count_;
  instrumentation::Stopwatch frame_time_;
  instrumentation::Stopwatch engine_time_;

  void beginFrame(ScopedFrame& frame, bool enableInstrumentation);
  void endFrame(ScopedFrame& frame, bool enableInstrumentation);

  DISALLOW_COPY_AND_ASSIGN(PaintContext);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_PAINT_CONTEXT_H_
