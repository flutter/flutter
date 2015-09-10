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

    ScopedFrame(ScopedFrame&& frame) = default;

    ~ScopedFrame() { context_.endFrame(); }

   private:
    PaintContext& context_;

    ScopedFrame() = delete;

    ScopedFrame(PaintContext& context, SkCanvas& canvas, GrContext* gr_context)
        : context_(context) {
      context_.beginFrame(canvas, gr_context);
    };

    friend class PaintContext;

    DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
  };

  PaintContext();
  ~PaintContext();

  PictureRasterzier& rasterizer() { return rasterizer_; }

  CompositorOptions& options() { return options_; };

  GrContext* gr_context() { return gr_context_; }

  SkCanvas& canvas() {
    DCHECK(canvas_) << "Tried to access the canvas of a context whose frame "
                       "was not initialized. Did you forget to "
                       "`AcquireFrame`?";
    return *canvas_;
  }

  ScopedFrame AcquireFrame(SkCanvas& canvas, GrContext* gr_context);

 private:
  PictureRasterzier rasterizer_;
  CompositorOptions options_;
  GrContext* gr_context_;
  SkCanvas* canvas_;

  void beginFrame(SkCanvas& canvas, GrContext* context);

  void endFrame();

  DISALLOW_COPY_AND_ASSIGN(PaintContext);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_PAINT_CONTEXT_CC_
