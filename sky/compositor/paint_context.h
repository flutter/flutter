// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_PAINT_CONTEXT_CC_
#define SKY_COMPOSITOR_PAINT_CONTEXT_CC_

#include "base/macros.h"
#include "sky/compositor/picture_rasterizer.h"

namespace sky {
namespace compositor {

class PaintContext {
 public:
  PaintContext(PictureRasterzier& rasterizer,
               GrContext* gr_context,
               SkCanvas* canvas);
  ~PaintContext();

  PictureRasterzier& rasterizer() { return rasterizer_; }

  GrContext* gr_context() { return gr_context_; }

  SkCanvas* canvas() { return canvas_; }

 private:
  PictureRasterzier& rasterizer_;
  GrContext* gr_context_;
  SkCanvas* canvas_;

  DISALLOW_COPY_AND_ASSIGN(PaintContext);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_PAINT_CONTEXT_CC_
