// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "helpers.h"
#include "live_objects.h"
#include "wrappers.h"

#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/display_list/effects/dl_runtime_effect_skia.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/effects/SkRuntimeEffect.h"

using namespace Skwasm;
using namespace flutter;

namespace Skwasm {
struct UniformData {
  std::shared_ptr<std::vector<uint8_t>> data;
};
}  // namespace Skwasm

SKWASM_EXPORT sp_wrapper<DlColorSource>* shader_createLinearGradient(
    DlPoint* endPoints,  // Two points
    uint32_t* colors,
    DlScalar* stops,
    int count,  // Number of stops/colors
    DlTileMode tileMode,
    DlScalar* matrix33  // Can be nullptr
) {
  liveShaderCount++;
  std::vector<DlColor> dlColors;
  dlColors.resize(count);
  for (int i = 0; i < count; i++) {
    dlColors[i] = DlColor(colors[i]);
  }
  if (matrix33) {
    auto matrix = createDlMatrixFrom3x3(matrix33);
    return new sp_wrapper<DlColorSource>(
        DlColorSource::MakeLinear(endPoints[0], endPoints[1], count,
                                  dlColors.data(), stops, tileMode, &matrix));
  } else {
    return new sp_wrapper<DlColorSource>(DlColorSource::MakeLinear(
        endPoints[0], endPoints[1], count, dlColors.data(), stops, tileMode));
  }
}

SKWASM_EXPORT sp_wrapper<DlColorSource>* shader_createRadialGradient(
    DlScalar centerX,
    DlScalar centerY,
    DlScalar radius,
    uint32_t* colors,
    DlScalar* stops,
    int count,
    DlTileMode tileMode,
    DlScalar* matrix33) {
  liveShaderCount++;
  std::vector<DlColor> dlColors;
  dlColors.resize(count);
  for (int i = 0; i < count; i++) {
    dlColors[i] = DlColor(colors[i]);
  }
  if (matrix33) {
    auto localMatrix = createDlMatrixFrom3x3(matrix33);
    return new sp_wrapper<DlColorSource>(DlColorSource::MakeRadial(
        DlPoint{centerX, centerY}, radius, count, dlColors.data(), stops,
        tileMode, &localMatrix));
  } else {
    return new sp_wrapper<DlColorSource>(
        DlColorSource::MakeRadial(DlPoint{centerX, centerY}, radius, count,
                                  dlColors.data(), stops, tileMode));
  }
}

SKWASM_EXPORT sp_wrapper<DlColorSource>* shader_createConicalGradient(
    DlPoint* endPoints,  // Two points
    DlScalar startRadius,
    DlScalar endRadius,
    uint32_t* colors,
    DlScalar* stops,
    int count,
    DlTileMode tileMode,
    DlScalar* matrix33) {
  liveShaderCount++;
  std::vector<DlColor> dlColors;
  dlColors.resize(count);
  for (int i = 0; i < count; i++) {
    dlColors[i] = DlColor(colors[i]);
  }
  if (matrix33) {
    auto localMatrix = createDlMatrixFrom3x3(matrix33);
    return new sp_wrapper<DlColorSource>(DlColorSource::MakeConical(
        endPoints[0], startRadius, endPoints[1], endRadius, count,
        dlColors.data(), stops, tileMode, &localMatrix));
  } else {
    return new sp_wrapper<DlColorSource>(DlColorSource::MakeConical(
        endPoints[0], startRadius, endPoints[1], endRadius, count,
        dlColors.data(), stops, tileMode));
  }
}

SKWASM_EXPORT sp_wrapper<DlColorSource>* shader_createSweepGradient(
    DlScalar centerX,
    DlScalar centerY,
    uint32_t* colors,
    DlScalar* stops,
    int count,
    DlTileMode tileMode,
    DlScalar startAngle,
    DlScalar endAngle,
    DlScalar* matrix33) {
  liveShaderCount++;
  std::vector<DlColor> dlColors;
  dlColors.resize(count);
  for (int i = 0; i < count; i++) {
    dlColors[i] = DlColor(colors[i]);
  }
  if (matrix33) {
    auto localMatrix = createDlMatrixFrom3x3(matrix33);
    return new sp_wrapper<DlColorSource>(DlColorSource::MakeSweep(
        DlPoint{centerX, centerY}, startAngle, endAngle, count, dlColors.data(),
        stops, tileMode, &localMatrix));
  } else {
    return new sp_wrapper<DlColorSource>(DlColorSource::MakeSweep(
        DlPoint{centerX, centerY}, startAngle, endAngle, count, dlColors.data(),
        stops, tileMode));
  }
}

SKWASM_EXPORT void shader_dispose(sp_wrapper<DlColorSource>* shader) {
  liveShaderCount--;
  delete shader;
}

SKWASM_EXPORT SkRuntimeEffect* runtimeEffect_create(SkString* source) {
  liveRuntimeEffectCount++;
  auto result = SkRuntimeEffect::MakeForShader(*source);
  if (result.effect == nullptr) {
    printf("Failed to compile shader. Error text:\n%s",
           result.errorText.data());
    return nullptr;
  } else {
    return result.effect.release();
  }
}

SKWASM_EXPORT void runtimeEffect_dispose(SkRuntimeEffect* effect) {
  liveRuntimeEffectCount--;
  effect->unref();
}

SKWASM_EXPORT size_t runtimeEffect_getUniformSize(SkRuntimeEffect* effect) {
  return effect->uniformSize();
}

SKWASM_EXPORT sp_wrapper<DlColorSource>* shader_createRuntimeEffectShader(
    SkRuntimeEffect* runtimeEffect,
    UniformData* uniforms,
    sp_wrapper<DlColorSource>** children,
    size_t childCount) {
  liveShaderCount++;
  std::vector<std::shared_ptr<DlColorSource>> childPointers;
  childPointers.resize(childCount);
  for (size_t i = 0; i < childCount; i++) {
    childPointers[i] = children[i]->shared();
  }

  return new sp_wrapper<DlColorSource>(DlColorSource::MakeRuntimeEffect(
      DlRuntimeEffectSkia::Make(sk_ref_sp(runtimeEffect)),
      std::move(childPointers), uniforms->data));
}

SKWASM_EXPORT sp_wrapper<DlColorSource>* shader_createFromImage(
    SkImage* image,
    DlTileMode tileModeX,
    DlTileMode tileModeY,
    FilterQuality quality,
    DlScalar* matrix33) {
  liveShaderCount++;
  if (matrix33) {
    auto localMatrix = createDlMatrixFrom3x3(matrix33);
    return new sp_wrapper<DlColorSource>(DlColorSource::MakeImage(
        DlImage::Make(image), tileModeX, tileModeY,
        samplingOptionsForQuality(quality), &localMatrix));
  } else {
    return new sp_wrapper<DlColorSource>(
        DlColorSource::MakeImage(DlImage::Make(image), tileModeX, tileModeY,
                                 samplingOptionsForQuality(quality)));
  }
}

SKWASM_EXPORT UniformData* uniformData_create(int size) {
  return new UniformData{std::make_shared<std::vector<uint8_t>>(size)};
}

SKWASM_EXPORT void uniformData_dispose(UniformData* data) {
  delete data;
}

SKWASM_EXPORT void* uniformData_getPointer(UniformData* data) {
  return data->data->data();
}
