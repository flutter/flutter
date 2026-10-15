// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/binding_set.h"

#include <utility>

#include "flutter/lib/gpu/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/renderer/sampler_library.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, BindingSet);

BindingSet::BindingSet() = default;

BindingSet::~BindingSet() = default;

// Whether a shader stage can take resource bindings from a render pass.
static bool IsRenderStage(impeller::ShaderStage stage) {
  return stage == impeller::ShaderStage::kVertex ||
         stage == impeller::ShaderStage::kFragment;
}

void BindingSet::RetainReflection(Shader& shader) {
  const auto& reflection = shader.GetReflection();
  for (const auto& retained : contents_.reflections) {
    if (retained == reflection) {
      return;
    }
  }
  contents_.reflections.push_back(reflection);
}

std::shared_ptr<const BindingSet::Contents> BindingSet::Snapshot() {
  if (!snapshot_) {
    snapshot_ = std::make_shared<const Contents>(contents_);
  }
  return snapshot_;
}

bool BindingSet::AddUniform(
    Shader& shader,
    int uniform_struct_index,
    const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
    size_t offset_in_bytes,
    size_t length_in_bytes) {
  if (!IsRenderStage(shader.GetShaderStage())) {
    return false;
  }
  const Shader::UniformBinding* uniform_struct =
      shader.GetUniformStructAt(uniform_struct_index);
  if (!uniform_struct) {
    return false;
  }
  if (!buffer || offset_in_bytes + length_in_bytes >
                     buffer->GetDeviceBufferDescriptor().size) {
    return false;
  }

  RetainReflection(shader);
  snapshot_.reset();
  contents_.buffer_bindings.push_back(BufferBinding{
      .stage = shader.GetShaderStage(),
      .slot = uniform_struct->slot,
      .metadata = &uniform_struct->metadata,
      .view = impeller::BufferView(
          buffer, impeller::Range(offset_in_bytes, length_in_bytes)),
  });
  return true;
}

bool BindingSet::AddTexture(Shader& shader,
                            int uniform_texture_index,
                            std::shared_ptr<const impeller::Texture> texture,
                            const impeller::SamplerDescriptor& sampler) {
  if (!IsRenderStage(shader.GetShaderStage())) {
    return false;
  }
  const Shader::TextureBinding* texture_binding =
      shader.GetUniformTextureAt(uniform_texture_index);
  if (!texture_binding) {
    return false;
  }
  if (!texture) {
    return false;
  }

  RetainReflection(shader);
  snapshot_.reset();
  contents_.texture_bindings.push_back(TextureBinding{
      .stage = shader.GetShaderStage(),
      .slot = texture_binding->slot,
      .metadata = &texture_binding->metadata,
      .texture = std::move(texture),
      .sampler = sampler,
  });
  return true;
}

void BindingSet::Clear() {
  contents_ = {};
  snapshot_.reset();
}

const std::vector<BindingSet::BufferBinding>& BindingSet::GetBufferBindings()
    const {
  return contents_.buffer_bindings;
}

const std::vector<BindingSet::TextureBinding>& BindingSet::GetTextureBindings()
    const {
  return contents_.texture_bindings;
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

void InternalFlutterGpu_BindingSet_Initialize(Dart_Handle wrapper) {
  auto res = fml::MakeRefCounted<flutter::gpu::BindingSet>();
  res->AssociateWithDartWrapper(wrapper);
}

bool InternalFlutterGpu_BindingSet_AddUniform(
    flutter::gpu::BindingSet* wrapper,
    flutter::gpu::Shader* shader,
    int uniform_struct_index,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes) {
  if (offset_in_bytes < 0 || length_in_bytes < 0) {
    return false;
  }
  return wrapper->AddUniform(*shader, uniform_struct_index,
                             device_buffer->GetBuffer(), offset_in_bytes,
                             length_in_bytes);
}

bool InternalFlutterGpu_BindingSet_AddTexture(
    flutter::gpu::BindingSet* wrapper,
    [[maybe_unused]] flutter::gpu::Context* context,
    flutter::gpu::Shader* shader,
    int uniform_texture_index,
    flutter::gpu::Texture* texture,
    int min_filter,
    int mag_filter,
    int mip_filter,
    int width_address_mode,
    int height_address_mode,
    int max_anisotropy) {
  const impeller::SamplerDescriptor sampler_desc =
      flutter::gpu::ToImpellerSamplerDescriptor(
          min_filter, mag_filter, mip_filter, width_address_mode,
          height_address_mode, max_anisotropy);
  return wrapper->AddTexture(*shader, uniform_texture_index,
                             texture->GetTexture(), sampler_desc);
}

void InternalFlutterGpu_BindingSet_Clear(flutter::gpu::BindingSet* wrapper) {
  wrapper->Clear();
}
