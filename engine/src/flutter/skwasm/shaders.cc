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

sk_sp<flutter::DlRuntimeEffect> CreateRuntimeEffect(SkString* string);
}  // namespace Skwasm

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlColorSource>*
shader_createLinearGradient(flutter::DlPoint* end_points,  // Two points
                            uint32_t* colors,
                            flutter::DlScalar* stops,
                            int count,  // Number of stops/colors
                            flutter::DlTileMode tile_mode,
                            flutter::DlScalar* matrix_33  // Can be nullptr
) {
  Skwasm::live_shader_count++;
  std::vector<flutter::DlColor> dl_colors;
  dl_colors.resize(count);
  for (int i = 0; i < count; i++) {
    dl_colors[i] = flutter::DlColor(colors[i]);
  }
  if (matrix_33) {
    auto matrix = Skwasm::CreateDlMatrixFrom3x3(matrix_33);
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeLinear(end_points[0], end_points[1], count,
                                           dl_colors.data(), stops, tile_mode,
                                           &matrix));
  } else {
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeLinear(end_points[0], end_points[1], count,
                                           dl_colors.data(), stops, tile_mode));
  }
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlColorSource>*
shader_createRadialGradient(flutter::DlScalar center_x,
                            flutter::DlScalar center_y,
                            flutter::DlScalar radius,
                            uint32_t* colors,
                            flutter::DlScalar* stops,
                            int count,
                            flutter::DlTileMode tile_mode,
                            flutter::DlScalar* matrix_33) {
  Skwasm::live_shader_count++;
  std::vector<flutter::DlColor> dl_colors;
  dl_colors.resize(count);
  for (int i = 0; i < count; i++) {
    dl_colors[i] = flutter::DlColor(colors[i]);
  }
  if (matrix_33) {
    auto local_matrix = Skwasm::CreateDlMatrixFrom3x3(matrix_33);
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeRadial(flutter::DlPoint{center_x, center_y},
                                           radius, count, dl_colors.data(),
                                           stops, tile_mode, &local_matrix));
  } else {
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeRadial(flutter::DlPoint{center_x, center_y},
                                           radius, count, dl_colors.data(),
                                           stops, tile_mode));
  }
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlColorSource>*
shader_createConicalGradient(flutter::DlPoint* end_points,  // Two points
                             flutter::DlScalar start_radius,
                             flutter::DlScalar end_radius,
                             uint32_t* colors,
                             flutter::DlScalar* stops,
                             int count,
                             flutter::DlTileMode tile_mode,
                             flutter::DlScalar* matrix_33) {
  Skwasm::live_shader_count++;
  std::vector<flutter::DlColor> dl_colors;
  dl_colors.resize(count);
  for (int i = 0; i < count; i++) {
    dl_colors[i] = flutter::DlColor(colors[i]);
  }
  if (matrix_33) {
    auto local_matrix = Skwasm::CreateDlMatrixFrom3x3(matrix_33);
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeConical(
            end_points[0], start_radius, end_points[1], end_radius, count,
            dl_colors.data(), stops, tile_mode, &local_matrix));
  } else {
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeConical(
            end_points[0], start_radius, end_points[1], end_radius, count,
            dl_colors.data(), stops, tile_mode));
  }
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlColorSource>*
shader_createSweepGradient(flutter::DlScalar center_x,
                           flutter::DlScalar center_y,
                           uint32_t* colors,
                           flutter::DlScalar* stops,
                           int count,
                           flutter::DlTileMode tile_mode,
                           flutter::DlScalar start_angle,
                           flutter::DlScalar end_angle,
                           flutter::DlScalar* matrix_33) {
  Skwasm::live_shader_count++;
  std::vector<flutter::DlColor> dl_colors;
  dl_colors.resize(count);
  for (int i = 0; i < count; i++) {
    dl_colors[i] = flutter::DlColor(colors[i]);
  }
  if (matrix_33) {
    auto local_matrix = Skwasm::CreateDlMatrixFrom3x3(matrix_33);
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeSweep(
            flutter::DlPoint{center_x, center_y}, start_angle, end_angle, count,
            dl_colors.data(), stops, tile_mode, &local_matrix));
  } else {
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeSweep(flutter::DlPoint{center_x, center_y},
                                          start_angle, end_angle, count,
                                          dl_colors.data(), stops, tile_mode));
  }
}

SKWASM_EXPORT void shader_dispose(
    Skwasm::sp_wrapper<flutter::DlColorSource>* shader) {
  Skwasm::live_shader_count--;
  delete shader;
}

SKWASM_EXPORT flutter::DlRuntimeEffect* runtimeEffect_create(SkString* source) {
  Skwasm::live_runtime_effect_count++;
  return Skwasm::CreateRuntimeEffect(source).release();
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
    flutter::DlRuntimeEffect* runtime_effect,
    Skwasm::UniformData* uniforms,
    Skwasm::sp_wrapper<flutter::DlColorSource>** children,
    size_t child_count) {
  Skwasm::live_shader_count++;
  std::vector<std::shared_ptr<flutter::DlColorSource>> child_pointers;
  child_pointers.resize(child_count);
  for (size_t i = 0; i < child_count; i++) {
    child_pointers[i] = children[i]->Shared();
  }

  return new Skwasm::sp_wrapper<flutter::DlColorSource>(
      flutter::DlColorSource::MakeRuntimeEffect(sk_ref_sp(runtime_effect),
                                                std::move(child_pointers),
                                                uniforms->data));
}

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlColorSource>*
shader_createFromImage(flutter::DlImage* image,
                       flutter::DlTileMode tile_mode_x,
                       flutter::DlTileMode tile_mode_y,
                       Skwasm::FilterQuality quality,
                       flutter::DlScalar* matrix_33) {
  Skwasm::live_shader_count++;
  if (matrix_33) {
    auto local_matrix = Skwasm::CreateDlMatrixFrom3x3(matrix_33);
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeImage(
            sk_ref_sp(image), tile_mode_x, tile_mode_y,
            Skwasm::SamplingOptionsForQuality(quality), &local_matrix));
  } else {
    return new Skwasm::sp_wrapper<flutter::DlColorSource>(
        flutter::DlColorSource::MakeImage(
            sk_ref_sp(image), tile_mode_x, tile_mode_y,
            Skwasm::SamplingOptionsForQuality(quality)));
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
