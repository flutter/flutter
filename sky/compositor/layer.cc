// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/layer.h"

#include "third_party/skia/include/core/SkColorFilter.h"

namespace sky {

Layer::Layer() {
}

Layer::~Layer() {
}

PictureLayer::PictureLayer() {
}

PictureLayer::~PictureLayer() {
}

void PictureLayer::Paint(SkCanvas* canvas) {
  canvas->save();
  canvas->translate(offset_.x(), offset_.y());
  canvas->drawPicture(picture_.get());
  canvas->restore();
}

ContainerLayer::ContainerLayer() {
}

ContainerLayer::~ContainerLayer() {
}

void ContainerLayer::Add(std::unique_ptr<Layer> layer) {
  layer->set_parent(this);
  layers_.push_back(std::move(layer));
}

void ContainerLayer::PaintChildren(SkCanvas* canvas) {
  for (auto& layer : layers_)
    layer->Paint(canvas);
}

TransformLayer::TransformLayer() {
}

TransformLayer::~TransformLayer() {
}

void TransformLayer::Paint(SkCanvas* canvas) {
  canvas->save();
  canvas->concat(transform_);
  PaintChildren(canvas);
  canvas->restore();
}

ClipRectLayer::ClipRectLayer() {
}

ClipRectLayer::~ClipRectLayer() {
}

void ClipRectLayer::Paint(SkCanvas* canvas) {
  canvas->save();
  canvas->clipRect(clip_rect_);
  PaintChildren(canvas);
  canvas->restore();
}

ClipRRectLayer::ClipRRectLayer() {
}

ClipRRectLayer::~ClipRRectLayer() {
}

void ClipRRectLayer::Paint(SkCanvas* canvas) {
  canvas->saveLayer(&clip_rrect_.getBounds(), nullptr);
  canvas->clipRRect(clip_rrect_);
  PaintChildren(canvas);
  canvas->restore();
}

ClipPathLayer::ClipPathLayer() {
}

ClipPathLayer::~ClipPathLayer() {
}

void ClipPathLayer::Paint(SkCanvas* canvas) {
  canvas->saveLayer(&clip_path_.getBounds(), nullptr);
  canvas->clipPath(clip_path_);
  PaintChildren(canvas);
  canvas->restore();
}

OpacityLayer::OpacityLayer() {
}

OpacityLayer::~OpacityLayer() {
}

void OpacityLayer::Paint(SkCanvas* canvas) {
  SkColor color = SkColorSetARGB(alpha_, 0, 0, 0);
  RefPtr<SkColorFilter> colorFilter = adoptRef(SkColorFilter::CreateModeFilter(color, SkXfermode::kSrcOver_Mode));
  SkPaint paint;
  paint.setColorFilter(colorFilter.get());
  canvas->saveLayer(&paint_bounds(), &paint);
  PaintChildren(canvas);
  canvas->restore();
}

ColorFilterLayer::ColorFilterLayer() {
}

ColorFilterLayer::~ColorFilterLayer() {
}

void ColorFilterLayer::Paint(SkCanvas* canvas) {
  RefPtr<SkColorFilter> color_filter =
      adoptRef(SkColorFilter::CreateModeFilter(color_, transfer_mode_));
  SkPaint paint;
  paint.setColorFilter(color_filter.get());
  canvas->saveLayer(&paint_bounds(), &paint);
  PaintChildren(canvas);
  canvas->restore();
}

}  // namespace sky
