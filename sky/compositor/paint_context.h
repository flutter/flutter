// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_PAINT_CONTEXT_CC_
#define SKY_COMPOSITOR_PAINT_CONTEXT_CC_

#include "base/macros.h"
#include "base/logging.h"
#include "sky/compositor/compositor_options.h"
#include "sky/compositor/picture_rasterizer.h"

namespace sky {
namespace compositor {

class PaintContext {
 public:
  class ScopedFrame {
   public:
    PaintContext& paint_context() { return context_; };

    GrContext* gr_context() { return gr_context_; }

    SkCanvas& canvas() { return canvas_; }

    ScopedFrame(ScopedFrame&& frame) = default;

    ~ScopedFrame() { context_.endFrame(); }

   private:
    PaintContext& context_;
    SkCanvas& canvas_;
    GrContext* gr_context_;

    ScopedFrame() = delete;

    ScopedFrame(PaintContext& context, SkCanvas& canvas, GrContext* gr_context)
        : context_(context), canvas_(canvas), gr_context_(gr_context) {
      DCHECK(&canvas) << "The frame requries a valid canvas";
      context_.beginFrame();
    };

    friend class PaintContext;

    DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
  };

  PaintContext();
  ~PaintContext();

  PictureRasterzier& rasterizer() { return rasterizer_; }

  CompositorOptions& options() { return options_; };

  ScopedFrame AcquireFrame(SkCanvas& canvas, GrContext* gr_context);

 private:
  PictureRasterzier rasterizer_;
  CompositorOptions options_;

  void beginFrame();

  void endFrame();

  DISALLOW_COPY_AND_ASSIGN(PaintContext);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_PAINT_CONTEXT_CC_
