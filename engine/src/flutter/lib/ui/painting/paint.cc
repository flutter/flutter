// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/paint.h"

#include "flutter/fml/logging.h"
#include "flutter/lib/ui/painting/shader.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace blink {

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
constexpr int kInvertColorIndex = 15;
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

// A color matrix which inverts colors.
// clang-format off
constexpr SkScalar invert_colors[20] = {
  -1.0,    0,    0, 1.0, 0,
     0, -1.0,    0, 1.0, 0,
     0,    0, -1.0, 1.0, 0,
   1.0,  1.0,  1.0, 1.0, 0
};
// clang-format on

// Must be kept in sync with the MaskFilter private constants in painting.dart.
enum MaskFilterType { Null, Blur };

Paint::Paint(Dart_Handle paint_objects, Dart_Handle paint_data) {
  is_null_ = Dart_IsNull(paint_data);
  if (is_null_)
    return;

  if (!Dart_IsNull(paint_objects)) {
    FML_DCHECK(Dart_IsList(paint_objects));
    intptr_t length = 0;
    Dart_ListLength(paint_objects, &length);

    FML_CHECK(length == kObjectCount);
    Dart_Handle values[kObjectCount];
    if (Dart_IsError(Dart_ListGetRange(paint_objects, 0, kObjectCount, values)))
      return;

    Dart_Handle shader = values[kShaderIndex];
    if (!Dart_IsNull(shader)) {
      Shader* decoded = tonic::DartConverter<Shader*>::FromDart(shader);
      paint_.setShader(decoded->shader());
    }
  }

  tonic::DartByteData byte_data(paint_data);
  FML_CHECK(byte_data.length_in_bytes() == kDataByteCount);

  const uint32_t* uint_data = static_cast<const uint32_t*>(byte_data.data());
  const float* float_data = static_cast<const float*>(byte_data.data());

  paint_.setAntiAlias(uint_data[kIsAntiAliasIndex] == 0);

  uint32_t encoded_color = uint_data[kColorIndex];
  if (encoded_color) {
    SkColor color = encoded_color ^ kColorDefault;
    paint_.setColor(color);
  }

  uint32_t encoded_blend_mode = uint_data[kBlendModeIndex];
  if (encoded_blend_mode) {
    uint32_t blend_mode = encoded_blend_mode ^ kBlendModeDefault;
    paint_.setBlendMode(static_cast<SkBlendMode>(blend_mode));
  }

  uint32_t style = uint_data[kStyleIndex];
  if (style)
    paint_.setStyle(static_cast<SkPaint::Style>(style));

  float stroke_width = float_data[kStrokeWidthIndex];
  if (stroke_width != 0.0)
    paint_.setStrokeWidth(stroke_width);

  uint32_t stroke_cap = uint_data[kStrokeCapIndex];
  if (stroke_cap)
    paint_.setStrokeCap(static_cast<SkPaint::Cap>(stroke_cap));

  uint32_t stroke_join = uint_data[kStrokeJoinIndex];
  if (stroke_join)
    paint_.setStrokeJoin(static_cast<SkPaint::Join>(stroke_join));

  float stroke_miter_limit = float_data[kStrokeMiterLimitIndex];
  if (stroke_miter_limit != 0.0)
    paint_.setStrokeMiter(stroke_miter_limit + kStrokeMiterLimitDefault);

  uint32_t filter_quality = uint_data[kFilterQualityIndex];
  if (filter_quality)
    paint_.setFilterQuality(static_cast<SkFilterQuality>(filter_quality));

  if (uint_data[kColorFilterIndex] && uint_data[kInvertColorIndex]) {
    SkColor color = uint_data[kColorFilterColorIndex];
    SkBlendMode blend_mode =
        static_cast<SkBlendMode>(uint_data[kColorFilterBlendModeIndex]);
    sk_sp<SkColorFilter> color_filter =
        SkColorFilter::MakeModeFilter(color, blend_mode);
    sk_sp<SkColorFilter> invert_filter =
        SkColorFilter::MakeMatrixFilterRowMajor255(invert_colors);
    paint_.setColorFilter(invert_filter->makeComposed(color_filter));
  } else if (uint_data[kInvertColorIndex]) {
    paint_.setColorFilter(
        SkColorFilter::MakeMatrixFilterRowMajor255(invert_colors));
  } else if (uint_data[kColorFilterIndex]) {
    SkColor color = uint_data[kColorFilterColorIndex];
    SkBlendMode blend_mode =
        static_cast<SkBlendMode>(uint_data[kColorFilterBlendModeIndex]);
    paint_.setColorFilter(SkColorFilter::MakeModeFilter(color, blend_mode));
  }

  switch (uint_data[kMaskFilterIndex]) {
    case Null:
      break;
    case Blur:
      SkBlurStyle blur_style =
          static_cast<SkBlurStyle>(uint_data[kMaskFilterBlurStyleIndex]);
      double sigma = float_data[kMaskFilterSigmaIndex];
      paint_.setMaskFilter(SkMaskFilter::MakeBlur(blur_style, sigma));
      break;
  }
}

}  // namespace blink

namespace tonic {

blink::Paint DartConverter<blink::Paint>::FromArguments(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  Dart_Handle paint_objects = Dart_GetNativeArgument(args, index);
  FML_DCHECK(!LogIfError(paint_objects));

  Dart_Handle paint_data = Dart_GetNativeArgument(args, index + 1);
  FML_DCHECK(!LogIfError(paint_data));

  return blink::Paint(paint_objects, paint_data);
}

blink::PaintData DartConverter<blink::PaintData>::FromArguments(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  return blink::PaintData();
}

}  // namespace tonic
