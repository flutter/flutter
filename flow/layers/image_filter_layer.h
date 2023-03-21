// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_IMAGE_FILTER_LAYER_H_
#define FLUTTER_FLOW_LAYERS_IMAGE_FILTER_LAYER_H_

#include <memory>
#include "flutter/flow/layers/cacheable_layer.h"

namespace flutter {

class ImageFilterLayer : public CacheableContainerLayer {
 public:
  explicit ImageFilterLayer(std::shared_ptr<const DlImageFilter> filter,
                            const SkPoint& offset = SkPoint::Make(0, 0));

  void Diff(DiffContext* context, const Layer* old_layer) override;

  void Preroll(PrerollContext* context) override;

  void Paint(PaintContext& context) const override;

 private:
  SkPoint offset_;
  std::shared_ptr<const DlImageFilter> filter_;
  std::shared_ptr<const DlImageFilter> transformed_filter_;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageFilterLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_IMAGE_FILTER_LAYER_H_
