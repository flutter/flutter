// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_TEXTURE_LAYER_H_
#define FLUTTER_FLOW_LAYERS_TEXTURE_LAYER_H_

#include "flutter/flow/layers/layer.h"
#include "third_party/skia/include/core/SkFilterQuality.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

class TextureLayer : public Layer {
 public:
  TextureLayer(const SkPoint& offset,
               const SkSize& size,
               int64_t texture_id,
               bool freeze,
               SkFilterQuality filter_quality);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) const override;

 private:
  SkPoint offset_;
  SkSize size_;
  int64_t texture_id_;
  bool freeze_;
  SkFilterQuality filter_quality_;

  FML_DISALLOW_COPY_AND_ASSIGN(TextureLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_TEXTURE_LAYER_H_
