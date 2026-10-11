// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/compute_pass_vk.h"

#include <vector>

#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/compute_pipeline_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "vulkan/vulkan_structs.hpp"

namespace impeller {

ComputePassVK::ComputePassVK(std::shared_ptr<const Context> context,
                             std::shared_ptr<CommandBufferVK> command_buffer)
    : ComputePass(std::move(context)),
      command_buffer_(std::move(command_buffer)) {
  is_valid_ = true;
}

ComputePassVK::~ComputePassVK() = default;

bool ComputePassVK::IsValid() const {
  return is_valid_;
}

void ComputePassVK::OnSetLabel(const std::string& label) {
  if (label.empty()) {
    return;
  }
  label_ = label;
}

// |RenderPass|
void ComputePassVK::SetCommandLabel(std::string_view label) {
#ifdef IMPELLER_DEBUG
  command_buffer_->PushDebugGroup(label);
  has_label_ = true;
#endif  // IMPELLER_DEBUG
}

void ComputePassVK::PopCommandLabel() {
#ifdef IMPELLER_DEBUG
  if (has_label_) {
    command_buffer_->PopDebugGroup();
  }
  has_label_ = false;
#endif  // IMPELLER_DEBUG
}

// |ComputePass|
void ComputePassVK::SetPipeline(
    const std::shared_ptr<Pipeline<ComputePipelineDescriptor>>& pipeline) {
  if (!pipeline) {
    return;
  }
  const auto& pipeline_vk = ComputePipelineVK::Cast(*pipeline);
  command_buffer_->GetCommandBuffer().bindPipeline(
      vk::PipelineBindPoint::eCompute, pipeline_vk.GetPipeline());
  pipeline_ = pipeline;
  descriptor_set_dirty_ = true;
}

absl::Status ComputePassVK::BindDescriptorSet() {
  const ContextVK& context_vk = ContextVK::Cast(*context_);
  const auto& pipeline_vk = ComputePipelineVK::Cast(*pipeline_);

  auto descriptor_result = command_buffer_->AllocateDescriptorSets(
      pipeline_vk.GetDescriptorSetLayout(), pipeline_vk.GetPipelineKey(),
      context_vk);
  if (!descriptor_result.ok()) {
    return descriptor_result.status();
  }
  vk::DescriptorSet descriptor_set = descriptor_result.value();

  // Write every binding the pipeline declares that the pass has a resource
  // for. Bindings made for another pipeline in the pass are kept for later
  // dispatches but not written here.
  std::vector<vk::WriteDescriptorSet> writes;
  for (const DescriptorSetLayout& layout :
       pipeline_->GetDescriptor().GetDescriptorSetLayouts()) {
    auto found = bindings_.find(layout.binding);
    if (found == bindings_.end() ||
        found->second.type != layout.descriptor_type) {
      continue;
    }
    const BoundResource& resource = found->second;
    vk::WriteDescriptorSet write_set;
    write_set.dstSet = descriptor_set;
    write_set.dstBinding = layout.binding;
    write_set.descriptorCount = 1u;
    write_set.descriptorType = ToVKDescriptorType(resource.type);
    if (resource.image_info.has_value()) {
      write_set.pImageInfo = &resource.image_info.value();
    } else if (resource.buffer_info.has_value()) {
      write_set.pBufferInfo = &resource.buffer_info.value();
    } else {
      continue;
    }
    writes.push_back(write_set);
  }

  context_vk.GetDevice().updateDescriptorSets(writes.size(), writes.data(), 0u,
                                              {});
  command_buffer_->GetCommandBuffer().bindDescriptorSets(
      vk::PipelineBindPoint::eCompute,  // bind point
      pipeline_vk.GetPipelineLayout(),  // layout
      0,                                // first set
      1,                                // set count
      &descriptor_set,                  // sets
      0,                                // offset count
      nullptr                           // offsets
  );
  descriptor_set_dirty_ = false;
  return absl::OkStatus();
}

// |ComputePass|
absl::Status ComputePassVK::Compute(std::array<uint32_t, 3> workgroup_count) {
  // A dispatch with no workgroups does nothing, like a draw with no vertices.
  if (workgroup_count[0] == 0u || workgroup_count[1] == 0u ||
      workgroup_count[2] == 0u) {
    PopCommandLabel();
    return absl::OkStatus();
  }

  if (!pipeline_) {
    PopCommandLabel();
    return absl::Status(absl::StatusCode::kCancelled,
                       "No compute pipeline is bound.");
  }

  if (descriptor_set_dirty_) {
    if (auto status = BindDescriptorSet(); !status.ok()) {
      PopCommandLabel();
      return status;
    }
  }

  // Make the writes of earlier dispatches in the pass visible to this one,
  // and order this dispatch's writes after their reads and writes.
  if (has_dispatched_) {
    vk::MemoryBarrier barrier;
    barrier.srcAccessMask = vk::AccessFlagBits::eShaderWrite;
    barrier.dstAccessMask =
        vk::AccessFlagBits::eShaderRead | vk::AccessFlagBits::eShaderWrite;
    command_buffer_->GetCommandBuffer().pipelineBarrier(
        vk::PipelineStageFlagBits::eComputeShader,
        vk::PipelineStageFlagBits::eComputeShader, {}, 1, &barrier, 0, {}, 0,
        {});
  }
  has_dispatched_ = true;

  // The arguments are workgroup counts. The per-workgroup invocation count (the
  // local size) is baked into the shader module, so dispatch the counts
  // directly.
  command_buffer_->GetCommandBuffer().dispatch(
      workgroup_count[0], workgroup_count[1], workgroup_count[2]);

  PopCommandLabel();
  return absl::OkStatus();
}

// |ResourceBinder|
bool ComputePassVK::BindResource(ShaderStage stage,
                                 DescriptorType type,
                                 const ShaderUniformSlot& slot,
                                 const ShaderMetadata* metadata,
                                 BufferView view) {
  return BindResource(slot.binding, type, view);
}

// |ResourceBinder|
bool ComputePassVK::BindResource(ShaderStage stage,
                                 DescriptorType type,
                                 const SampledImageSlot& slot,
                                 const ShaderMetadata* metadata,
                                 std::shared_ptr<const Texture> texture,
                                 raw_ptr<const Sampler> sampler) {
  if (!texture || !texture->IsValid() || !sampler) {
    return false;
  }
  const TextureVK& texture_vk = TextureVK::Cast(*texture);
  const SamplerVK& sampler_vk = SamplerVK::Cast(*sampler);

  if (!command_buffer_->Track(texture)) {
    return false;
  }

  vk::DescriptorImageInfo image_info;
  image_info.imageLayout = vk::ImageLayout::eShaderReadOnlyOptimal;
  image_info.sampler = sampler_vk.GetSampler();
  image_info.imageView = texture_vk.GetSampledImageView();

  bindings_[static_cast<uint32_t>(slot.binding)] = {.type = type,
                                                    .image_info = image_info};
  descriptor_set_dirty_ = true;
  return true;
}

bool ComputePassVK::BindResource(size_t binding,
                                 DescriptorType type,
                                 BufferView view) {
  if (!view.GetBuffer()) {
    return false;
  }
  auto buffer = DeviceBufferVK::Cast(*view.GetBuffer()).GetBuffer();
  if (!buffer) {
    return false;
  }

  std::shared_ptr<const DeviceBuffer> device_buffer = view.TakeBuffer();
  if (device_buffer && !command_buffer_->Track(device_buffer)) {
    return false;
  }

  vk::DescriptorBufferInfo buffer_info;
  buffer_info.buffer = buffer;
  buffer_info.offset = view.GetRange().offset;
  buffer_info.range = view.GetRange().length;

  bindings_[static_cast<uint32_t>(binding)] = {.type = type,
                                               .buffer_info = buffer_info};
  descriptor_set_dirty_ = true;
  return true;
}

// Note:
// https://github.com/KhronosGroup/Vulkan-Docs/wiki/Synchronization-Examples
// Seems to suggest that anything more finely grained than a global memory
// barrier is likely to be weakened into a global barrier. Confirming this on
// mobile devices will require some experimentation.

// |ComputePass|
void ComputePassVK::AddBufferMemoryBarrier() {
  vk::MemoryBarrier barrier;
  barrier.srcAccessMask = vk::AccessFlagBits::eShaderWrite;
  barrier.dstAccessMask = vk::AccessFlagBits::eShaderRead;

  command_buffer_->GetCommandBuffer().pipelineBarrier(
      vk::PipelineStageFlagBits::eComputeShader,
      vk::PipelineStageFlagBits::eComputeShader, {}, 1, &barrier, 0, {}, 0, {});
}

// |ComputePass|
void ComputePassVK::AddTextureMemoryBarrier() {
  vk::MemoryBarrier barrier;
  barrier.srcAccessMask = vk::AccessFlagBits::eShaderWrite;
  barrier.dstAccessMask = vk::AccessFlagBits::eShaderRead;

  command_buffer_->GetCommandBuffer().pipelineBarrier(
      vk::PipelineStageFlagBits::eComputeShader,
      vk::PipelineStageFlagBits::eComputeShader, {}, 1, &barrier, 0, {}, 0, {});
}

// |ComputePass|
bool ComputePassVK::EncodeCommands() const {
  // A pass that dispatched nothing has no writes to order.
  if (!has_dispatched_) {
    return true;
  }
  // Make the pass's writes visible to every later consumer in queue order,
  // whether in this command buffer or a later one: draws reading vertex,
  // index, indirect or uniform data, any shader stage, copies and host reads.
  // Order later writes after the pass's reads and writes too.
  //
  // This does not currently handle image layout transitions, since compute
  // passes do not write images.
  vk::MemoryBarrier barrier;
  barrier.srcAccessMask = vk::AccessFlagBits::eShaderWrite;
  barrier.dstAccessMask =
      vk::AccessFlagBits::eIndirectCommandRead |
      vk::AccessFlagBits::eIndexRead |
      vk::AccessFlagBits::eVertexAttributeRead |
      vk::AccessFlagBits::eUniformRead | vk::AccessFlagBits::eShaderRead |
      vk::AccessFlagBits::eShaderWrite | vk::AccessFlagBits::eTransferRead |
      vk::AccessFlagBits::eTransferWrite | vk::AccessFlagBits::eHostRead;

  command_buffer_->GetCommandBuffer().pipelineBarrier(
      vk::PipelineStageFlagBits::eComputeShader,
      vk::PipelineStageFlagBits::eDrawIndirect |
          vk::PipelineStageFlagBits::eVertexInput |
          vk::PipelineStageFlagBits::eVertexShader |
          vk::PipelineStageFlagBits::eFragmentShader |
          vk::PipelineStageFlagBits::eComputeShader |
          vk::PipelineStageFlagBits::eTransfer |
          vk::PipelineStageFlagBits::eHost,
      {}, 1, &barrier, 0, {}, 0, {});

  return true;
}

}  // namespace impeller
