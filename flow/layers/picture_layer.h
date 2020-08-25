// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_PICTURE_LAYER_H_
#define FLUTTER_FLOW_LAYERS_PICTURE_LAYER_H_

#include <memory>

#include "flutter/flow/layers/layer.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/skia_gpu_object.h"

namespace flutter {

class PictureLayer : public Layer {
 public:
  PictureLayer(const SkPoint& offset,
               SkiaGPUObject<SkPicture> picture,
               bool is_complex,
               bool will_change);

  SkPicture* picture() const { return picture_.get().get(); }

  void Preroll(PrerollContext* frame, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

 private:
  SkPoint offset_;
  // Even though pictures themselves are not GPU resources, they may reference
  // images that have a reference to a GPU resource.
  SkiaGPUObject<SkPicture> picture_;
  bool is_complex_ = false;
  bool will_change_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(PictureLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_PICTURE_LAYER_H_
