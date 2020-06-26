// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_IMAGE_FILTER_LAYER_H_
#define FLUTTER_FLOW_LAYERS_IMAGE_FILTER_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

#include "third_party/skia/include/core/SkImageFilter.h"

namespace flutter {

class ImageFilterLayer : public MergedContainerLayer {
 public:
  ImageFilterLayer(sk_sp<SkImageFilter> filter);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

 private:
  // The ImageFilterLayer might cache the filtered output of this layer
  // if the layer remains stable (if it is not animating for instance).
  // If the ImageFilterLayer is not the same between rendered frames,
  // though, it will cache its children instead and filter their cached
  // output on the fly.
  // Caching just the children saves the time to render them and also
  // avoids a rendering surface switch to draw them.
  // Caching the layer itself avoids all of that and additionally avoids
  // the cost of applying the filter, but can be worse than caching the
  // children if the filter itself is not stable from frame to frame.
  // This constant controls how many times we will Preroll and Paint this
  // same ImageFilterLayer before we consider the layer and filter to be
  // stable enough to switch from caching the children to caching the
  // filtered output of this layer.
  static constexpr int kMinimumRendersBeforeCachingFilterLayer = 3;

  sk_sp<SkImageFilter> filter_;
  sk_sp<SkImageFilter> transformed_filter_;
  int render_count_;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageFilterLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_IMAGE_FILTER_LAYER_H_
