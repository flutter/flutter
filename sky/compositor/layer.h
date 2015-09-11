// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_LAYER_H_
#define SKY_COMPOSITOR_LAYER_H_

#include <memory>
#include <vector>

#include "base/macros.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefPtr.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkXfermode.h"
#include "sky/compositor/paint_context.h"
#include "sky/compositor/picture_rasterizer.h"

namespace sky {
namespace compositor {

class ContainerLayer;
class Layer {
 public:
  Layer();
  virtual ~Layer();

  virtual void Paint(PaintContext::ScopedFrame& frame) = 0;

  virtual SkMatrix model_view_matrix(const SkMatrix& model_matrix) const;

  ContainerLayer* parent() const { return parent_; }

  void set_parent(ContainerLayer* parent) { parent_ = parent; }

  const SkRect& paint_bounds() const { return paint_bounds_; }

  void set_paint_bounds(const SkRect& paint_bounds) {
    paint_bounds_ = paint_bounds;
  }

 private:
  ContainerLayer* parent_;
  SkRect paint_bounds_;

  DISALLOW_COPY_AND_ASSIGN(Layer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_LAYER_H_
