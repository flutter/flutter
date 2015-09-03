// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_H_
#define SKY_COMPOSITOR_H_

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

namespace sky {
class ContainerLayer;

class Layer {
 public:
  Layer();
  virtual ~Layer();

  virtual void Paint(SkCanvas* canvas) = 0;

  ContainerLayer* parent() const { return parent_; }
  void set_parent(ContainerLayer* parent) { parent_ = parent; }

  const SkRect& paint_bounds() const { return paint_bounds_; }
  void set_paint_bounds(const SkRect& paint_bounds) { paint_bounds_ = paint_bounds; }

 private:
  ContainerLayer* parent_;
  SkRect paint_bounds_;

  DISALLOW_COPY_AND_ASSIGN(Layer);
};

class PictureLayer : public Layer {
 public:
  PictureLayer();
  ~PictureLayer() override;

  void Paint(SkCanvas* canvas) override;

  void set_offset(const SkPoint& offset) { offset_ = offset; }
  void set_picture(PassRefPtr<SkPicture> picture) { picture_ = picture; }

 private:
  SkPoint offset_;
  RefPtr<SkPicture> picture_;

  DISALLOW_COPY_AND_ASSIGN(PictureLayer);
};

class ContainerLayer : public Layer {
 public:
  ContainerLayer();
  ~ContainerLayer() override;

  void Add(std::unique_ptr<Layer> layer);

  void PaintChildren(SkCanvas* canvas);

 private:
  std::vector<std::unique_ptr<Layer>> layers_;

  DISALLOW_COPY_AND_ASSIGN(ContainerLayer);
};

class TransformLayer : public ContainerLayer {
 public:
  TransformLayer();
  ~TransformLayer() override;

  void Paint(SkCanvas* canvas) override;

  void set_transform(const SkMatrix& transform) { transform_ = transform; }

 private:
  SkMatrix transform_;

  DISALLOW_COPY_AND_ASSIGN(TransformLayer);
};

class ClipRectLayer : public ContainerLayer {
 public:
  ClipRectLayer();
  ~ClipRectLayer() override;

  void Paint(SkCanvas* canvas) override;

  void set_clip_rect(const SkRect& clip_rect) { clip_rect_ = clip_rect; }

 private:
  SkRect clip_rect_;

  DISALLOW_COPY_AND_ASSIGN(ClipRectLayer);
};

class ClipRRectLayer : public ContainerLayer {
 public:
  ClipRRectLayer();
  ~ClipRRectLayer() override;

  void Paint(SkCanvas* canvas) override;

  void set_clip_rrect(const SkRRect& clip_rrect) { clip_rrect_ = clip_rrect; }

 private:
  SkRRect clip_rrect_;

  DISALLOW_COPY_AND_ASSIGN(ClipRRectLayer);
};

class ClipPathLayer : public ContainerLayer {
 public:
  ClipPathLayer();
  ~ClipPathLayer() override;

  void Paint(SkCanvas* canvas) override;

  void set_clip_path(const SkPath& clip_path) { clip_path_ = clip_path; }

 private:
  SkPath clip_path_;

  DISALLOW_COPY_AND_ASSIGN(ClipPathLayer);
};

class OpacityLayer : public ContainerLayer {
 public:
  OpacityLayer();
  ~OpacityLayer() override;

  void Paint(SkCanvas* canvas) override;

  void set_alpha(int alpha) { alpha_ = alpha; }

 private:
  int alpha_;

  DISALLOW_COPY_AND_ASSIGN(OpacityLayer);
};

class ColorFilterLayer : public ContainerLayer {
 public:
  ColorFilterLayer();
  ~ColorFilterLayer() override;

  void Paint(SkCanvas* canvas) override;

  void set_color(SkColor color) { color_ = color; }
  void set_transfer_mode(SkXfermode::Mode transfer_mode) { transfer_mode_ = transfer_mode; }

 private:
  SkColor color_;
  SkXfermode::Mode transfer_mode_;

  DISALLOW_COPY_AND_ASSIGN(ColorFilterLayer);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_H_
