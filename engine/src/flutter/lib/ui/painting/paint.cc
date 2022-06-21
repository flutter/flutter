// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/paint.h"

#include "flutter/display_list/display_list_builder.h"
#include "flutter/fml/logging.h"
#include "flutter/lib/ui/painting/color_filter.h"
#include "flutter/lib/ui/painting/image_filter.h"
#include "flutter/lib/ui/painting/shader.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkImageFilter.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace flutter {

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
constexpr int kMaskFilterIndex = 9;
constexpr int kMaskFilterBlurStyleIndex = 10;
constexpr int kMaskFilterSigmaIndex = 11;
constexpr int kInvertColorIndex = 12;
constexpr int kDitherIndex = 13;
constexpr size_t kDataByteCount = 56;  // 4 * (last index + 1)

// Indices for objects.
constexpr int kShaderIndex = 0;
constexpr int kColorFilterIndex = 1;
constexpr int kImageFilterIndex = 2;
constexpr int kObjectCount = 3;  // One larger than largest object index.

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
constexpr float kInvertColors[20] = {
  -1.0,    0,    0, 1.0, 0,
     0, -1.0,    0, 1.0, 0,
     0,    0, -1.0, 1.0, 0,
   1.0,  1.0,  1.0, 1.0, 0
};
// clang-format on

// Must be kept in sync with the MaskFilter private constants in painting.dart.
enum MaskFilterType { kNull, kBlur };

Paint::Paint(Dart_Handle paint_objects, Dart_Handle paint_data)
    : paint_objects_(paint_objects), paint_data_(paint_data) {}

const SkPaint* Paint::paint(SkPaint& paint) const {
  if (isNull()) {
    return nullptr;
  }
  FML_DCHECK(paint == SkPaint());

  tonic::DartByteData byte_data(paint_data_);
  FML_CHECK(byte_data.length_in_bytes() == kDataByteCount);

  const uint32_t* uint_data = static_cast<const uint32_t*>(byte_data.data());
  const float* float_data = static_cast<const float*>(byte_data.data());

  Dart_Handle values[kObjectCount];
  if (!Dart_IsNull(paint_objects_)) {
    FML_DCHECK(Dart_IsList(paint_objects_));
    intptr_t length = 0;
    Dart_ListLength(paint_objects_, &length);

    FML_CHECK(length == kObjectCount);
    if (Dart_IsError(
            Dart_ListGetRange(paint_objects_, 0, kObjectCount, values))) {
      return nullptr;
    }

    Dart_Handle shader = values[kShaderIndex];
    if (!Dart_IsNull(shader)) {
      Shader* decoded = tonic::DartConverter<Shader*>::FromDart(shader);
      auto sampling =
          ImageFilter::SamplingFromIndex(uint_data[kFilterQualityIndex]);
      paint.setShader(decoded->shader(sampling)->skia_object());
    }

    Dart_Handle color_filter = values[kColorFilterIndex];
    if (!Dart_IsNull(color_filter)) {
      ColorFilter* decoded =
          tonic::DartConverter<ColorFilter*>::FromDart(color_filter);
      paint.setColorFilter(decoded->filter()->skia_object());
    }

    Dart_Handle image_filter = values[kImageFilterIndex];
    if (!Dart_IsNull(image_filter)) {
      ImageFilter* decoded =
          tonic::DartConverter<ImageFilter*>::FromDart(image_filter);
      paint.setImageFilter(decoded->filter()->skia_object());
    }
  }

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
  if (style) {
    paint.setStyle(static_cast<SkPaint::Style>(style));
  }

  float stroke_width = float_data[kStrokeWidthIndex];
  if (stroke_width != 0.0) {
    paint.setStrokeWidth(stroke_width);
  }

  uint32_t stroke_cap = uint_data[kStrokeCapIndex];
  if (stroke_cap) {
    paint.setStrokeCap(static_cast<SkPaint::Cap>(stroke_cap));
  }

  uint32_t stroke_join = uint_data[kStrokeJoinIndex];
  if (stroke_join) {
    paint.setStrokeJoin(static_cast<SkPaint::Join>(stroke_join));
  }

  float stroke_miter_limit = float_data[kStrokeMiterLimitIndex];
  if (stroke_miter_limit != 0.0) {
    paint.setStrokeMiter(stroke_miter_limit + kStrokeMiterLimitDefault);
  }

  if (uint_data[kInvertColorIndex]) {
    sk_sp<SkColorFilter> invert_filter = SkColorFilters::Matrix(kInvertColors);
    sk_sp<SkColorFilter> current_filter = paint.refColorFilter();
    if (current_filter) {
      invert_filter = invert_filter->makeComposed(current_filter);
    }
    paint.setColorFilter(invert_filter);
  }

  if (uint_data[kDitherIndex]) {
    paint.setDither(true);
  }

  switch (uint_data[kMaskFilterIndex]) {
    case kNull:
      break;
    case kBlur:
      SkBlurStyle blur_style =
          static_cast<SkBlurStyle>(uint_data[kMaskFilterBlurStyleIndex]);
      double sigma = float_data[kMaskFilterSigmaIndex];
      paint.setMaskFilter(SkMaskFilter::MakeBlur(blur_style, sigma));
      break;
  }

  return &paint;
}

