// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/shader.h"

#include <cstring>
#include <utility>

#include "flutter/lib/gpu/formats.h"
#include "fml/make_copyable.h"
#include "impeller/core/runtime_types.h"
#include "impeller/renderer/shader_function.h"
#include "impeller/renderer/shader_key.h"
#include "impeller/renderer/shader_library.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

const impeller::ShaderStructMemberMetadata*
Shader::UniformBinding::GetMemberMetadata(const std::string& name) const {
  auto result =
      std::find_if(metadata.members.begin(), metadata.members.end(),
                   [&name](const impeller::ShaderStructMemberMetadata& member) {
                     return member.name == name;
                   });
  if (result == metadata.members.end()) {
    return nullptr;
  }
  return &(*result);
}

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, Shader);

Shader::Shader() = default;

Shader::~Shader() = default;

fml::RefPtr<Shader> Shader::Make(
    std::string library_id,
    std::string entrypoint,
    impeller::ShaderStage stage,
    std::shared_ptr<fml::Mapping> code_mapping,
    std::vector<impeller::ShaderStageIOSlot> inputs,
    std::vector<impeller::ShaderStageBufferLayout> layouts,
    std::unordered_map<std::string, UniformBinding> uniform_structs,
    std::unordered_map<std::string, TextureBinding> uniform_textures,
    std::vector<impeller::DescriptorSetLayout> descriptor_set_layouts) {
  auto shader = fml::MakeRefCounted<Shader>();
  shader->library_id_ = std::move(library_id);
  shader->entrypoint_ = std::move(entrypoint);
  shader->stage_ = stage;
  shader->code_mapping_ = std::move(code_mapping);
  shader->inputs_ = std::move(inputs);
  shader->layouts_ = std::move(layouts);
  shader->uniform_structs_ = std::move(uniform_structs);
  shader->uniform_textures_ = std::move(uniform_textures);
  shader->descriptor_set_layouts_ = std::move(descriptor_set_layouts);
  return shader;
}

std::string Shader::GetScopedName() const {
  return impeller::ShaderKey::MakeUserScopedName(
      impeller::ShaderKey::kScopeFlutterGPU, library_id_, entrypoint_);
}

std::shared_ptr<const impeller::ShaderFunction> Shader::GetFunctionFromLibrary(
    impeller::ShaderLibrary& library) {
  return library.GetFunction(GetScopedName(), stage_);
}

bool Shader::IsRegistered(Context& context) {
  auto& lib = *context.GetContext().GetShaderLibrary();
  return GetFunctionFromLibrary(lib) != nullptr;
}

bool Shader::IsDirty() const {
  return is_dirty_;
}

void Shader::SetClean() {
  is_dirty_ = false;
}

void Shader::ResetFrom(Shader& other) {
  // Compare the compiled bytes against the freshly-parsed mapping before
  // moving anything. A shader bundle is the unit of asset distribution, so
  // editing one shader recompiles the whole bundle; without this dedupe
  // every unchanged shader in the bundle would still be evicted and
  // re-registered on reload. Code-byte equality is sufficient because
  // impellerc derives reflection metadata (uniforms, inputs, layouts)
  // deterministically from the compiled output.
  const bool code_changed =
      code_mapping_ == nullptr || other.code_mapping_ == nullptr ||
      code_mapping_->GetSize() != other.code_mapping_->GetSize() ||
      std::memcmp(code_mapping_->GetMapping(),
                  other.code_mapping_->GetMapping(),
                  code_mapping_->GetSize()) != 0;

  // library_id_ is intentionally preserved: the scoped registry key
  // (library_id + entrypoint) must remain stable across reloads so the
  // eviction triple-call in `RegisterSync` lands at the same slot.
  entrypoint_ = std::move(other.entrypoint_);
  stage_ = other.stage_;
  code_mapping_ = std::move(other.code_mapping_);
  inputs_ = std::move(other.inputs_);
  layouts_ = std::move(other.layouts_);
  uniform_structs_ = std::move(other.uniform_structs_);
  uniform_textures_ = std::move(other.uniform_textures_);
  descriptor_set_layouts_ = std::move(other.descriptor_set_layouts_);
  if (code_changed) {
    is_dirty_ = true;
  }
}

