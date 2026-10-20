// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/shader.h"

#include <chrono>
#include <cstring>
#include <utility>

#include "flutter/lib/gpu/formats.h"
#include "flutter/lib/gpu/recording.h"
#include "fml/make_copyable.h"
#include "impeller/base/promise.h"
#include "impeller/core/runtime_types.h"
#include "impeller/renderer/pipeline_library.h"
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
  shader->reflection_ =
      MakeReflection(std::move(uniform_structs), std::move(uniform_textures));
  shader->descriptor_set_layouts_ = std::move(descriptor_set_layouts);
  return shader;
}

std::shared_ptr<const Shader::Reflection> Shader::MakeReflection(
    std::unordered_map<std::string, UniformBinding> uniform_structs,
    std::unordered_map<std::string, TextureBinding> uniform_textures) {
  auto reflection = std::make_shared<Reflection>();
  reflection->uniform_structs = std::move(uniform_structs);
  reflection->uniform_textures = std::move(uniform_textures);
  reflection->uniform_struct_order.reserve(reflection->uniform_structs.size());
  for (const auto& entry : reflection->uniform_structs) {
    reflection->uniform_struct_order.push_back(&entry.second);
  }
  reflection->uniform_texture_order.reserve(
      reflection->uniform_textures.size());
  for (const auto& entry : reflection->uniform_textures) {
    reflection->uniform_texture_order.push_back(&entry.second);
  }
  return reflection;
}

const std::shared_ptr<const Shader::Reflection>& Shader::GetReflection() const {
  return reflection_;
}

std::string Shader::GetScopedName() const {
  return impeller::ShaderKey::MakeUserScopedName(
      impeller::ShaderKey::kScopeFlutterGPU, library_id_, entrypoint_);
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
  // eviction in `ScheduleRegistration` lands at the same slot.
  entrypoint_ = std::move(other.entrypoint_);
  stage_ = other.stage_;
  code_mapping_ = std::move(other.code_mapping_);
  inputs_ = std::move(other.inputs_);
  layouts_ = std::move(other.layouts_);
  // Swapped rather than mutated, so recordings holding the old reflection
  // keep valid binding pointers.
  reflection_ = std::move(other.reflection_);
  descriptor_set_layouts_ = std::move(other.descriptor_set_layouts_);
  if (code_changed) {
    is_dirty_ = true;
  }
}

void Shader::Registration::Set(std::shared_future<bool> latest) {
  std::scoped_lock lock(mutex_);
  latest_ = std::move(latest);
}

bool Shader::Registration::Wait() const {
  std::shared_future<bool> latest;
  {
    std::scoped_lock lock(mutex_);
    latest = latest_;
  }
  return !latest.valid() || latest.get();
}

bool Shader::Registration::HasFailed() const {
  std::scoped_lock lock(mutex_);
  return latest_.valid() &&
         latest_.wait_for(std::chrono::seconds(0)) ==
             std::future_status::ready &&
         !latest_.get();
}

const std::shared_ptr<Shader::Registration>& Shader::GetRegistration() const {
  return registration_;
}

void Shader::ScheduleRegistration(Context& context) {
  if (!is_dirty_ && !registration_->HasFailed()) {
    return;
  }
  is_dirty_ = false;

  auto promise = std::make_shared<impeller::NoExceptionPromise<bool>>();
  registration_->Set(promise->get_future().share());
  auto task = [context = context.GetContextShared(), name = GetScopedName(),
               stage = stage_, code = code_mapping_, promise]() {
    auto& library = *context->GetShaderLibrary();
    // After a reload an earlier version still occupies the scoped slot.
    // Evict it, and the pipelines built from it, before registering the new
    // code. Mirrors `RuntimeEffectContents::RegisterShader`.
    if (auto existing = library.GetFunction(name, stage)) {
      context->GetPipelineLibrary()->RemovePipelinesWithEntryPoint(existing);
      library.UnregisterFunction(name, stage);
    }
    library.RegisterFunction(name, stage, code, [promise](bool result) {
      promise->set_value(result);
    });
  };
  if (auto runner = GetReplayTaskRunner()) {
    runner->PostTask(std::move(task));
  } else {
    task();
  }
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

const std::string& Shader::GetEntrypoint() const {
  return entrypoint_;
}

const std::vector<impeller::DescriptorSetLayout>&
Shader::GetDescriptorSetLayouts() const {
  return descriptor_set_layouts_;
}

const Shader::UniformBinding* Shader::GetUniformStruct(
    const std::string& name) const {
  auto uniform = reflection_->uniform_structs.find(name);
  if (uniform == reflection_->uniform_structs.end()) {
    return nullptr;
  }
  return &uniform->second;
}

const Shader::TextureBinding* Shader::GetUniformTexture(
    const std::string& name) const {
  auto uniform = reflection_->uniform_textures.find(name);
  if (uniform == reflection_->uniform_textures.end()) {
    return nullptr;
  }
  return &uniform->second;
}

int Shader::GetUniformStructIndex(const std::string& name) const {
  const UniformBinding* binding = GetUniformStruct(name);
  if (binding == nullptr) {
    return -1;
  }
  const auto& order = reflection_->uniform_struct_order;
  for (size_t i = 0; i < order.size(); i++) {
    if (order[i] == binding) {
      return static_cast<int>(i);
    }
  }
  return -1;
}

const Shader::UniformBinding* Shader::GetUniformStructAt(int index) const {
  const auto& order = reflection_->uniform_struct_order;
  if (index < 0 || static_cast<size_t>(index) >= order.size()) {
    return nullptr;
  }
  return order[index];
}

int Shader::GetUniformTextureIndex(const std::string& name) const {
  const TextureBinding* binding = GetUniformTexture(name);
  if (binding == nullptr) {
    return -1;
  }
  const auto& order = reflection_->uniform_texture_order;
  for (size_t i = 0; i < order.size(); i++) {
    if (order[i] == binding) {
      return static_cast<int>(i);
    }
  }
  return -1;
}

const Shader::TextureBinding* Shader::GetUniformTextureAt(int index) const {
  const auto& order = reflection_->uniform_texture_order;
  if (index < 0 || static_cast<size_t>(index) >= order.size()) {
    return nullptr;
  }
  return order[index];
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

int InternalFlutterGpu_Shader_GetUniformStructIndex(
    flutter::gpu::Shader* wrapper,
    Dart_Handle struct_name_handle) {
  auto name = tonic::StdStringFromDart(struct_name_handle);
  return wrapper->GetUniformStructIndex(name);
}

int InternalFlutterGpu_Shader_GetUniformTextureIndex(
    flutter::gpu::Shader* wrapper,
    Dart_Handle texture_name_handle) {
  auto name = tonic::StdStringFromDart(texture_name_handle);
  return wrapper->GetUniformTextureIndex(name);
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
