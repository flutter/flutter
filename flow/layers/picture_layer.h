// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_LAYERS_PICTURE_LAYER_H_
#define FLOW_LAYERS_PICTURE_LAYER_H_

#include "flow/layers/layer.h"

namespace flow {

class PictureLayer : public Layer {
 public:
  PictureLayer();
  ~PictureLayer() override;

  void set_offset(const SkPoint& offset) { offset_ = offset; }

  void set_picture(SkPicture* picture) { picture_ = skia::SharePtr(picture); }

  SkPicture* picture() const { return picture_.get(); }

  void Preroll(PrerollContext* frame, const SkMatrix& matrix) override;
  void Paint(PaintContext::ScopedFrame& frame) override;

 private:
  SkPoint offset_;
  skia::RefPtr<SkPicture> picture_;

  // If we rasterized the picture separately, image_ holds the pixels.
  skia::RefPtr<SkImage> image_;

  DISALLOW_COPY_AND_ASSIGN(PictureLayer);
};

}  // namespace flow

#endif  // FLOW_LAYERS_PICTURE_LAYER_H_
