// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/color_filter.h"

#include <cstring>

#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

static void ColorFilter_constructor(Dart_NativeArguments args) {
  UIDartState::ThrowIfUIOperationsProhibited();
  DartCallConstructor(&ColorFilter::Create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, ColorFilter);

#define FOR_EACH_BINDING(V)             \
  V(ColorFilter, initMode)              \
  V(ColorFilter, initMatrix)            \
  V(ColorFilter, initSrgbToLinearGamma) \
  V(ColorFilter, initLinearToSrgbGamma)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void ColorFilter::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"ColorFilter_constructor", ColorFilter_constructor, 1, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<ColorFilter> ColorFilter::Create() {
  return fml::MakeRefCounted<ColorFilter>();
}

void ColorFilter::initMode(int color, int blend_mode) {
  filter_ = SkColorFilters::Blend(static_cast<SkColor>(color),
                                  static_cast<SkBlendMode>(blend_mode));
}

sk_sp<SkColorFilter> ColorFilter::MakeColorMatrixFilter255(
    const float array[20]) {
  float tmp[20];
  memcpy(tmp, array, sizeof(tmp));
  tmp[4] *= 1.0f / 255;
  tmp[9] *= 1.0f / 255;
  tmp[14] *= 1.0f / 255;
  tmp[19] *= 1.0f / 255;
  return SkColorFilters::Matrix(tmp);
}

void ColorFilter::initMatrix(const tonic::Float32List& color_matrix) {
  FML_CHECK(color_matrix.num_elements() == 20);

  filter_ = MakeColorMatrixFilter255(color_matrix.data());
}

void ColorFilter::initLinearToSrgbGamma() {
  filter_ = SkColorFilters::LinearToSRGBGamma();
}

void ColorFilter::initSrgbToLinearGamma() {
  filter_ = SkColorFilters::SRGBToLinearGamma();
}

ColorFilter::~ColorFilter() = default;

}  // namespace flutter
