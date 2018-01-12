// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/paint.h"

#include "flutter/lib/ui/painting/shader.h"
#include "lib/fxl/logging.h"
#include "lib/tonic/typed_data/dart_byte_data.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/skia/include/effects/SkBlurMaskFilter.h"

using namespace blink;

namespace tonic {

// Indices for 32bit values.
constexpr int kIsAntiAliasIndex = 0;
constexpr int kColorIndex = 1;
constexpr int kBlendModeIndex = 2;
constexpr int kStyleIndex = 3;
constexpr int kStrokeWidthIndex = 4;
constexpr int kStrokeCapIndex = 5;
constexpr int kStrokeJoinIndex = 6;
constexpr int kStrokeMiterLimitIndex = 7;
constexpr int kFilterQualityIndex = 8;
constexpr int kColorFilterIndex = 9;
constexpr int kColorFilterColorIndex = 10;
constexpr int kColorFilterBlendModeIndex = 11;
constexpr int kMaskFilterIndex = 12;
constexpr int kMaskFilterBlurStyleIndex = 13;
constexpr int kMaskFilterSigmaIndex = 14;
constexpr size_t kDataByteCount = 75;  // 4 * (last index + 1)

// Indices for objects.
constexpr int kShaderIndex = 0;
constexpr int kObjectCount = 1;  // One larger than largest object index.

// Must be kept in sync with the default in painting.dart.
constexpr uint32_t kColorDefault = 0xFF000000;

// Must be kept in sync with the default in painting.dart.
constexpr uint32_t kBlendModeDefault =
    static_cast<uint32_t>(SkBlendMode::kSrcOver);

// Must be kept in sync with the default in painting.dart, and also with the
// default SkPaintDefaults_MiterLimit in Skia (which is not in a public header).
constexpr double kStrokeMiterLimitDefault = 4.0;

// Must be kept in sync with the MaskFilter private constants in painting.dart.
enum MaskFilterType { Null, Blur };

Paint DartConverter<Paint>::FromArguments(Dart_NativeArguments args,
                                          int index,
                                          Dart_Handle& exception) {
  Dart_Handle paint_objects = Dart_GetNativeArgument(args, index);
  FXL_DCHECK(!LogIfError(paint_objects));

  Dart_Handle paint_data = Dart_GetNativeArgument(args, index + 1);
  FXL_DCHECK(!LogIfError(paint_data));

  Paint result;
  SkPaint& paint = result.paint_;

  if (!Dart_IsNull(paint_objects)) {
    FXL_DCHECK(Dart_IsList(paint_objects));
    intptr_t length = 0;
    Dart_ListLength(paint_objects, &length);

    FXL_CHECK(length == kObjectCount);
    Dart_Handle values[kObjectCount];
    if (Dart_IsError(Dart_ListGetRange(paint_objects, 0, kObjectCount, values)))
      return result;

    Dart_Handle shader = values[kShaderIndex];
    if (!Dart_IsNull(shader)) {
      Shader* decoded = DartConverter<Shader*>::FromDart(shader);
      paint.setShader(decoded->shader());
    }
  }

  tonic::DartByteData byte_data(paint_data);
  FXL_CHECK(byte_data.length_in_bytes() == kDataByteCount);

  const uint32_t* uint_data = static_cast<const uint32_t*>(byte_data.data());
  const float* float_data = static_cast<const float*>(byte_data.data());

  paint.setAntiAlias(uint_data[kIsAntiAliasIndex] == 0);

  uint32_t encoded_color = uint_data[kColorIndex];
  if (encoded_color) {
    SkColor color = encoded_color ^ kColorDefault;
    paint.setColor(color);
  }

  uint32_t encoded_blend_mode = uint_data[kBlendModeIndex];
  if (encoded_blend_mode) {
    uint32_t blend_mode = encoded_blend_mode ^ kBlendModeDefault;
    paint.setBlendMode(static_cast<SkBlendMode>(blend_mode));
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

  uint32_t stroke_join = uint_data[kStrokeJoinIndex];
  if (stroke_join)
    paint.setStrokeJoin(static_cast<SkPaint::Join>(stroke_join));

  float stroke_miter_limit = float_data[kStrokeMiterLimitIndex];
  if (stroke_miter_limit != 0.0)
    paint.setStrokeMiter(stroke_miter_limit + kStrokeMiterLimitDefault);

  uint32_t filter_quality = uint_data[kFilterQualityIndex];
  if (filter_quality)
    paint.setFilterQuality(static_cast<SkFilterQuality>(filter_quality));

  if (uint_data[kColorFilterIndex]) {
    SkColor color = uint_data[kColorFilterColorIndex];
    SkBlendMode blend_mode =
        static_cast<SkBlendMode>(uint_data[kColorFilterBlendModeIndex]);
    paint.setColorFilter(SkColorFilter::MakeModeFilter(color, blend_mode));
  }

  switch (uint_data[kMaskFilterIndex]) {
    case Null:
      break;
    case Blur:
      SkBlurStyle blur_style =
          static_cast<SkBlurStyle>(uint_data[kMaskFilterBlurStyleIndex]);
      double sigma = float_data[kMaskFilterSigmaIndex];
      paint.setMaskFilter(SkBlurMaskFilter::Make(blur_style, sigma));
      break;
  }

  result.is_null_ = false;
  return result;
}

PaintData DartConverter<PaintData>::FromArguments(Dart_NativeArguments args,
                                                  int index,
                                                  Dart_Handle& exception) {
  return PaintData();
}

}  // namespace tonic
