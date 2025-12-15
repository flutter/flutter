// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/runtime_stage/runtime_stage.h"

#include <array>
#include <memory>
#include <sstream>

#include "fml/mapping.h"
#include "impeller/base/validation.h"
#include "impeller/core/runtime_types.h"
#include "impeller/core/shader_types.h"
#include "impeller/runtime_stage/runtime_stage_flatbuffers.h"
#include "runtime_stage_types_flatbuffers.h"

namespace impeller {

static RuntimeUniformType ToType(fb::UniformDataType type) {
  switch (type) {
    case fb::UniformDataType::kFloat:
      return RuntimeUniformType::kFloat;
    case fb::UniformDataType::kSampledImage:
      return RuntimeUniformType::kSampledImage;
    case fb::UniformDataType::kStruct:
      return RuntimeUniformType::kStruct;
  }
  FML_UNREACHABLE();
}

static RuntimeShaderStage ToShaderStage(fb::Stage stage) {
  switch (stage) {
    case fb::Stage::kVertex:
      return RuntimeShaderStage::kVertex;
    case fb::Stage::kFragment:
      return RuntimeShaderStage::kFragment;
    case fb::Stage::kCompute:
      return RuntimeShaderStage::kCompute;
  }
  FML_UNREACHABLE();
}

/// The generated name from GLSLang/shaderc for the UBO containing non-opaque
/// uniforms specified in the user-written runtime effect shader.
///
/// Vulkan does not allow non-opaque uniforms outside of a UBO.
const char* RuntimeStage::kVulkanUBOName =
    "_RESERVED_IDENTIFIER_FIXUP_gl_DefaultUniformBlock";

absl::StatusOr<RuntimeStage> RuntimeStage::Create(
    const fb::RuntimeStage* runtime_stage,
    const std::shared_ptr<fml::Mapping>& payload) {
  if (!runtime_stage) {
    return absl::InvalidArgumentError("Runtime stage is null.");
  }

  RuntimeStage stage(payload);
  stage.stage_ = ToShaderStage(runtime_stage->stage());
  stage.entrypoint_ = runtime_stage->entrypoint()->str();

  auto* uniforms = runtime_stage->uniforms();

  // Note: image bindings are screwy and will always have the same offset.
  // track the binding of the UBO to determine where the image bindings go.
  // This is only guaranteed to give us the correct bindings if there is a
  // single sampler2D.
  std::optional<size_t> ubo_id;
  if (uniforms) {
    for (auto i = uniforms->begin(), end = uniforms->end(); i != end; i++) {
      RuntimeUniformDescription desc;
      desc.name = i->name()->str();
      desc.location = i->location();
      desc.binding = i->binding();
      desc.type = ToType(i->type());
      if (desc.type == kStruct) {
        ubo_id = desc.location;
        desc.binding = desc.location;
      }
      desc.dimensions = RuntimeUniformDimensions{
          static_cast<size_t>(i->rows()), static_cast<size_t>(i->columns())};
      desc.bit_width = i->bit_width();
      desc.array_elements = i->array_elements();
      if (i->struct_layout()) {
        for (const auto& byte_type : *i->struct_layout()) {
          desc.struct_layout.push_back(static_cast<uint8_t>(byte_type));
        }
      }
      desc.struct_float_count = i->struct_float_count();
      stage.uniforms_.push_back(std::move(desc));
    }
  }

  stage.code_mapping_ = std::make_shared<fml::NonOwnedMapping>(
      runtime_stage->shader()->data(),           //
      runtime_stage->shader()->size(),           //
      [payload = stage.payload_](auto, auto) {}  //
  );

  size_t binding = 64;
  if (ubo_id.has_value() && ubo_id.value() == binding) {
    binding++;
  }
  for (auto& uniform : stage.uniforms_) {
    if (uniform.type == kSampledImage) {
      uniform.binding = binding;
      binding++;
      if (ubo_id.has_value() && ubo_id.value() == binding) {
        binding++;
      }
    }
  }

  for (const auto& uniform : stage.GetUniforms()) {
    if (uniform.type == kStruct) {
      stage.descriptor_set_layouts_.push_back(DescriptorSetLayout{
          static_cast<uint32_t>(uniform.location),
          DescriptorType::kUniformBuffer,
          ShaderStage::kFragment,
      });
    } else if (uniform.type == kSampledImage) {
      stage.descriptor_set_layouts_.push_back(DescriptorSetLayout{
          static_cast<uint32_t>(uniform.binding),
          DescriptorType::kSampledImage,
          ShaderStage::kFragment,
      });
    }
  }

  return stage;
}

std::unique_ptr<RuntimeStage> RuntimeStage::RuntimeStageIfPresent(
    const fb::RuntimeStage* runtime_stage,
    const std::shared_ptr<fml::Mapping>& payload) {
  auto stage = Create(runtime_stage, payload);
  if (!stage.ok()) {
    return nullptr;
  }
  return std::make_unique<RuntimeStage>(std::move(*stage));
}

absl::StatusOr<RuntimeStage::Map> RuntimeStage::DecodeRuntimeStages(
    const std::shared_ptr<fml::Mapping>& payload) {
  if (payload == nullptr || !payload->GetMapping()) {
    return absl::InvalidArgumentError("Payload is null or empty.");
  }
  if (!fb::RuntimeStagesBufferHasIdentifier(payload->GetMapping())) {
    return absl::InvalidArgumentError(
        "Payload does not have valid identifier.");
  }

  auto raw_stages = fb::GetRuntimeStages(payload->GetMapping());
  if (!raw_stages) {
    return absl::InvalidArgumentError("Failed to get runtime stages.");
  }

  const uint32_t version = raw_stages->format_version();
  const auto expected =
      static_cast<uint32_t>(fb::RuntimeStagesFormatVersion::kVersion);
  if (version != expected) {
    std::stringstream stream;
    stream << "Unsupported runtime stages format version. Expected " << expected
           << ", got " << version << ".";
    return absl::InvalidArgumentError(stream.str());
  }

  return Map{
      {RuntimeStageBackend::kSkSL,
       RuntimeStageIfPresent(raw_stages->sksl(), payload)},
      {RuntimeStageBackend::kMetal,
       RuntimeStageIfPresent(raw_stages->metal(), payload)},
      {RuntimeStageBackend::kOpenGLES,
       RuntimeStageIfPresent(raw_stages->opengles(), payload)},
      {RuntimeStageBackend::kOpenGLES3,
       RuntimeStageIfPresent(raw_stages->opengles3(), payload)},
      {RuntimeStageBackend::kVulkan,
       RuntimeStageIfPresent(raw_stages->vulkan(), payload)},
  };
}

RuntimeStage::RuntimeStage(std::shared_ptr<fml::Mapping> payload)
    : payload_(std::move(payload)) {}

RuntimeStage::~RuntimeStage() = default;
RuntimeStage::RuntimeStage(RuntimeStage&&) = default;
RuntimeStage& RuntimeStage::operator=(RuntimeStage&&) = default;

const std::shared_ptr<fml::Mapping>& RuntimeStage::GetCodeMapping() const {
  return code_mapping_;
}

const std::vector<RuntimeUniformDescription>& RuntimeStage::GetUniforms()
    const {
  return uniforms_;
}

const RuntimeUniformDescription* RuntimeStage::GetUniform(
    const std::string& name) const {
  for (const auto& uniform : uniforms_) {
    if (uniform.name == name) {
      return &uniform;
    }
  }
  return nullptr;
}

const std::string& RuntimeStage::GetEntrypoint() const {
  return entrypoint_;
}

RuntimeShaderStage RuntimeStage::GetShaderStage() const {
  return stage_;
}

bool RuntimeStage::IsDirty() const {
  return is_dirty_;
}

void RuntimeStage::SetClean() {
  is_dirty_ = false;
}

const std::vector<DescriptorSetLayout>& RuntimeStage::GetDescriptorSetLayouts()
    const {
  return descriptor_set_layouts_;
}

}  // namespace impeller
