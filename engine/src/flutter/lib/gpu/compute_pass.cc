// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/compute_pass.h"

#include <utility>
#include <vector>

#include "flutter/lib/gpu/formats.h"
#include "impeller/core/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/sampler_library.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"
#include "third_party/abseil-cpp/absl/strings/str_cat.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, ComputePass);

ComputePass::ComputePass() = default;

ComputePass::~ComputePass() = default;

absl::Status ComputePass::Begin(flutter::gpu::CommandBuffer& command_buffer) {
  compute_pass_ = command_buffer.CreateComputePass();
  if (!compute_pass_) {
    return absl::InternalError("Failed to begin ComputePass.");
  }
  context_ = command_buffer.GetContext();
  command_buffer_ = fml::Ref(&command_buffer);
  return absl::OkStatus();
}

absl::Status ComputePass::End() {
  if (!command_buffer_) {
    return absl::OkStatus();
  }
  absl::Status status = command_buffer_->EndComputePass(compute_pass_.get());
  command_buffer_ = nullptr;
  return status;
}

const std::shared_ptr<impeller::Context>& ComputePass::GetContext() const {
  return context_;
}

void ComputePass::SetPipeline(fml::RefPtr<ComputePipeline> pipeline) {
  // On debug this makes a difference, but not on release builds.
  // NOLINTNEXTLINE(performance-move-const-arg)
  pipeline_ = std::move(pipeline);
}

// Checks that `binding` exists and belongs to a compute shader.
static absl::Status ValidateBinding(const Shader& shader, const void* binding) {
  if (!binding) {
    return absl::InvalidArgumentError(
        absl::StrCat("The shader '", shader.GetEntrypoint(),
                     "' does not declare the binding."));
  }
  if (shader.GetShaderStage() != impeller::ShaderStage::kCompute) {
    return absl::InvalidArgumentError(absl::StrCat(
        "The shader '", shader.GetEntrypoint(), "' is not a compute shader."));
  }
  return absl::OkStatus();
}

// Checks that `buffer` is not null and holds the view.
static absl::Status ValidateView(
    const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
    size_t offset_in_bytes,
    size_t length_in_bytes) {
  if (!buffer) {
    return absl::InvalidArgumentError("The buffer is null.");
  }
  const size_t size = buffer->GetDeviceBufferDescriptor().size;
  if (offset_in_bytes > size || length_in_bytes > size - offset_in_bytes) {
    return absl::OutOfRangeError(absl::StrCat(
        "The view of ", length_in_bytes, " bytes at offset ", offset_in_bytes,
        " runs past the end of the ", size, "-byte buffer."));
  }
  return absl::OkStatus();
}

absl::Status ComputePass::BindUniform(
    const Shader& shader,
    const Shader::UniformBinding* binding,
    const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
    size_t offset_in_bytes,
    size_t length_in_bytes) {
  if (absl::Status status = ValidateBinding(shader, binding); !status.ok()) {
    return status;
  }
  if (absl::Status status =
          ValidateView(buffer, offset_in_bytes, length_in_bytes);
      !status.ok()) {
    return status;
  }
  buffer_bindings_.insert_or_assign(
      &binding->metadata,
      impeller::BufferView(buffer,
                           impeller::Range(offset_in_bytes, length_in_bytes)));
  bindings_dirty_ = true;
  return absl::OkStatus();
}

absl::Status ComputePass::BindStorageBuffer(
    const Shader& shader,
    const Shader::StorageBufferBinding* binding,
    const std::shared_ptr<const impeller::DeviceBuffer>& buffer,
    size_t offset_in_bytes,
    size_t length_in_bytes) {
  if (absl::Status status = ValidateBinding(shader, binding); !status.ok()) {
    return status;
  }
  if (absl::Status status =
          ValidateView(buffer, offset_in_bytes, length_in_bytes);
      !status.ok()) {
    return status;
  }
  buffer_bindings_.insert_or_assign(
      &binding->metadata,
      impeller::BufferView(buffer,
                           impeller::Range(offset_in_bytes, length_in_bytes)));
  bindings_dirty_ = true;
  return absl::OkStatus();
}

