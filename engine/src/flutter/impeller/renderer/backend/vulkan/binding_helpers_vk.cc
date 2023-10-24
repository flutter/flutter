// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/binding_helpers_vk.h"
#include "fml/status.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/compute_pipeline_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/compute_command.h"

namespace impeller {

static bool BindImages(const Bindings& bindings,
                       Allocator& allocator,
                       const std::shared_ptr<CommandEncoderVK>& encoder,
                       vk::DescriptorSet& vk_desc_set,
                       std::vector<vk::DescriptorImageInfo>& images,
                       std::vector<vk::WriteDescriptorSet>& writes) {
  for (const auto& [index, data] : bindings.sampled_images) {
    auto texture = data.texture.resource;
    const auto& texture_vk = TextureVK::Cast(*texture);
    const SamplerVK& sampler = SamplerVK::Cast(*data.sampler.resource);

    if (!encoder->Track(texture) ||
        !encoder->Track(sampler.GetSharedSampler())) {
      return false;
    }

    const SampledImageSlot& slot = data.slot;

    vk::DescriptorImageInfo image_info;
    image_info.imageLayout = vk::ImageLayout::eShaderReadOnlyOptimal;
    image_info.sampler = sampler.GetSampler();
    image_info.imageView = texture_vk.GetImageView();
    images.push_back(image_info);

    vk::WriteDescriptorSet write_set;
    write_set.dstSet = vk_desc_set;
    write_set.dstBinding = slot.binding;
    write_set.descriptorCount = 1u;
    write_set.descriptorType = vk::DescriptorType::eCombinedImageSampler;
    write_set.pImageInfo = &images.back();

    writes.push_back(write_set);
  }

  return true;
};

static bool BindBuffers(const Bindings& bindings,
                        Allocator& allocator,
                        const std::shared_ptr<CommandEncoderVK>& encoder,
                        vk::DescriptorSet& vk_desc_set,
                        const std::vector<DescriptorSetLayout>& desc_set,
                        std::vector<vk::DescriptorBufferInfo>& buffers,
                        std::vector<vk::WriteDescriptorSet>& writes) {
  for (const auto& [buffer_index, data] : bindings.buffers) {
    const auto& buffer_view = data.view.resource.buffer;

    auto device_buffer = buffer_view->GetDeviceBuffer(allocator);
    if (!device_buffer) {
      VALIDATION_LOG << "Failed to get device buffer for vertex binding";
      return false;
    }

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
    buffers.push_back(buffer_info);

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
    write_set.pBufferInfo = &buffers.back();

    writes.push_back(write_set);
  }
  return true;
}

fml::StatusOr<std::vector<vk::DescriptorSet>> AllocateAndBindDescriptorSets(
    const ContextVK& context,
    const std::shared_ptr<CommandEncoderVK>& encoder,
    const std::vector<Command>& commands) {
  if (commands.empty()) {
    return std::vector<vk::DescriptorSet>{};
  }

  // Step 1: Determine the total number of buffer and sampler descriptor
  // sets required. Collect this information along with the layout information
  // to allocate a correctly sized descriptor pool.
  size_t buffer_count = 0;
  size_t samplers_count = 0;
  std::vector<vk::DescriptorSetLayout> layouts;
  layouts.reserve(commands.size());

  for (const auto& command : commands) {
    buffer_count += command.vertex_bindings.buffers.size();
    buffer_count += command.fragment_bindings.buffers.size();
    samplers_count += command.fragment_bindings.sampled_images.size();

    layouts.emplace_back(
        PipelineVK::Cast(*command.pipeline).GetDescriptorSetLayout());
  }
  auto descriptor_result =
      encoder->AllocateDescriptorSets(buffer_count, samplers_count, layouts);
  if (!descriptor_result.ok()) {
    return descriptor_result.status();
  }
  auto descriptor_sets = descriptor_result.value();
  if (descriptor_sets.empty()) {
    return fml::Status();
  }

  // Step 2: Update the descriptors for all image and buffer descriptors used
  // in the render pass.
  std::vector<vk::DescriptorImageInfo> images;
  std::vector<vk::DescriptorBufferInfo> buffers;
  std::vector<vk::WriteDescriptorSet> writes;
  images.reserve(samplers_count);
  buffers.reserve(buffer_count);
  writes.reserve(samplers_count + buffer_count);

  auto& allocator = *context.GetResourceAllocator();
  auto desc_index = 0u;
  for (const auto& command : commands) {
    auto desc_set = command.pipeline->GetDescriptor()
                        .GetVertexDescriptor()
                        ->GetDescriptorSetLayouts();

    if (!BindBuffers(command.vertex_bindings, allocator, encoder,
                     descriptor_sets[desc_index], desc_set, buffers, writes) ||
        !BindBuffers(command.fragment_bindings, allocator, encoder,
                     descriptor_sets[desc_index], desc_set, buffers, writes) ||
        !BindImages(command.fragment_bindings, allocator, encoder,
                    descriptor_sets[desc_index], images, writes)) {
      return fml::Status(fml::StatusCode::kUnknown,
                         "Failed to bind texture or buffer.");
    }
    desc_index += 1;
  }

  context.GetDevice().updateDescriptorSets(writes, {});
  return descriptor_sets;
}

fml::StatusOr<std::vector<vk::DescriptorSet>> AllocateAndBindDescriptorSets(
    const ContextVK& context,
    const std::shared_ptr<CommandEncoderVK>& encoder,
    const std::vector<ComputeCommand>& commands) {
  if (commands.empty()) {
    return std::vector<vk::DescriptorSet>{};
  }
  // Step 1: Determine the total number of buffer and sampler descriptor
  // sets required. Collect this information along with the layout information
  // to allocate a correctly sized descriptor pool.
  size_t buffer_count = 0;
  size_t samplers_count = 0;
  std::vector<vk::DescriptorSetLayout> layouts;
  layouts.reserve(commands.size());

  for (const auto& command : commands) {
    buffer_count += command.bindings.buffers.size();
    samplers_count += command.bindings.sampled_images.size();

    layouts.emplace_back(
        ComputePipelineVK::Cast(*command.pipeline).GetDescriptorSetLayout());
  }
  auto descriptor_result =
      encoder->AllocateDescriptorSets(buffer_count, samplers_count, layouts);
  if (!descriptor_result.ok()) {
    return descriptor_result.status();
  }
  auto descriptor_sets = descriptor_result.value();
  if (descriptor_sets.empty()) {
    return fml::Status();
  }
  // Step 2: Update the descriptors for all image and buffer descriptors used
  // in the render pass.
  std::vector<vk::DescriptorImageInfo> images;
  std::vector<vk::DescriptorBufferInfo> buffers;
  std::vector<vk::WriteDescriptorSet> writes;
  images.reserve(samplers_count);
  buffers.reserve(buffer_count);
  writes.reserve(samplers_count + buffer_count);

  auto& allocator = *context.GetResourceAllocator();
  auto desc_index = 0u;
  for (const auto& command : commands) {
    auto desc_set = command.pipeline->GetDescriptor().GetDescriptorSetLayouts();

    if (!BindBuffers(command.bindings, allocator, encoder,
                     descriptor_sets[desc_index], desc_set, buffers, writes) ||
        !BindImages(command.bindings, allocator, encoder,
                    descriptor_sets[desc_index], images, writes)) {
      return fml::Status(fml::StatusCode::kUnknown,
                         "Failed to bind texture or buffer.");
    }
    desc_index += 1;
  }

  context.GetDevice().updateDescriptorSets(writes, {});
  return descriptor_sets;
}

}  // namespace impeller
