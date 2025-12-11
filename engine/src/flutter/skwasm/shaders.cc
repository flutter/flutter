// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/display_list/effects/dl_runtime_effect_skia.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/helpers.h"
#include "flutter/skwasm/live_objects.h"
#include "flutter/skwasm/wrappers.h"
#include "third_party/skia/include/effects/SkRuntimeEffect.h"

namespace Skwasm {
struct UniformData {
  std::shared_ptr<std::vector<uint8_t>> data;
};

extern sk_sp<flutter::DlRuntimeEffect> createRuntimeEffect(SkString* string);
}  // namespace Skwasm

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlColorSource>*
shader_createLinearGradient(flutter::DlPoint* endPoints,  // Two points
                            uint32_t* colors,
                            flutter::DlScalar* stops,
                            int count,  // Number of stops/colors
                            flutter::DlTileMode tileMode,
                            flutter::DlScalar* matrix33  // Can be nullptr
) {
  Skwasm::live_shader_count++;
  std::vector<flutter::DlColor> dl_colors;
  dl_colors.resize(count);
  for (int i = 0; i < count; i++) {
    dl_colors[i] = flutter::DlColor(colors[i]);
  }
  if (matrix33) {
    auto matrix = Skwasm::createDlMatrixFrom3x3(matrix33);
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeLinear(endPoints[0], endPoints[1], count,
                                           dl_colors.data(), stops, tileMode,
                                           &matrix));
  } else {
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeLinear(endPoints[0], endPoints[1], count,
                                           dl_colors.data(), stops, tileMode));
  }
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlColorSource>*
shader_createRadialGradient(flutter::DlScalar centerX,
                            flutter::DlScalar centerY,
                            flutter::DlScalar radius,
                            uint32_t* colors,
                            flutter::DlScalar* stops,
                            int count,
                            flutter::DlTileMode tileMode,
                            flutter::DlScalar* matrix33) {
  Skwasm::live_shader_count++;
  std::vector<flutter::DlColor> dl_colors;
  dl_colors.resize(count);
  for (int i = 0; i < count; i++) {
    dl_colors[i] = flutter::DlColor(colors[i]);
  }
  if (matrix33) {
    auto localMatrix = Skwasm::createDlMatrixFrom3x3(matrix33);
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeRadial(flutter::DlPoint{centerX, centerY},
                                           radius, count, dl_colors.data(),
                                           stops, tileMode, &localMatrix));
  } else {
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeRadial(flutter::DlPoint{centerX, centerY},
                                           radius, count, dl_colors.data(),
                                           stops, tileMode));
  }
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlColorSource>*
shader_createConicalGradient(flutter::DlPoint* endPoints,  // Two points
                             flutter::DlScalar startRadius,
                             flutter::DlScalar endRadius,
                             uint32_t* colors,
                             flutter::DlScalar* stops,
                             int count,
                             flutter::DlTileMode tileMode,
                             flutter::DlScalar* matrix33) {
  Skwasm::live_shader_count++;
  std::vector<flutter::DlColor> dl_colors;
  dl_colors.resize(count);
  for (int i = 0; i < count; i++) {
    dl_colors[i] = flutter::DlColor(colors[i]);
  }
  if (matrix33) {
    auto localMatrix = Skwasm::createDlMatrixFrom3x3(matrix33);
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeConical(
            endPoints[0], startRadius, endPoints[1], endRadius, count,
            dl_colors.data(), stops, tileMode, &localMatrix));
  } else {
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeConical(endPoints[0], startRadius,
                                            endPoints[1], endRadius, count,
                                            dl_colors.data(), stops, tileMode));
  }
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlColorSource>*
shader_createSweepGradient(flutter::DlScalar centerX,
                           flutter::DlScalar centerY,
                           uint32_t* colors,
                           flutter::DlScalar* stops,
                           int count,
                           flutter::DlTileMode tileMode,
                           flutter::DlScalar startAngle,
                           flutter::DlScalar endAngle,
                           flutter::DlScalar* matrix33) {
  Skwasm::live_shader_count++;
  std::vector<flutter::DlColor> dl_colors;
  dl_colors.resize(count);
  for (int i = 0; i < count; i++) {
    dl_colors[i] = flutter::DlColor(colors[i]);
  }
  if (matrix33) {
    auto localMatrix = Skwasm::createDlMatrixFrom3x3(matrix33);
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeSweep(
            flutter::DlPoint{centerX, centerY}, startAngle, endAngle, count,
            dl_colors.data(), stops, tileMode, &localMatrix));
  } else {
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeSweep(flutter::DlPoint{centerX, centerY},
                                          startAngle, endAngle, count,
                                          dl_colors.data(), stops, tileMode));
  }
}

SKWASM_EXPORT void shader_dispose(
    Skwasm::sp_wrapper<flutter::DlColorSource>* shader) {
  Skwasm::live_shader_count--;
  delete shader;
}

SKWASM_EXPORT flutter::DlRuntimeEffect* runtimeEffect_create(SkString* source) {
  Skwasm::live_runtime_effect_count++;
  return Skwasm::createRuntimeEffect(source).release();
}

SKWASM_EXPORT void runtimeEffect_dispose(flutter::DlRuntimeEffect* effect) {
  Skwasm::live_runtime_effect_count--;
  effect->unref();
}

SKWASM_EXPORT size_t
runtimeEffect_getUniformSize(flutter::DlRuntimeEffect* effect) {
  return effect->uniform_size();
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlColorSource>*
shader_createRuntimeEffectShader(
    flutter::DlRuntimeEffect* runtimeEffect,
    Skwasm::UniformData* uniforms,
    Skwasm::sp_wrapper<flutter::DlColorSource>** children,
    size_t childCount) {
  Skwasm::live_shader_count++;
  std::vector<std::shared_ptr<flutter::DlColorSource>> child_pointers;
  child_pointers.resize(childCount);
  for (size_t i = 0; i < childCount; i++) {
    child_pointers[i] = children[i]->Shared();
  }

  return new Skwasm::sp_wrapper<flutter::DlColorSource>(
      flutter::DlColorSource::MakeRuntimeEffect(
          sk_ref_sp(runtimeEffect), std::move(child_pointers), uniforms->data));
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlColorSource>*
shader_createFromImage(flutter::DlImage* image,
                       flutter::DlTileMode tileModeX,
                       flutter::DlTileMode tileModeY,
                       Skwasm::FilterQuality quality,
                       flutter::DlScalar* matrix33) {
  Skwasm::live_shader_count++;
  if (matrix33) {
    auto localMatrix = Skwasm::createDlMatrixFrom3x3(matrix33);
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeImage(
            sk_ref_sp(image), tileModeX, tileModeY,
            Skwasm::samplingOptionsForQuality(quality), &localMatrix));
  } else {
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeImage(
            sk_ref_sp(image), tileModeX, tileModeY,
            Skwasm::samplingOptionsForQuality(quality)));
  }
}

SKWASM_EXPORT Skwasm::UniformData* uniformData_create(int size) {
  return new Skwasm::UniformData{std::make_shared<std::vector<uint8_t>>(size)};
}

SKWASM_EXPORT void uniformData_dispose(Skwasm::UniformData* data) {
  delete data;
}

SKWASM_EXPORT void* uniformData_getPointer(Skwasm::UniformData* data) {
  return data->data->data();
}
