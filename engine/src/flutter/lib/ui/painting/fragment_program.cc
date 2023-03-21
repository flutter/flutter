// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <sstream>

#include "display_list/effects/dl_runtime_effect.h"
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

std::string FragmentProgram::initFromAsset(const std::string& asset_name) {
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

  int sampled_image_count = 0;
  size_t other_uniforms_bytes = 0;
  for (const auto& uniform_description : runtime_stage.GetUniforms()) {
    if (uniform_description.type ==
        impeller::RuntimeUniformType::kSampledImage) {
      sampled_image_count++;
    } else {
      other_uniforms_bytes += uniform_description.GetSize();
    }
  }

  if (UIDartState::Current()->IsImpellerEnabled()) {
    runtime_effect_ = DlRuntimeEffect::MakeImpeller(
        std::make_unique<impeller::RuntimeStage>(std::move(runtime_stage)));
  } else {
    auto code_mapping = runtime_stage.GetSkSLMapping();
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
    runtime_effect_ = DlRuntimeEffect::MakeSkia(result.effect);
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

std::shared_ptr<DlColorSource> FragmentProgram::MakeDlColorSource(
    std::shared_ptr<std::vector<uint8_t>> float_uniforms,
    const std::vector<std::shared_ptr<DlColorSource>>& children) {
  return DlColorSource::MakeRuntimeEffect(runtime_effect_, children,
                                          std::move(float_uniforms));
}

void FragmentProgram::Create(Dart_Handle wrapper) {
  auto res = fml::MakeRefCounted<FragmentProgram>();
  res->AssociateWithDartWrapper(wrapper);
}

FragmentProgram::FragmentProgram() = default;

FragmentProgram::~FragmentProgram() = default;

}  // namespace flutter
