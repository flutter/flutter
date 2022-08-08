// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>

#include "flutter/lib/ui/painting/fragment_program.h"

#include "flutter/assets/asset_manager.h"
#include "flutter/fml/trace_event.h"
#include "flutter/impeller/runtime_stage/runtime_stage.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, FragmentProgram);

std::string FragmentProgram::initFromAsset(std::string asset_name) {
  FML_TRACE_EVENT("flutter", "FragmentProgram::initFromAsset", "asset",
                  asset_name);
  std::shared_ptr<AssetManager> asset_manager = UIDartState::Current()
                                                    ->platform_configuration()
                                                    ->client()
                                                    ->GetAssetManager();
  std::unique_ptr<fml::Mapping> data = asset_manager->GetAsMapping(asset_name);
  if (data == nullptr) {
    return std::string("Asset '") + asset_name + std::string("' not found");
  }

  auto runtime_stage = impeller::RuntimeStage(std::move(data));
  if (!runtime_stage.IsValid()) {
    return std::string("Asset '") + asset_name +
           std::string("' does not contain valid shader data.");
  }
  {
    auto code_mapping = runtime_stage.GetCodeMapping();
    auto code_size = code_mapping->GetSize();
    const char* sksl =
        reinterpret_cast<const char*>(code_mapping->GetMapping());
    // SkString makes a copy.
    SkRuntimeEffect::Result result =
        SkRuntimeEffect::MakeForShader(SkString(sksl, code_size));
    if (result.effect == nullptr) {
      return std::string("Invalid SkSL:\n") + sksl +
             std::string("\nSkSL Error:\n") + result.errorText.c_str();
    }
    runtime_effect_ = result.effect;
  }

  int sampled_image_count = 0;
  size_t other_uniforms_bytes = 0;
  for (const auto& uniform_description : runtime_stage.GetUniforms()) {
    if (uniform_description.type ==
        impeller::RuntimeUniformType::kSampledImage) {
      sampled_image_count++;
    } else {
      size_t size = uniform_description.dimensions.rows *
                    uniform_description.dimensions.cols *
                    uniform_description.bit_width / 8u;
      if (uniform_description.array_elements > 0) {
        size *= uniform_description.array_elements;
      }
      other_uniforms_bytes += size;
    }
  }

  Dart_Handle ths = Dart_HandleFromWeakPersistent(dart_wrapper());
  if (Dart_IsError(ths)) {
    Dart_PropagateError(ths);
  }

  Dart_Handle result = Dart_SetField(ths, tonic::ToDart("_samplerCount"),
                                     Dart_NewInteger(sampled_image_count));
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }

  size_t rounded_uniform_bytes =
      (other_uniforms_bytes + sizeof(float) - 1) & ~(sizeof(float) - 1);
  size_t float_count = rounded_uniform_bytes / sizeof(float);
  result = Dart_SetField(ths, tonic::ToDart("_uniformFloatCount"),
                         Dart_NewInteger(float_count));
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }

  return "";
}

fml::RefPtr<FragmentShader> FragmentProgram::shader(Dart_Handle shader,
                                                    Dart_Handle uniforms_handle,
                                                    Dart_Handle samplers) {
  auto sampler_shaders =
      tonic::DartConverter<std::vector<ImageShader*>>::FromDart(samplers);
  tonic::Float32List uniforms(uniforms_handle);
  size_t uniform_count = uniforms.num_elements();
  size_t uniform_data_size =
      (uniform_count + 2 * sampler_shaders.size()) * sizeof(float);
  sk_sp<SkData> uniform_data = SkData::MakeUninitialized(uniform_data_size);
  // uniform_floats must only be referenced BEFORE the call to makeShader below.
  auto* uniform_floats =
      reinterpret_cast<float*>(uniform_data->writable_data());
  for (size_t i = 0; i < uniform_count; i++) {
    uniform_floats[i] = uniforms[i];
  }
  uniforms.Release();
  std::vector<sk_sp<SkShader>> sk_samplers(sampler_shaders.size());
  for (size_t i = 0; i < sampler_shaders.size(); i++) {
    DlImageSampling sampling = DlImageSampling::kNearestNeighbor;
    ImageShader* image_shader = sampler_shaders[i];
    // ImageShaders can hold a preferred value for sampling options and
    // developers are encouraged to use that value or the value will be supplied
    // by "the environment where it is used". The environment here does not
    // contain a value to be used if the developer did not specify a preference
    // when they constructed the ImageShader, so we will use kNearest which is
    // the default filterQuality in a Paint object.
    sk_samplers[i] = image_shader->shader(sampling)->skia_object();
    uniform_floats[uniform_count + 2 * i] = image_shader->width();
    uniform_floats[uniform_count + 2 * i + 1] = image_shader->height();
  }
  auto sk_shader = runtime_effect_->makeShader(
      std::move(uniform_data), sk_samplers.data(), sk_samplers.size());
  return FragmentShader::Create(shader, std::move(sk_shader));
}

void FragmentProgram::Create(Dart_Handle wrapper) {
  auto res = fml::MakeRefCounted<FragmentProgram>();
  res->AssociateWithDartWrapper(wrapper);
}

FragmentProgram::FragmentProgram() = default;

FragmentProgram::~FragmentProgram() = default;

}  // namespace flutter
