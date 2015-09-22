// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_PAINT_CONTEXT_CC_
#define SKY_COMPOSITOR_PAINT_CONTEXT_CC_

#include <memory>

#include "base/macros.h"
#include "base/logging.h"
#include "sky/compositor/compositor_options.h"
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

    ScopedFrame(ScopedFrame&& frame);

    ~ScopedFrame();

   private:
    PaintContext& context_;
    SkCanvas* canvas_;
    std::string trace_file_name_;
    std::unique_ptr<SkPictureRecorder> trace_recorder_;

    ScopedFrame(PaintContext& context, SkCanvas& canvas);

    ScopedFrame(PaintContext& context,
                const std::string& trace_file_name,
                gfx::Size frame_size);

    friend class PaintContext;

    DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
  };

  PaintContext();
  ~PaintContext();

  CompositorOptions& options() { return options_; };

  ScopedFrame AcquireFrame(SkCanvas& canvas);

  ScopedFrame AcquireFrame(const std::string& trace_file_name,
                           gfx::Size frame_size);

 private:
  CompositorOptions options_;

  instrumentation::Counter frame_count_;
  instrumentation::Stopwatch frame_time_;

  void beginFrame(ScopedFrame& frame);
  void endFrame(ScopedFrame& frame);
  void DisplayStatistics(ScopedFrame& frame);

  DISALLOW_COPY_AND_ASSIGN(PaintContext);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_PAINT_CONTEXT_CC_