bool Paint::sync_to(DisplayListBuilder* builder,
                    const DisplayListAttributeFlags& flags) const {
  if (isNull()) {
    return false;
  }
  tonic::DartByteData byte_data(paint_data_);
  FML_CHECK(byte_data.length_in_bytes() == kDataByteCount);

  const uint32_t* uint_data = static_cast<const uint32_t*>(byte_data.data());
  const float* float_data = static_cast<const float*>(byte_data.data());

  Dart_Handle values[kObjectCount];
  if (Dart_IsNull(paint_objects_)) {
    if (flags.applies_shader()) {
      builder->setColorSource(nullptr);
    }
    if (flags.applies_color_filter()) {
      builder->setColorFilter(nullptr);
    }
    if (flags.applies_image_filter()) {
      builder->setImageFilter(nullptr);
    }
  } else {
    FML_DCHECK(Dart_IsList(paint_objects_));
    intptr_t length = 0;
    Dart_ListLength(paint_objects_, &length);

    FML_CHECK(length == kObjectCount);
    if (Dart_IsError(
            Dart_ListGetRange(paint_objects_, 0, kObjectCount, values))) {
      return false;
    }

    if (flags.applies_shader()) {
      Dart_Handle shader = values[kShaderIndex];
      if (Dart_IsNull(shader)) {
        builder->setColorSource(nullptr);
      } else {
        Shader* decoded = tonic::DartConverter<Shader*>::FromDart(shader);
        auto sampling =
            ImageFilter::SamplingFromIndex(uint_data[kFilterQualityIndex]);
        builder->setColorSource(decoded->shader(sampling).get());
      }
    }

    if (flags.applies_color_filter()) {
      Dart_Handle color_filter = values[kColorFilterIndex];
      if (Dart_IsNull(color_filter)) {
        builder->setColorFilter(nullptr);
      } else {
        ColorFilter* decoded =
            tonic::DartConverter<ColorFilter*>::FromDart(color_filter);
        builder->setColorFilter(decoded->dl_filter());
      }
    }

    if (flags.applies_image_filter()) {
      Dart_Handle image_filter = values[kImageFilterIndex];
      if (Dart_IsNull(image_filter)) {
        builder->setImageFilter(nullptr);
      } else {
        ImageFilter* decoded =
            tonic::DartConverter<ImageFilter*>::FromDart(image_filter);
        builder->setImageFilter(decoded->dl_filter());
      }
    }
  }

  if (flags.applies_anti_alias()) {
    builder->setAntiAlias(uint_data[kIsAntiAliasIndex] == 0);
  }

  if (flags.applies_alpha_or_color()) {
    uint32_t encoded_color = uint_data[kColorIndex];
    builder->setColor(encoded_color ^ kColorDefault);
  }

  if (flags.applies_blend()) {
    uint32_t encoded_blend_mode = uint_data[kBlendModeIndex];
    uint32_t blend_mode = encoded_blend_mode ^ kBlendModeDefault;
    builder->setBlendMode(static_cast<DlBlendMode>(blend_mode));
  }

  if (flags.applies_style()) {
    uint32_t style = uint_data[kStyleIndex];
    builder->setStyle(static_cast<DlDrawStyle>(style));
  }

  if (flags.is_stroked(builder->getStyle())) {
    float stroke_width = float_data[kStrokeWidthIndex];
    builder->setStrokeWidth(stroke_width);

    float stroke_miter_limit = float_data[kStrokeMiterLimitIndex];
    builder->setStrokeMiter(stroke_miter_limit + kStrokeMiterLimitDefault);

    uint32_t stroke_cap = uint_data[kStrokeCapIndex];
    builder->setStrokeCap(static_cast<DlStrokeCap>(stroke_cap));

    uint32_t stroke_join = uint_data[kStrokeJoinIndex];
    builder->setStrokeJoin(static_cast<DlStrokeJoin>(stroke_join));
  }

  if (flags.applies_color_filter()) {
    builder->setInvertColors(uint_data[kInvertColorIndex] != 0);
  }

  if (flags.applies_dither()) {
    builder->setDither(uint_data[kDitherIndex] != 0);
  }

  if (flags.applies_path_effect()) {
    // The paint API exposed to Dart does not support path effects.  But other
    // operations such as text may set a path effect, which must be cleared.
    builder->setPathEffect(nullptr);
  }

  if (flags.applies_mask_filter()) {
    switch (uint_data[kMaskFilterIndex]) {
      case kNull:
        builder->setMaskFilter(nullptr);
        break;
      case kBlur:
        SkBlurStyle blur_style =
            static_cast<SkBlurStyle>(uint_data[kMaskFilterBlurStyleIndex]);
        double sigma = float_data[kMaskFilterSigmaIndex];
        DlBlurMaskFilter dl_filter(blur_style, sigma);
        if (dl_filter.skia_object()) {
          builder->setMaskFilter(&dl_filter);
        } else {
          builder->setMaskFilter(nullptr);
        }
        break;
    }
  }

  return true;
}

}  // namespace flutter

namespace tonic {

flutter::Paint DartConverter<flutter::Paint>::FromArguments(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  Dart_Handle paint_objects = Dart_GetNativeArgument(args, index);
  FML_DCHECK(!CheckAndHandleError(paint_objects));

  Dart_Handle paint_data = Dart_GetNativeArgument(args, index + 1);
  FML_DCHECK(!CheckAndHandleError(paint_data));

  return flutter::Paint(paint_objects, paint_data);
}

flutter::PaintData DartConverter<flutter::PaintData>::FromArguments(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  return flutter::PaintData();
}

}  // namespace tonic
