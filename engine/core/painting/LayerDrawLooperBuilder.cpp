// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/LayerDrawLooperBuilder.h"

#include "sky/engine/core/painting/DrawLooper.h"
#include "sky/engine/core/painting/DrawLooperAddLayerCallback.h"
#include "sky/engine/core/painting/DrawLooperLayerInfo.h"
#include "sky/engine/core/painting/Paint.h"
#include "third_party/skia/include/core/SkColorFilter.h"

namespace blink {

LayerDrawLooperBuilder::LayerDrawLooperBuilder() {
}

LayerDrawLooperBuilder::~LayerDrawLooperBuilder() {
}

PassRefPtr<DrawLooper> LayerDrawLooperBuilder::build() {
  return DrawLooper::create(adoptRef(draw_looper_builder_.detachLooper()));
}

void LayerDrawLooperBuilder::addLayerOnTop(
    DrawLooperLayerInfo* layer_info,
    PassOwnPtr<DrawLooperAddLayerCallback> callback) {
  SkPaint* sk_paint =
      draw_looper_builder_.addLayerOnTop(layer_info->layer_info());
  RefPtr<Paint> paint = Paint::create();

  paint->setPaint(*sk_paint);
  callback->handleEvent(paint.get());
  *sk_paint = paint->paint();

  // TODO(mpcomplete): Remove this when we add color filter support to Paint's
  // API.
  SkColor skColor = sk_paint->getColor();
  RefPtr<SkColorFilter> cf = adoptRef(
      SkColorFilter::CreateModeFilter(skColor, SkXfermode::kSrcIn_Mode));
  sk_paint->setColorFilter(cf.get());
}

} // namespace blink
