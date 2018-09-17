// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/shader_mask_layer.h"

namespace flow {

ShaderMaskLayer::ShaderMaskLayer() = default;

ShaderMaskLayer::~ShaderMaskLayer() = default;

void ShaderMaskLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ShaderMaskLayer::Paint");
  FML_DCHECK(needs_painting());

  Layer::AutoSaveLayer save =
      Layer::AutoSaveLayer::Create(context, paint_bounds(), nullptr);
  PaintChildren(context);

  SkPaint paint;
  paint.setBlendMode(blend_mode_);
  paint.setShader(shader_);
  context.canvas.translate(mask_rect_.left(), mask_rect_.top());
  context.canvas.drawRect(
      SkRect::MakeWH(mask_rect_.width(), mask_rect_.height()), paint);
}

}  // namespace flow
