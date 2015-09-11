// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_PICTURE_LAYER_H_
#define SKY_COMPOSITOR_PICTURE_LAYER_H_

#include "sky/compositor/layer.h"

namespace sky {
namespace compositor {

class PictureLayer : public Layer {
 public:
  PictureLayer();
  ~PictureLayer() override;

  void set_offset(const SkPoint& offset) { offset_ = offset; }

  void set_picture(PassRefPtr<SkPicture> picture) { picture_ = picture; }

  SkMatrix model_view_matrix(const SkMatrix& model_matrix) const override;

  SkPicture* picture() const { return picture_.get(); }

  void Paint(PaintContext::ScopedFrame& frame) override;

 private:
  SkPoint offset_;
  RefPtr<SkPicture> picture_;

  DISALLOW_COPY_AND_ASSIGN(PictureLayer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_PICTURE_LAYER_H_
