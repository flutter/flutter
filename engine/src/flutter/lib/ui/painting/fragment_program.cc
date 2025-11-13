// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <sstream>

#include "display_list/effects/dl_runtime_effect.h"
#include "display_list/effects/dl_runtime_effect_skia.h"
#include "flutter/lib/ui/painting/fragment_program.h"

#include "flutter/assets/asset_manager.h"
#include "flutter/fml/trace_event.h"
#if IMPELLER_SUPPORTS_RENDERING
#include "flutter/impeller/display_list/dl_runtime_effect_impeller.h"  // nogncheck
#endif
#include "flutter/impeller/runtime_stage/runtime_stage.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_configuration.h"

#include "impeller/core/runtime_types.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/skia/include/effects/SkRuntimeEffect.h"
#include "third_party/tonic/converter/dart_converter.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, FragmentProgram);

static std::string RuntimeStageBackendToString(
    impeller::RuntimeStageBackend backend) {
  switch (backend) {
    case impeller::RuntimeStageBackend::kSkSL:
      return "SkSL";
    case impeller::RuntimeStageBackend::kMetal:
      return "Metal";
    case impeller::RuntimeStageBackend::kOpenGLES:
      return "OpenGLES";
    case impeller::RuntimeStageBackend::kVulkan:
      return "Vulkan";
    case impeller::RuntimeStageBackend::kOpenGLES3:
      return "OpenGLES3";
  }
}

namespace {
Dart_Handle ConvertUniformDescriptionToMap(
    const impeller::RuntimeUniformDescription& uniform_description) {
  constexpr int num_entries = 3;
  Dart_Handle keys = Dart_NewList(num_entries);
  FML_DCHECK(!Dart_IsError(keys));
  Dart_Handle values = Dart_NewList(num_entries);
  FML_DCHECK(!Dart_IsError(values));
  {  // 0
    Dart_Handle name =
        Dart_NewStringFromCString(uniform_description.name.c_str());
    FML_DCHECK(!Dart_IsError(name));
    [[maybe_unused]] Dart_Handle result =
        Dart_ListSetAt(keys, 0, Dart_NewStringFromCString("name"));
    FML_DCHECK(!Dart_IsError(result));
    result = Dart_ListSetAt(values, 0, name);
    FML_DCHECK(!Dart_IsError(result));
  }
  {  // 1
    Dart_Handle type;
    switch (uniform_description.type) {
      case impeller::RuntimeUniformType::kFloat:
        type = Dart_NewStringFromCString("Float");
        break;
      case impeller::RuntimeUniformType::kSampledImage:
        type = Dart_NewStringFromCString("SampledImage");
        break;
      case impeller::RuntimeUniformType::kStruct:
        type = Dart_NewStringFromCString("Struct");
        break;
    }
    FML_DCHECK(!Dart_IsError(type));
    [[maybe_unused]] Dart_Handle result =
        Dart_ListSetAt(keys, 1, Dart_NewStringFromCString("type"));
    FML_DCHECK(!Dart_IsError(result));
    result = Dart_ListSetAt(values, 1, type);
    FML_DCHECK(!Dart_IsError(result));
  }
  {  // 2
    Dart_Handle size = Dart_NewIntegerFromUint64(uniform_description.GetSize());
    FML_DCHECK(!Dart_IsError(size));
    [[maybe_unused]] Dart_Handle result =
        Dart_ListSetAt(keys, 2, Dart_NewStringFromCString("size"));
    FML_DCHECK(!Dart_IsError(result));
    result = Dart_ListSetAt(values, 2, size);
    FML_DCHECK(!Dart_IsError(result));
  }
  Dart_Handle map =
      Dart_NewMap(Dart_TypeString(), keys, Dart_TypeObject(), values);

  return map;
}
}  // namespace