absl::Status ComputePass::BindTexture(
    const Shader& shader,
    const Shader::TextureBinding* binding,
    std::shared_ptr<const impeller::Texture> texture,
    impeller::raw_ptr<const impeller::Sampler> sampler) {
  if (absl::Status status = ValidateBinding(shader, binding); !status.ok()) {
    return status;
  }
  if (!texture) {
    return absl::InvalidArgumentError("The texture is null.");
  }
  if (!sampler) {
    return absl::InvalidArgumentError("The sampler is null.");
  }
  texture_bindings_.insert_or_assign(
      &binding->metadata, TextureBinding{
                              .texture = std::move(texture),
                              // NOLINTNEXTLINE(performance-move-const-arg)
                              .sampler = std::move(sampler),
                          });
  bindings_dirty_ = true;
  return absl::OkStatus();
}

void ComputePass::BindSet(size_t slot, fml::RefPtr<BindingSet> set) {
  if (slot >= kMaxBindingSets) {
    return;
  }
  // On debug this makes a difference, but not on release builds.
  // NOLINTNEXTLINE(performance-move-const-arg)
  binding_sets_[slot] = std::move(set);
  bindings_dirty_ = true;
}

void ComputePass::ClearBindings() {
  buffer_bindings_.clear();
  texture_bindings_.clear();
  for (auto& set : binding_sets_) {
    set = nullptr;
  }
  bindings_dirty_ = true;
}

// Returns the entry of `bindings` that fills the binding described by
// `metadata`, searching the binding sets from the highest slot down, so that
// a higher slot wins where two sets hold the same binding.
template <typename T>
static const T* FindInSets(const std::array<fml::RefPtr<BindingSet>,
                                            ComputePass::kMaxBindingSets>& sets,
                           const std::vector<T>& (BindingSet::*bindings)()
                               const,
                           const impeller::ShaderMetadata* metadata) {
  for (auto set = sets.rbegin(); set != sets.rend(); ++set) {
    if (!*set) {
      continue;
    }
    for (const T& binding : ((**set).*bindings)()) {
      if (binding.metadata == metadata) {
        return &binding;
      }
    }
  }
  return nullptr;
}

// Whether the shader compiler removed the resource at this backend index
// because the shader never uses it. Metal does this, and reflection stamps
// the index with a sentinel. The binding is still required, so that every
// backend accepts the same bindings, but there is nothing to hand the
// backend.
static bool IsOptimizedOut(size_t backend_index) {
  return backend_index == impeller::kOptimizedOutBinding;
}

absl::Status ComputePass::ApplyBindings(const Shader& shader) {
  auto missing = [&shader](std::string_view kind, std::string_view name) {
    return absl::FailedPreconditionError(absl::StrCat(
        "The compute shader '", shader.GetEntrypoint(), "' declares the ", kind,
        " '", name, "', but nothing is bound to it."));
  };

  for (int i = 0;; i++) {
    const Shader::UniformBinding* binding = shader.GetUniformStructAt(i);
    if (!binding) {
      break;
    }
    const impeller::BufferView* view = nullptr;
    if (auto found = buffer_bindings_.find(&binding->metadata);
        found != buffer_bindings_.end()) {
      view = &found->second;
    } else if (const auto* set_binding =
                   FindInSets(binding_sets_, &BindingSet::GetBufferBindings,
                              &binding->metadata)) {
      view = &set_binding->view;
    }
    if (!view) {
      return missing("uniform struct", binding->metadata.name);
    }
    if (IsOptimizedOut(binding->slot.ext_res_0)) {
      continue;
    }
    compute_pass_->BindResource(impeller::ShaderStage::kCompute,
                                impeller::DescriptorType::kUniformBuffer,
                                binding->slot, &binding->metadata, *view);
  }

  for (int i = 0;; i++) {
    const Shader::StorageBufferBinding* binding = shader.GetStorageBufferAt(i);
    if (!binding) {
      break;
    }
    const impeller::BufferView* view = nullptr;
    if (auto found = buffer_bindings_.find(&binding->metadata);
        found != buffer_bindings_.end()) {
      view = &found->second;
    } else if (const auto* set_binding = FindInSets(
                   binding_sets_, &BindingSet::GetStorageBufferBindings,
                   &binding->metadata)) {
      view = &set_binding->view;
    }
    if (!view) {
      return missing("storage buffer", binding->metadata.name);
    }
    if (IsOptimizedOut(binding->slot.ext_res_0)) {
      continue;
    }
    compute_pass_->BindResource(impeller::ShaderStage::kCompute,
                                impeller::DescriptorType::kStorageBuffer,
                                binding->slot, &binding->metadata, *view);
  }

  for (int i = 0;; i++) {
    const Shader::TextureBinding* binding = shader.GetUniformTextureAt(i);
    if (!binding) {
      break;
    }
    std::shared_ptr<const impeller::Texture> texture;
    impeller::raw_ptr<const impeller::Sampler> sampler;
    if (auto found = texture_bindings_.find(&binding->metadata);
        found != texture_bindings_.end()) {
      texture = found->second.texture;
      sampler = found->second.sampler;
    } else if (const auto* set_binding =
                   FindInSets(binding_sets_, &BindingSet::GetTextureBindings,
                              &binding->metadata)) {
      texture = set_binding->texture;
      sampler = set_binding->sampler;
    } else {
      return missing("texture", binding->metadata.name);
    }
    if (IsOptimizedOut(binding->slot.texture_index)) {
      continue;
    }
    compute_pass_->BindResource(impeller::ShaderStage::kCompute,
                                impeller::DescriptorType::kSampledImage,
                                binding->slot, &binding->metadata,
                                std::move(texture), sampler);
  }

  return absl::OkStatus();
}

