// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Paint.h"

#include "sky/engine/core/painting/CanvasColor.h"
#include "sky/engine/core/painting/ColorFilter.h"
#include "sky/engine/core/painting/DrawLooper.h"
#include "sky/engine/core/painting/FilterQuality.h"
#include "sky/engine/core/painting/MaskFilter.h"
#include "sky/engine/core/painting/PaintingStyle.h"
#include "sky/engine/core/painting/Shader.h"
#include "sky/engine/core/painting/TransferMode.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/wtf/text/StringBuilder.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/core/SkString.h"

#include <iostream>

namespace blink {
namespace {

enum PaintFields {
  kStrokeWidth,
  kIsAntiAlias,
  kColor,
  kColorFilter,
  kDrawLooper,
  kFilterQuality,
  kMaskFilter,
  kShader,
  kStyle,
  kTransferMode,

  // kNumberOfPaintFields must be last.
  kNumberOfPaintFields,
};

}

Paint DartConverter<Paint>::FromDart(Dart_Handle dart_paint) {
  Paint result;
  result.is_null = true;
  if (Dart_IsNull(dart_paint))
    return result;

  Dart_Handle value_handle = DOMDartState::Current()->value_handle();
  Dart_Handle data = Dart_GetField(dart_paint, value_handle);

  DCHECK(Dart_IsList(data));

  intptr_t length;
  Dart_ListLength(data, &length);

  CHECK_EQ(length, kNumberOfPaintFields);
  Dart_Handle values[kNumberOfPaintFields];
  for (int i = 0; i < kNumberOfPaintFields; ++i)
    values[i] = Dart_ListGetAt(data, i);

  SkPaint& paint = result.sk_paint;
  if (!Dart_IsNull(values[kStrokeWidth]))
    paint.setStrokeWidth(DartConverter<SkScalar>::FromDart(values[kStrokeWidth]));
  if (!Dart_IsNull(values[kIsAntiAlias]))
    paint.setAntiAlias(DartConverter<bool>::FromDart(values[kIsAntiAlias]));
  if (!Dart_IsNull(values[kColor]))
    paint.setColor(DartConverter<CanvasColor>::FromDart(values[kColor]));
  if (!Dart_IsNull(values[kColorFilter]))
    paint.setColorFilter(DartConverter<ColorFilter*>::FromDart(values[kColorFilter])->filter());
  if (!Dart_IsNull(values[kDrawLooper]))
    paint.setLooper(DartConverter<DrawLooper*>::FromDart(values[kDrawLooper])->looper());
  if (!Dart_IsNull(values[kFilterQuality]))
    paint.setFilterQuality(DartConverter<FilterQuality>::FromDart(values[kFilterQuality]));
  if (!Dart_IsNull(values[kMaskFilter]))
    paint.setMaskFilter(DartConverter<MaskFilter*>::FromDart(values[kMaskFilter])->filter());
  if (!Dart_IsNull(values[kShader]))
    paint.setShader(DartConverter<Shader*>::FromDart(values[kShader])->shader());
  if (!Dart_IsNull(values[kStyle]))
    paint.setStyle(DartConverter<PaintingStyle>::FromDart(values[kStyle]));
  if (!Dart_IsNull(values[kTransferMode]))
    paint.setXfermodeMode(DartConverter<TransferMode>::FromDart(values[kTransferMode]));

  result.is_null = false;
  return result;
}

Paint DartConverter<Paint>::FromArgumentsWithNullCheck(Dart_NativeArguments args,
                                                       int index,
                                                       Dart_Handle& exception) {
  Dart_Handle dart_rect = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(dart_rect));
  return FromDart(dart_rect);
}

}  // namespace blink