std::string FragmentProgram::initFromAsset(const std::string& asset_name) {
  FML_TRACE_EVENT("flutter", "FragmentProgram::initFromAsset", "asset",
                  asset_name);
  UIDartState* ui_dart_state = UIDartState::Current();
  std::shared_ptr<AssetManager> asset_manager =
      ui_dart_state->platform_configuration()->client()->GetAssetManager();

  std::unique_ptr<fml::Mapping> data = asset_manager->GetAsMapping(asset_name);
  if (data == nullptr) {
    return std::string("Asset '") + asset_name + std::string("' not found");
  }

  auto runtime_stages =
      impeller::RuntimeStage::DecodeRuntimeStages(std::move(data));

  if (runtime_stages.empty()) {
    return std::string("Asset '") + asset_name +
           std::string("' does not contain any shader data.");
  }

  impeller::RuntimeStageBackend backend =
      ui_dart_state->GetRuntimeStageBackend();
  std::shared_ptr<impeller::RuntimeStage> runtime_stage =
      runtime_stages[backend];
  if (!runtime_stage) {
    std::ostringstream stream;
    stream << "Asset '" << asset_name
           << "' does not contain appropriate runtime stage data for current "
              "backend ("
           << RuntimeStageBackendToString(backend) << ")." << std::endl
           << "Found stages: ";
    for (const auto& kvp : runtime_stages) {
      if (kvp.second) {
        stream << RuntimeStageBackendToString(kvp.first) << " ";
      }
    }
    return stream.str();
  }

  int sampled_image_count = 0;
  size_t other_uniforms_bytes = 0;
  const std::vector<impeller::RuntimeUniformDescription>& uniforms =
      runtime_stage->GetUniforms();
  Dart_Handle uniform_info = Dart_NewList(uniforms.size());
  FML_DCHECK(!Dart_IsError(uniform_info));
  for (size_t i = 0; i < uniforms.size(); ++i) {
    const impeller::RuntimeUniformDescription& uniform_description =
        uniforms[i];

    Dart_Handle map = ConvertUniformDescriptionToMap(uniform_description);
    [[maybe_unused]] Dart_Handle dart_result =
        Dart_ListSetAt(uniform_info, i, map);
    FML_DCHECK(!Dart_IsError(dart_result));

    if (uniform_description.type ==
        impeller::RuntimeUniformType::kSampledImage) {
      sampled_image_count++;
    } else {
      other_uniforms_bytes += uniform_description.GetSize();
    }
  }

  if (UIDartState::Current()->IsImpellerEnabled()) {
    // Spawn (but do not block on) a task that will load the runtime stage and
    // populate an initial shader variant.
    auto snapshot_controller = UIDartState::Current()->GetSnapshotDelegate();
    ui_dart_state->GetTaskRunners().GetRasterTaskRunner()->PostTask(
        [runtime_stage, snapshot_controller]() {
          if (!snapshot_controller) {
            return;
          }
          snapshot_controller->CacheRuntimeStage(runtime_stage);
        });
#if IMPELLER_SUPPORTS_RENDERING
    runtime_effect_ = DlRuntimeEffectImpeller::Make(std::move(runtime_stage));
#endif
  } else {
    const auto& code_mapping = runtime_stage->GetCodeMapping();
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
    runtime_effect_ = DlRuntimeEffectSkia::Make(result.effect);
  }

  Dart_Handle ths = Dart_HandleFromWeakPersistent(dart_wrapper());
  if (Dart_IsError(ths)) {
    Dart_PropagateError(ths);
  }

  Dart_Handle result = Dart_SetField(ths, tonic::ToDart("_samplerCount"),
                                     Dart_NewInteger(sampled_image_count));
  if (Dart_IsError(result)) {
    return "Failed to set sampler count for fragment program.";
  }

  size_t rounded_uniform_bytes =
      (other_uniforms_bytes + sizeof(float) - 1) & ~(sizeof(float) - 1);
  size_t float_count = rounded_uniform_bytes / sizeof(float);

  result = Dart_SetField(ths, tonic::ToDart("_uniformFloatCount"),
                         Dart_NewInteger(float_count));
  if (Dart_IsError(result)) {
    return "Failed to set uniform float count for fragment program.";
  }

  result = Dart_SetField(ths, tonic::ToDart("_uniformInfo"), uniform_info);
  if (Dart_IsError(result)) {
    FML_DLOG(ERROR) << Dart_GetError(result);
    return "Failed to set uniform info for fragment program.";
  }

  return "";
}

std::shared_ptr<DlColorSource> FragmentProgram::MakeDlColorSource(
    std::shared_ptr<std::vector<uint8_t>> float_uniforms,
    const std::vector<std::shared_ptr<DlColorSource>>& children) {
  return DlColorSource::MakeRuntimeEffect(runtime_effect_, children,
                                          std::move(float_uniforms));
}

std::shared_ptr<DlImageFilter> FragmentProgram::MakeDlImageFilter(
    std::shared_ptr<std::vector<uint8_t>> float_uniforms,
    const std::vector<std::shared_ptr<DlColorSource>>& children) {
  return DlImageFilter::MakeRuntimeEffect(runtime_effect_, children,
                                          std::move(float_uniforms));
}

void FragmentProgram::Create(Dart_Handle wrapper) {
  auto res = fml::MakeRefCounted<FragmentProgram>();
  res->AssociateWithDartWrapper(wrapper);
}

FragmentProgram::FragmentProgram() = default;

FragmentProgram::~FragmentProgram() = default;

}  // namespace flutter
