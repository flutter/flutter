// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/binding_helpers_vk.h"
#include "fml/status.h"
#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/compute_pipeline_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/compute_command.h"
#include "vulkan/vulkan_core.h"

namespace impeller {

// Warning: if any of the constant values or layouts are changed in the
// framebuffer fetch shader, then this input binding may need to be
// manually changed.
static constexpr size_t kMagicSubpassInputBinding = 64;

static bool BindImages(
    const Bindings& bindings,
    Allocator& allocator,
    const std::shared_ptr<CommandEncoderVK>& encoder,
    vk::DescriptorSet& vk_desc_set,
    std::array<vk::DescriptorImageInfo, kMaxBindings>& image_workspace,
    size_t& image_offset,
    std::array<vk::WriteDescriptorSet, kMaxBindings + kMaxBindings>&
        write_workspace,
    size_t& write_offset) {
  for (const TextureAndSampler& data : bindings.sampled_images) {
    const std::shared_ptr<const Texture>& texture = data.texture.resource;
    const TextureVK& texture_vk = TextureVK::Cast(*texture);
    const SamplerVK& sampler = SamplerVK::Cast(*data.sampler);

    if (!encoder->Track(texture) ||
        !encoder->Track(sampler.GetSharedSampler())) {
      return false;
    }

    const SampledImageSlot& slot = data.slot;

    vk::DescriptorImageInfo image_info;
    image_info.imageLayout = vk::ImageLayout::eShaderReadOnlyOptimal;
    image_info.sampler = sampler.GetSampler();
    image_info.imageView = texture_vk.GetImageView();
    image_workspace[image_offset++] = image_info;

    vk::WriteDescriptorSet write_set;
    write_set.dstSet = vk_desc_set;
    write_set.dstBinding = slot.binding;
    write_set.descriptorCount = 1u;
    write_set.descriptorType = vk::DescriptorType::eCombinedImageSampler;
    write_set.pImageInfo = &image_workspace[image_offset - 1];

    write_workspace[write_offset++] = write_set;
  }

  return true;
};

static bool BindBuffers(
    const Bindings& bindings,
    Allocator& allocator,
    const std::shared_ptr<CommandEncoderVK>& encoder,
    vk::DescriptorSet& vk_desc_set,
    const std::vector<DescriptorSetLayout>& desc_set,
    std::array<vk::DescriptorBufferInfo, kMaxBindings>& buffer_workspace,
    size_t& buffer_offset,
    std::array<vk::WriteDescriptorSet, kMaxBindings + kMaxBindings>&
        write_workspace,
    size_t& write_offset) {
  for (const BufferAndUniformSlot& data : bindings.buffers) {
    const std::shared_ptr<const DeviceBuffer>& device_buffer =
        data.view.resource.buffer;

    auto buffer = DeviceBufferVK::Cast(*device_buffer).GetBuffer();
    if (!buffer) {
      return false;
    }

    if (!encoder->Track(device_buffer)) {
      return false;
    }

    uint32_t offset = data.view.resource.range.offset;

    vk::DescriptorBufferInfo buffer_info;
    buffer_info.buffer = buffer;
    buffer_info.offset = offset;
    buffer_info.range = data.view.resource.range.length;
    buffer_workspace[buffer_offset++] = buffer_info;

    // TODO(jonahwilliams): remove this part by storing more data in
    // ShaderUniformSlot.
    const ShaderUniformSlot& uniform = data.slot;
    auto layout_it =
        std::find_if(desc_set.begin(), desc_set.end(),
                     [&uniform](const DescriptorSetLayout& layout) {
                       return layout.binding == uniform.binding;
                     });
    if (layout_it == desc_set.end()) {
      VALIDATION_LOG << "Failed to get descriptor set layout for binding "
                     << uniform.binding;
      return false;
    }
    auto layout = *layout_it;

    vk::WriteDescriptorSet write_set;
    write_set.dstSet = vk_desc_set;
    write_set.dstBinding = uniform.binding;
    write_set.descriptorCount = 1u;
    write_set.descriptorType = ToVKDescriptorType(layout.descriptor_type);
    write_set.pBufferInfo = &buffer_workspace[buffer_offset - 1];

    write_workspace[write_offset++] = write_set;
  }
  return true;
}

fml::StatusOr<vk::DescriptorSet> AllocateAndBindDescriptorSets(
    const ContextVK& context,
    const std::shared_ptr<CommandEncoderVK>& encoder,
    Allocator& allocator,
    const Command& command,
    const TextureVK& input_attachment,
    std::array<vk::DescriptorImageInfo, kMaxBindings>& image_workspace,
    std::array<vk::DescriptorBufferInfo, kMaxBindings>& buffer_workspace,
    std::array<vk::WriteDescriptorSet, kMaxBindings + kMaxBindings>&
        write_workspace) {
  auto descriptor_result = encoder->AllocateDescriptorSets(
      PipelineVK::Cast(*command.pipeline).GetDescriptorSetLayout(), context);
  if (!descriptor_result.ok()) {
    return descriptor_result.status();
  }
  vk::DescriptorSet descriptor_set = descriptor_result.value();

  size_t buffer_offset = 0u;
  size_t image_offset = 0u;
  size_t write_offset = 0u;

  auto& pipeline_descriptor = command.pipeline->GetDescriptor();
  auto& desc_set =
      pipeline_descriptor.GetVertexDescriptor()->GetDescriptorSetLayouts();

  if (!BindBuffers(command.vertex_bindings, allocator, encoder, descriptor_set,
                   desc_set, buffer_workspace, buffer_offset, write_workspace,
                   write_offset) ||
      !BindBuffers(command.fragment_bindings, allocator, encoder,
                   descriptor_set, desc_set, buffer_workspace, buffer_offset,
                   write_workspace, write_offset) ||
      !BindImages(command.fragment_bindings, allocator, encoder, descriptor_set,
                  image_workspace, image_offset, write_workspace,
                  write_offset)) {
    return fml::Status(fml::StatusCode::kUnknown,
                       "Failed to bind texture or buffer.");
  }

  if (pipeline_descriptor.UsesSubpassInput()) {
    vk::DescriptorImageInfo image_info;
    image_info.imageLayout = vk::ImageLayout::eGeneral;
    image_info.sampler = VK_NULL_HANDLE;
    image_info.imageView = input_attachment.GetImageView();
    image_workspace[image_offset++] = image_info;

    vk::WriteDescriptorSet write_set;
    write_set.dstSet = descriptor_set;
    write_set.dstBinding = kMagicSubpassInputBinding;
    write_set.descriptorCount = 1u;
    write_set.descriptorType = vk::DescriptorType::eInputAttachment;
    write_set.pImageInfo = &image_workspace[image_offset - 1];

    write_workspace[write_offset++] = write_set;
  }

  context.GetDevice().updateDescriptorSets(write_offset, write_workspace.data(),
                                           0u, {});

  return descriptor_set;
}

fml::StatusOr<vk::DescriptorSet> AllocateAndBindDescriptorSets(
    const ContextVK& context,
    const std::shared_ptr<CommandEncoderVK>& encoder,
    Allocator& allocator,
    const ComputeCommand& command,
    std::array<vk::DescriptorImageInfo, kMaxBindings>& image_workspace,
    std::array<vk::DescriptorBufferInfo, kMaxBindings>& buffer_workspace,
    std::array<vk::WriteDescriptorSet, kMaxBindings + kMaxBindings>&
        write_workspace) {
  auto descriptor_result = encoder->AllocateDescriptorSets(
      ComputePipelineVK::Cast(*command.pipeline).GetDescriptorSetLayout(),
      context);
  if (!descriptor_result.ok()) {
    return descriptor_result.status();
  }
  auto descriptor_set = descriptor_result.value();

  size_t buffer_offset = 0u;
  size_t image_offset = 0u;
  size_t write_offset = 0u;

  auto& pipeline_descriptor = command.pipeline->GetDescriptor();
  auto& desc_set = pipeline_descriptor.GetDescriptorSetLayouts();

  if (!BindBuffers(command.bindings, allocator, encoder, descriptor_set,
                   desc_set, buffer_workspace, buffer_offset, write_workspace,
                   write_offset) ||
      !BindImages(command.bindings, allocator, encoder, descriptor_set,
                  image_workspace, image_offset, write_workspace,
                  write_offset)) {
    return fml::Status(fml::StatusCode::kUnknown,
                       "Failed to bind texture or buffer.");
  }
  context.GetDevice().updateDescriptorSets(write_offset, write_workspace.data(),
                                           0u, {});

  return descriptor_set;
}

}  // namespace impeller
