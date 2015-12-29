// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/LayerDrawLooperBuilder.h"

#include "sky/engine/core/painting/DrawLooper.h"
#include "sky/engine/core/painting/DrawLooperLayerInfo.h"
#include "sky/engine/core/painting/Paint.h"
#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_library_natives.h"
#include "third_party/skia/include/core/SkColorFilter.h"

namespace blink {

static void LayerDrawLooperBuilder_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&LayerDrawLooperBuilder::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(LayerDrawLooperBuilder);

#define FOR_EACH_BINDING(V) \
  V(LayerDrawLooperBuilder, build) \
  V(LayerDrawLooperBuilder, addLayerOnTop)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void LayerDrawLooperBuilder::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "LayerDrawLooperBuilder_constructor", LayerDrawLooperBuilder_constructor, 1, true },
FOR_EACH_BINDING(DART_REGISTER_NATIVE)
  });
}

LayerDrawLooperBuilder::LayerDrawLooperBuilder() {
}

LayerDrawLooperBuilder::~LayerDrawLooperBuilder() {
}

PassRefPtr<DrawLooper> LayerDrawLooperBuilder::build() {
  return DrawLooper::create(adoptRef(draw_looper_builder_.detachLooper()));
}

void LayerDrawLooperBuilder::addLayerOnTop(
    DrawLooperLayerInfo* layer_info, const Paint& paint) {
  SkPaint* sk_paint =
      draw_looper_builder_.addLayerOnTop(layer_info->layer_info());
  if (!paint.is_null)
    *sk_paint = paint.sk_paint;
}

} // namespace blink
