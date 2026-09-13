// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_OVERSCROLL_STRETCH_LAYER_H_
#define FLUTTER_FLOW_LAYERS_OVERSCROLL_STRETCH_LAYER_H_

#include <memory>
#include "flutter/flow/layers/cacheable_layer.h"

namespace flutter {

class OverscrollStretchLayer : public CacheableContainerLayer {
 public:
  explicit OverscrollStretchLayer(const std::shared_ptr<DlImageFilter>& filter,
                                  DlScalar overscroll_x = 0.0f,
                                  DlScalar overscroll_y = 0.0f,
                                  DlScalar max_stretch_intensity = 1.0f,
                                  DlScalar interpolation_strength = 0.7f,
                                  const DlPoint& offset = DlPoint());

  void Diff(DiffContext* context, const Layer* old_layer) override;

  void Preroll(PrerollContext* context) override;

  void Paint(PaintContext& context) const override;

  DlScalar overscroll_x() const { return overscroll_x_; }
  DlScalar overscroll_y() const { return overscroll_y_; }
  DlScalar max_stretch_intensity() const { return max_stretch_intensity_; }
  DlScalar interpolation_strength() const { return interpolation_strength_; }

 private:
  DlPoint offset_;
  const std::shared_ptr<DlImageFilter> filter_;
  std::shared_ptr<DlImageFilter> transformed_filter_;
  DlScalar overscroll_x_;
  DlScalar overscroll_y_;
  DlScalar max_stretch_intensity_;
  DlScalar interpolation_strength_;

  FML_DISALLOW_COPY_AND_ASSIGN(OverscrollStretchLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_OVERSCROLL_STRETCH_LAYER_H_
