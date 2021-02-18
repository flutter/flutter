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

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

  bool IsReplacing(DiffContext* context, const Layer* layer) const override;

  void Diff(DiffContext* context, const Layer* old_layer) override;

  const PictureLayer* as_picture_layer() const override { return this; }

#endif  // FLUTTER_ENABLE_DIFF_CONTEXT

  void Preroll(PrerollContext* frame, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

 private:
  SkPoint offset_;
  // Even though pictures themselves are not GPU resources, they may reference
  // images that have a reference to a GPU resource.
  SkiaGPUObject<SkPicture> picture_;
  bool is_complex_ = false;
  bool will_change_ = false;

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

  sk_sp<SkData> SerializedPicture() const;
  mutable sk_sp<SkData> cached_serialized_picture_;
  static bool Compare(DiffContext::Statistics& statistics,
                      const PictureLayer* l1,
                      const PictureLayer* l2);

#endif  // FLUTTER_ENABLE_DIFF_CONTEXT

  FML_DISALLOW_COPY_AND_ASSIGN(PictureLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_PICTURE_LAYER_H_
