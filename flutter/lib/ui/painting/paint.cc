// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/paint.h"

#include "flutter/lib/ui/painting/mask_filter.h"
#include "flutter/lib/ui/painting/shader.h"
#include "flutter/tonic/dart_byte_data.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/core/SkString.h"

namespace blink {

static const int kIsAntiAliasIndex = 0;
static const int kColorIndex = 1;
static const int kTransferModeIndex = 2;
static const int kStyleIndex = 3;
static const int kStrokeWidthIndex = 4;
static const int kStrokeCapIndex = 5;
static const int kFilterQualityIndex = 6;
static const int kColorFilterIndex = 7;
static const int kColorFilterColorIndex = 8;
static const int kColorFilterTransferModeIndex = 9;
static const size_t kDataByteCount = 40;

static const int kMaskFilterIndex = 0;
static const int kShaderIndex = 1;
static const int kObjectCount = 2;  // Must be one larger than the largest index

Paint DartConverter<Paint>::FromArguments(Dart_NativeArguments args,
                                          int index,
                                          Dart_Handle& exception) {
  Dart_Handle paint_objects = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(paint_objects));

  Dart_Handle paint_data = Dart_GetNativeArgument(args, index + 1);
  DCHECK(!LogIfError(paint_data));

  Paint result;
  SkPaint& paint = result.paint_;

  if (!Dart_IsNull(paint_objects)) {
    DCHECK(Dart_IsList(paint_objects));
    intptr_t length = 0;
    Dart_ListLength(paint_objects, &length);

    CHECK_EQ(length, kObjectCount);
    Dart_Handle values[kObjectCount];
    if (Dart_IsError(Dart_ListGetRange(paint_objects, 0, kObjectCount, values)))
      return result;

    Dart_Handle mask_filter = values[kMaskFilterIndex];
    if (!Dart_IsNull(mask_filter)) {
      MaskFilter* decoded = DartConverter<MaskFilter*>::FromDart(mask_filter);
      paint.setMaskFilter(decoded->filter());
    }

    Dart_Handle shader = values[kShaderIndex];
    if (!Dart_IsNull(shader)) {
      Shader* decoded = DartConverter<Shader*>::FromDart(shader);
      paint.setShader(decoded->shader());
    }
  }

  DartByteData byte_data(paint_data);
  CHECK_EQ(byte_data.length_in_bytes(), kDataByteCount);

  const uint32_t* uint_data = static_cast<const uint32_t*>(byte_data.data());
  const float* float_data = static_cast<const float*>(byte_data.data());

  paint.setAntiAlias(uint_data[kIsAntiAliasIndex] == 0);

  uint32_t encoded_color = uint_data[kColorIndex];
  if (encoded_color) {
    SkColor color = encoded_color ^ 0xFF000000;
    paint.setColor(color);
  }

  uint32_t encoded_transfer_mode = uint_data[kTransferModeIndex];
  if (encoded_transfer_mode) {
    uint32_t transfer_mode = encoded_transfer_mode ^ SkXfermode::kSrcOver_Mode;
    paint.setXfermodeMode(static_cast<SkXfermode::Mode>(transfer_mode));
  }

  uint32_t style = uint_data[kStyleIndex];
  if (style)
    paint.setStyle(static_cast<SkPaint::Style>(style));

  float stroke_width = float_data[kStrokeWidthIndex];
  if (stroke_width != 0.0)
    paint.setStrokeWidth(stroke_width);

  uint32_t stroke_cap = uint_data[kStrokeCapIndex];
  if (stroke_cap)
    paint.setStrokeCap(static_cast<SkPaint::Cap>(stroke_cap));

  uint32_t filter_quality = uint_data[kFilterQualityIndex];
  if (filter_quality)
    paint.setFilterQuality(static_cast<SkFilterQuality>(filter_quality));

  if (uint_data[kColorFilterIndex]) {
    SkColor color = uint_data[kColorFilterColorIndex];
    SkXfermode::Mode transfer_mode =
        static_cast<SkXfermode::Mode>(uint_data[kColorFilterTransferModeIndex]);
    paint.setColorFilter(SkColorFilter::MakeModeFilter(color, transfer_mode));
  }

  result.is_null_ = false;
  return result;
}

PaintData DartConverter<PaintData>::FromArguments(Dart_NativeArguments args,
                                                  int index,
                                                  Dart_Handle& exception) {
  return PaintData();
}

}  // namespace blink