bool Shader::RegisterSync(Context& context) {
  auto& lib = *context.GetContext().GetShaderLibrary();
  const std::string scoped_name = GetScopedName();

  std::shared_ptr<const impeller::ShaderFunction> existing =
      lib.GetFunction(scoped_name, stage_);
  if (existing && !is_dirty_) {
    return true;  // Already registered and current.
  }

  // Dirty path: an earlier asset version still occupies the scoped slot.
  // Evict it (and any pipelines that referenced it) before registering the
  // new code mapping. Mirrors `RuntimeEffectContents::RegisterShader`.
  if (existing && is_dirty_) {
    context.GetContext().GetPipelineLibrary()->RemovePipelinesWithEntryPoint(
        existing);
    lib.UnregisterFunction(scoped_name, stage_);
  }

  std::promise<bool> promise;
  auto future = promise.get_future();
  lib.RegisterFunction(
      scoped_name, stage_, code_mapping_,
      fml::MakeCopyable([promise = std::move(promise)](bool result) mutable {
        promise.set_value(result);
      }));
  if (!future.get()) {
    return false;  // Registration failed.
  }
  is_dirty_ = false;
  return true;
}

std::shared_ptr<impeller::VertexDescriptor> Shader::CreateVertexDescriptor()
    const {
  auto vertex_descriptor = std::make_shared<impeller::VertexDescriptor>();
  vertex_descriptor->SetStageInputs(inputs_, layouts_);
  return vertex_descriptor;
}

const std::vector<impeller::ShaderStageIOSlot>& Shader::GetStageInputs() const {
  return inputs_;
}

const std::vector<impeller::ShaderStageBufferLayout>&
Shader::GetStageBufferLayouts() const {
  return layouts_;
}

impeller::ShaderStage Shader::GetShaderStage() const {
  return stage_;
}

const std::vector<impeller::DescriptorSetLayout>&
Shader::GetDescriptorSetLayouts() const {
  return descriptor_set_layouts_;
}

const Shader::UniformBinding* Shader::GetUniformStruct(
    const std::string& name) const {
  auto uniform = uniform_structs_.find(name);
  if (uniform == uniform_structs_.end()) {
    return nullptr;
  }
  return &uniform->second;
}

const Shader::TextureBinding* Shader::GetUniformTexture(
    const std::string& name) const {
  auto uniform = uniform_textures_.find(name);
  if (uniform == uniform_textures_.end()) {
    return nullptr;
  }
  return &uniform->second;
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

int InternalFlutterGpu_Shader_GetUniformStructSize(
    flutter::gpu::Shader* wrapper,
    Dart_Handle struct_name_handle) {
  auto name = tonic::StdStringFromDart(struct_name_handle);
  const auto* uniform = wrapper->GetUniformStruct(name);
  if (uniform == nullptr) {
    return -1;
  }

  return uniform->size_in_bytes;
}

int InternalFlutterGpu_Shader_GetUniformMemberOffset(
    flutter::gpu::Shader* wrapper,
    Dart_Handle struct_name_handle,
    Dart_Handle member_name_handle) {
  auto struct_name = tonic::StdStringFromDart(struct_name_handle);
  const auto* uniform = wrapper->GetUniformStruct(struct_name);
  if (uniform == nullptr) {
    return -1;
  }

  auto member_name = tonic::StdStringFromDart(member_name_handle);
  const auto* member = uniform->GetMemberMetadata(member_name);
  if (member == nullptr) {
    return -1;
  }

  return member->offset;
}

bool InternalFlutterGpu_Shader_DebugIsDirty(flutter::gpu::Shader* wrapper) {
  return wrapper->IsDirty();
}