absl::Status ComputePass::Dispatch(std::array<uint32_t, 3> workgroup_count) {
  if (!command_buffer_ || !compute_pass_) {
    return absl::FailedPreconditionError("The ComputePass is not recording.");
  }
  // Nothing to do, like a draw with no vertices.
  if (workgroup_count[0] == 0u || workgroup_count[1] == 0u ||
      workgroup_count[2] == 0u) {
    return absl::OkStatus();
  }
  if (!pipeline_) {
    return absl::FailedPreconditionError("No ComputePipeline is bound.");
  }

  const std::array<uint32_t, 3> max_count =
      context_->GetCapabilities()->GetMaximumComputeWorkgroupCount();
  if (workgroup_count[0] > max_count[0] || workgroup_count[1] > max_count[1] ||
      workgroup_count[2] > max_count[2]) {
    return absl::OutOfRangeError(absl::StrCat(
        "The workgroup count ", workgroup_count[0], "x", workgroup_count[1],
        "x", workgroup_count[2], " exceeds the device maximum of ",
        max_count[0], "x", max_count[1], "x", max_count[2], "."));
  }

  absl::StatusOr<std::shared_ptr<BackendComputePipeline>> pipeline_or =
      pipeline_->GetOrCreatePipeline(*context_);
  if (!pipeline_or.ok()) {
    return pipeline_or.status();
  }
  std::shared_ptr<BackendComputePipeline> pipeline =
      std::move(pipeline_or).value();
  if (pipeline != bound_pipeline_) {
    compute_pass_->SetPipeline(pipeline);
    bound_pipeline_ = pipeline;
    // A hot reload can replace the pipeline while this command buffer is
    // still running, and Vulkan does not track pipelines in its command
    // buffers, so hold this one until the command buffer completes.
    command_buffer_->AddCompletionCallback(
        [pipeline](impeller::CommandBuffer::Status) {});
    // Rebind for the new pipeline's shader, which can declare other bindings
    // at the same indices.
    bindings_dirty_ = true;
  }
  if (bindings_dirty_) {
    if (absl::Status status = ApplyBindings(*pipeline_->GetShader());
        !status.ok()) {
      return status;
    }
    bindings_dirty_ = false;
  }

  if (fml::Status status = compute_pass_->Compute(workgroup_count);
      !status.ok()) {
    return absl::InternalError(status.message());
  }
  return absl::OkStatus();
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

void InternalFlutterGpu_ComputePass_Initialize(Dart_Handle wrapper) {
  auto res = fml::MakeRefCounted<flutter::gpu::ComputePass>();
  res->AssociateWithDartWrapper(wrapper);
}

// Returns null for OK, or the error message for Dart to throw.
static Dart_Handle ToDartError(const absl::Status& status) {
  if (status.ok()) {
    return Dart_Null();
  }
  return tonic::ToDart(std::string(status.message()));
}

Dart_Handle InternalFlutterGpu_ComputePass_Begin(
    flutter::gpu::ComputePass* wrapper,
    flutter::gpu::CommandBuffer* command_buffer) {
  return ToDartError(wrapper->Begin(*command_buffer));
}

Dart_Handle InternalFlutterGpu_ComputePass_End(
    flutter::gpu::ComputePass* wrapper) {
  return ToDartError(wrapper->End());
}

void InternalFlutterGpu_ComputePass_BindPipeline(
    flutter::gpu::ComputePass* wrapper,
    flutter::gpu::ComputePipeline* pipeline) {
  wrapper->SetPipeline(fml::RefPtr<flutter::gpu::ComputePipeline>(pipeline));
}

bool InternalFlutterGpu_ComputePass_BindUniformIndexed(
    flutter::gpu::ComputePass* wrapper,
    flutter::gpu::Shader* shader,
    int uniform_struct_index,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes) {
  if (offset_in_bytes < 0 || length_in_bytes < 0) {
    return false;
  }
  return wrapper
      ->BindUniform(*shader, shader->GetUniformStructAt(uniform_struct_index),
                    device_buffer->GetBuffer(), offset_in_bytes,
                    length_in_bytes)
      .ok();
}

bool InternalFlutterGpu_ComputePass_BindStorageBufferIndexed(
    flutter::gpu::ComputePass* wrapper,
    flutter::gpu::Shader* shader,
    int storage_buffer_index,
    flutter::gpu::DeviceBuffer* device_buffer,
    int offset_in_bytes,
    int length_in_bytes) {
  if (offset_in_bytes < 0 || length_in_bytes < 0) {
    return false;
  }
  return wrapper
      ->BindStorageBuffer(
          *shader, shader->GetStorageBufferAt(storage_buffer_index),
          device_buffer->GetBuffer(), offset_in_bytes, length_in_bytes)
      .ok();
}

bool InternalFlutterGpu_ComputePass_BindTextureIndexed(
    flutter::gpu::ComputePass* wrapper,
    flutter::gpu::Shader* shader,
    int uniform_texture_index,
    flutter::gpu::Texture* texture,
    int min_filter,
    int mag_filter,
    int mip_filter,
    int width_address_mode,
    int height_address_mode,
    int max_anisotropy) {
  if (!wrapper->GetContext()) {
    return false;
  }
  const impeller::SamplerDescriptor sampler_desc =
      flutter::gpu::ToImpellerSamplerDescriptor(
          min_filter, mag_filter, mip_filter, width_address_mode,
          height_address_mode, max_anisotropy);
  return wrapper
      ->BindTexture(
          *shader, shader->GetUniformTextureAt(uniform_texture_index),
          texture->GetTexture(),
          wrapper->GetContext()->GetSamplerLibrary()->GetSampler(sampler_desc))
      .ok();
}

void InternalFlutterGpu_ComputePass_BindSet(
    flutter::gpu::ComputePass* wrapper,
    flutter::gpu::BindingSet* binding_set,
    int slot) {
  if (slot < 0) {
    return;
  }
  wrapper->BindSet(slot, fml::RefPtr<flutter::gpu::BindingSet>(binding_set));
}

void InternalFlutterGpu_ComputePass_ClearBindings(
    flutter::gpu::ComputePass* wrapper) {
  wrapper->ClearBindings();
}

Dart_Handle InternalFlutterGpu_ComputePass_Dispatch(
    flutter::gpu::ComputePass* wrapper,
    int workgroup_count_x,
    int workgroup_count_y,
    int workgroup_count_z) {
  // Guard the casts to uint32_t; a negative value would wrap.
  if (workgroup_count_x < 0 || workgroup_count_y < 0 || workgroup_count_z < 0) {
    return tonic::ToDart("Workgroup counts must not be negative.");
  }
  return ToDartError(
      wrapper->Dispatch({static_cast<uint32_t>(workgroup_count_x),
                         static_cast<uint32_t>(workgroup_count_y),
                         static_cast<uint32_t>(workgroup_count_z)}));
}
