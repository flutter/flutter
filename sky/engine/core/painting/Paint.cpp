// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Paint.h"

#include "sky/engine/core/painting/ColorFilter.h"
#include "sky/engine/core/painting/MaskFilter.h"
#include "sky/engine/core/painting/Shader.h"
#include "sky/engine/core/script/ui_dart_state.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/core/SkString.h"

#include <iostream>

namespace blink {
namespace {

// Must match Paint._value getter in Paint.dart.
enum PaintFields {
  kStyle,
  kStrokeWidth,
  kStrokeCap,
  kIsAntiAlias,
  kColor,
  kTransferMode,
  kColorFilter,
  kMaskFilter,
  kFilterQuality,
  kShader,

  // kNumberOfPaintFields must be last.
  kNumberOfPaintFields,
};

}

Paint DartConverter<Paint>::FromDart(Dart_Handle dart_paint) {
  Paint result;
  result.is_null = true;
  if (Dart_IsNull(dart_paint))
    return result;

  Dart_Handle value_handle = UIDartState::Current()->value_handle();
  Dart_Handle data = Dart_GetField(dart_paint, value_handle);

  if (Dart_IsInteger(data)) {
    // This is a simple Paint object that just contains a color with
    // anti-aliasing enabled. The data is the color, represented as an
    // int in the same format as SkColor.
    result.sk_paint.setColor(DartConverter<SkColor>::FromDart(data));
    result.sk_paint.setAntiAlias(true);
    result.is_null = false;
    return result;
  }

  DCHECK(Dart_IsList(data));

  intptr_t length;
  Dart_ListLength(data, &length);

  CHECK_EQ(length, kNumberOfPaintFields);
  Dart_Handle values[kNumberOfPaintFields];
  Dart_Handle range_result = Dart_ListGetRange(data, 0, kNumberOfPaintFields,
					       values);
  if (Dart_IsError(range_result)) {
    return result;
  }

  SkPaint& paint = result.sk_paint;

  if (!Dart_IsNull(values[kStyle]))
    paint.setStyle(static_cast<SkPaint::Style>(DartConverter<int>::FromDart(values[kStyle])));
  if (!Dart_IsNull(values[kStrokeWidth]))
    paint.setStrokeWidth(DartConverter<SkScalar>::FromDart(values[kStrokeWidth]));
  if (!Dart_IsNull(values[kStrokeCap]))
    paint.setStrokeCap(static_cast<SkPaint::Cap>(DartConverter<int>::FromDart(values[kStrokeCap])));
  if (!Dart_IsNull(values[kIsAntiAlias]))
    paint.setAntiAlias(DartConverter<bool>::FromDart(values[kIsAntiAlias]));
  if (!Dart_IsNull(values[kColor]))
    paint.setColor(static_cast<SkColor>(DartConverter<int>::FromDart(values[kColor])));
  if (!Dart_IsNull(values[kTransferMode]))
    paint.setXfermodeMode(static_cast<SkXfermode::Mode>(DartConverter<int>::FromDart(values[kTransferMode])));
  if (!Dart_IsNull(values[kColorFilter]))
    paint.setColorFilter(DartConverter<ColorFilter*>::FromDart(values[kColorFilter])->filter());
  if (!Dart_IsNull(values[kMaskFilter]))
    paint.setMaskFilter(DartConverter<MaskFilter*>::FromDart(values[kMaskFilter])->filter());
  if (!Dart_IsNull(values[kFilterQuality]))
    paint.setFilterQuality(static_cast<SkFilterQuality>(DartConverter<int>::FromDart(values[kFilterQuality])));
  if (!Dart_IsNull(values[kShader]))
    paint.setShader(DartConverter<Shader*>::FromDart(values[kShader])->shader());

  result.is_null = false;
  return result;
}

Paint DartConverter<Paint>::FromArguments(Dart_NativeArguments args,
                                          int index,
                                          Dart_Handle& exception) {
  Dart_Handle dart_rect = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(dart_rect));
  return FromDart(dart_rect);
}

}  // namespace blink
