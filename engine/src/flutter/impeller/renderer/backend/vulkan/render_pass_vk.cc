// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/render_pass_vk.h"

#include <array>
#include <cstdint>
#include <vector>

#include "fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/commands_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/pipeline_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_vk.h"
#include "impeller/renderer/backend/vulkan/surface_producer_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/sampler.h"
#include "impeller/renderer/shader_types.h"
#include "vulkan/vulkan_enums.hpp"
#include "vulkan/vulkan_structs.hpp"

namespace impeller {

static uint32_t color_flash = 0;

RenderPassVK::RenderPassVK(
    std::weak_ptr<const Context> context,
    vk::Device device,
    const RenderTarget& target,
    std::shared_ptr<FencedCommandBufferVK> command_buffer,
    vk::RenderPass render_pass)
    : RenderPass(std::move(context), target),
      device_(device),
      command_buffer_(std::move(command_buffer)),
      render_pass_(render_pass) {
  is_valid_ = true;
}

RenderPassVK::~RenderPassVK() = default;

bool RenderPassVK::IsValid() const {
  return is_valid_;
}

void RenderPassVK::OnSetLabel(std::string label) {
  label_ = std::move(label);
}

bool RenderPassVK::OnEncodeCommands(const Context& context) const {
  if (!IsValid()) {
    return false;
  }

  const auto& render_target = GetRenderTarget();
  if (!render_target.HasColorAttachment(0u)) {
    return false;
  }

  vk::CommandBufferBeginInfo begin_info;
  auto res = command_buffer_->Get().begin(begin_info);
  if (res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to begin command buffer: " << vk::to_string(res);
    return false;
  }

  const auto& color0 = render_target.GetColorAttachments().at(0u);
  const auto& depth0 = render_target.GetDepthAttachment();
  const auto& stencil0 = render_target.GetStencilAttachment();

  auto& texture = TextureVK::Cast(*color0.texture);
  const auto& size = texture.GetTextureDescriptor().size;
  vk::Framebuffer framebuffer = CreateFrameBuffer(texture);
  uint32_t mip_count = texture.GetTextureDescriptor().mip_count;

  command_buffer_->GetDeletionQueue()->Push(
      [device = device_, fbo = framebuffer]() {
        device.destroyFramebuffer(fbo);
      });

  // layout transition.
  if (!TransitionImageLayout(texture.GetImage(), vk::ImageLayout::eUndefined,
                             vk::ImageLayout::eColorAttachmentOptimal,
                             mip_count)) {
    return false;
  }

  vk::ClearValue clear_value;
  clear_value.color =
      vk::ClearColorValue(std::array<float, 4>{0.0f, 0.0f, 0.0, 0.0f});

  vk::Rect2D render_area =
      vk::Rect2D()
          .setOffset(vk::Offset2D(0, 0))
          .setExtent(vk::Extent2D(size.width, size.height));
  auto rp_begin_info = vk::RenderPassBeginInfo()
                           .setRenderPass(render_pass_)
                           .setFramebuffer(framebuffer)
                           .setRenderArea(render_area)
                           .setClearValues(clear_value);

  command_buffer_->Get().beginRenderPass(rp_begin_info,
                                         vk::SubpassContents::eInline);

  const auto& transients_allocator = context.GetResourceAllocator();

  // encode the commands.
  for (const auto& command : commands_) {
    if (command.index_count == 0u) {
      continue;
    }

    if (command.instance_count == 0u) {
      continue;
    }

    if (!command.pipeline) {
      continue;
    }

    if (!EncodeCommand(context, command)) {
      return false;
    }
  }

  if (!TransitionImageLayout(texture.GetImage(), vk::ImageLayout::eUndefined,
                             vk::ImageLayout::eColorAttachmentOptimal,
                             mip_count)) {
    return false;
  }

  command_buffer_->Get().endRenderPass();

  return const_cast<RenderPassVK*>(this)->EndCommandBuffer();
}

bool RenderPassVK::EndCommandBuffer() {
  if (command_buffer_) {
    auto res = command_buffer_->Get().end();
    if (res != vk::Result::eSuccess) {
      VALIDATION_LOG << "Failed to end command buffer: " << vk::to_string(res);
      return false;
    }

    const auto& context_vk = GetContextVK();
    command_buffer_->GetDeletionQueue()->Push(
        [device = device_, render_pass = render_pass_]() {
          device.destroyRenderPass(render_pass);
        });

    return true;
  }
  return false;
}

bool RenderPassVK::EncodeCommand(const Context& context,
                                 const Command& command) const {
  SetViewportAndScissor(command);

  auto& pipeline_vk = PipelineVK::Cast(*command.pipeline);
  PipelineCreateInfoVK* pipeline_create_info = pipeline_vk.GetCreateInfo();

  if (!AllocateAndBindDescriptorSets(context, command, pipeline_create_info)) {
    return false;
  }

  command_buffer_->Get().bindPipeline(vk::PipelineBindPoint::eGraphics,
                                      pipeline_create_info->GetVKPipeline());

  auto vertex_buffer_view = command.GetVertexBuffer();
  auto index_buffer_view = command.index_buffer;

  if (!vertex_buffer_view || !index_buffer_view) {
    return false;
  }

  auto& allocator = *context.GetResourceAllocator();
  const auto& pipeline_desc = command.pipeline->GetDescriptor();

  auto vertex_buffer = vertex_buffer_view.buffer->GetDeviceBuffer(allocator);
  auto index_buffer = index_buffer_view.buffer->GetDeviceBuffer(allocator);

  if (!vertex_buffer || !index_buffer) {
    VALIDATION_LOG << "Failed to acquire device buffers"
                   << " for vertex and index buffer views";
    return false;
  }

  // bind vertex buffer
  auto vertex_buffer_handle =
      DeviceBufferVK::Cast(*vertex_buffer).GetVKBufferHandle();
  vk::Buffer vertex_buffers[] = {vertex_buffer_handle};
  vk::DeviceSize vertex_buffer_offsets[] = {vertex_buffer_view.range.offset};
  command_buffer_->Get().bindVertexBuffers(0, 1, vertex_buffers,
                                           vertex_buffer_offsets);

  // index buffer
  auto index_buffer_handle =
      DeviceBufferVK::Cast(*index_buffer).GetVKBufferHandle();
  command_buffer_->Get().bindIndexBuffer(index_buffer_handle,
                                         index_buffer_view.range.offset,
                                         ToVKIndexType(command.index_type));

  // execute draw
  command_buffer_->Get().drawIndexed(command.index_count,
                                     command.instance_count, 0, 0, 0);
  return true;
}

bool RenderPassVK::AllocateAndBindDescriptorSets(

    const Context& context,
    const Command& command,
    PipelineCreateInfoVK* pipeline_create_info) const {
  auto& allocator = *context.GetResourceAllocator();
  vk::PipelineLayout pipeline_layout =
      pipeline_create_info->GetPipelineLayout();

  const auto& context_vk = GetContextVK();
  const auto& pool = context_vk.CreateDescriptorPool();

  command_buffer_->GetDeletionQueue()->Push(
      [pool = pool->GetPool(), device = device_]() {
        device.destroyDescriptorPool(pool);
      });

  vk::DescriptorSetAllocateInfo alloc_info;
  std::array<vk::DescriptorSetLayout, 1> dsls = {
      pipeline_create_info->GetDescriptorSetLayout(),
  };

  alloc_info.setDescriptorPool(pool->GetPool());
  alloc_info.setSetLayouts(dsls);

  auto desc_sets_res = device_.allocateDescriptorSets(alloc_info);
  if (desc_sets_res.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to allocate descriptor sets: "
                   << vk::to_string(desc_sets_res.result);
    return false;
  }

  auto desc_sets = desc_sets_res.value;
  bool update_vertex_descriptors = UpdateDescriptorSets(
      "vertex_bindings", command.vertex_bindings, allocator, desc_sets[0]);
  if (!update_vertex_descriptors) {
    return false;
  }
  bool update_frag_descriptors = UpdateDescriptorSets(
      "fragment_bindings", command.fragment_bindings, allocator, desc_sets[0]);
  if (!update_frag_descriptors) {
    return false;
  }

  command_buffer_->Get().bindDescriptorSets(
      vk::PipelineBindPoint::eGraphics, pipeline_layout, 0, desc_sets, nullptr);
  return true;
}

bool RenderPassVK::UpdateDescriptorSets(const char* label,
                                        const Bindings& bindings,
                                        Allocator& allocator,
                                        vk::DescriptorSet desc_set) const {
  std::vector<vk::WriteDescriptorSet> writes;
  std::vector<vk::DescriptorBufferInfo> buffer_infos;
  std::vector<vk::DescriptorImageInfo> image_infos;

  for (const auto& [buffer_index, view] : bindings.buffers) {
    const auto& buffer_view = view.resource.buffer;

    auto device_buffer = buffer_view->GetDeviceBuffer(allocator);
    if (!device_buffer) {
      VALIDATION_LOG << "Failed to get device buffer for vertex binding";
      return false;
    }

    auto buffer = DeviceBufferVK::Cast(*device_buffer).GetVKBufferHandle();
    if (!buffer) {
      return false;
    }

    // reserved index used for per-vertex data.
    if (buffer_index == VertexDescriptor::kReservedVertexBufferIndex) {
      continue;
    }

    uint32_t offset = view.resource.range.offset;

    vk::DescriptorBufferInfo desc_buffer_info;
    desc_buffer_info.setBuffer(buffer);
    desc_buffer_info.setOffset(offset);
    desc_buffer_info.setRange(view.resource.range.length);
    buffer_infos.push_back(desc_buffer_info);

    const ShaderUniformSlot& uniform = bindings.uniforms.at(buffer_index);

    vk::WriteDescriptorSet setWrite;
    setWrite.setDstSet(desc_set);
    setWrite.setDstBinding(uniform.binding);
    setWrite.setDescriptorCount(1);
    setWrite.setDescriptorType(vk::DescriptorType::eUniformBuffer);
    setWrite.setPBufferInfo(&buffer_infos.back());

    writes.push_back(setWrite);
  }

  for (const auto& [index, sampler_handle] : bindings.samplers) {
    if (bindings.textures.find(index) == bindings.textures.end()) {
      VALIDATION_LOG << "Missing texture for sampler: " << index;
      return false;
    }

    const auto& texture_vk =
        TextureVK::Cast(*bindings.textures.at(index).resource);

    const Sampler& sampler = *sampler_handle.resource;
    const SamplerVK& sampler_vk = SamplerVK::Cast(sampler);

    const SampledImageSlot& slot = bindings.sampled_images.at(index);
    uint32_t mip_levels = texture_vk.GetTextureDescriptor().mip_count;

    if (!TransitionImageLayout(
            texture_vk.GetImage(), vk::ImageLayout::eUndefined,
            vk::ImageLayout::eTransferDstOptimal, mip_levels)) {
      return false;
    }

    CopyBufferToImage(texture_vk);

    if (!TransitionImageLayout(
            texture_vk.GetImage(), vk::ImageLayout::eTransferDstOptimal,
            vk::ImageLayout::eShaderReadOnlyOptimal, mip_levels)) {
      return false;
    }

    vk::DescriptorImageInfo desc_image_info;
    desc_image_info.setImageLayout(vk::ImageLayout::eShaderReadOnlyOptimal);
    desc_image_info.setSampler(sampler_vk.GetSamplerVK());
    desc_image_info.setImageView(texture_vk.GetImageView());
    image_infos.push_back(desc_image_info);

    vk::WriteDescriptorSet setWrite;
    setWrite.setDstSet(desc_set);
    setWrite.setDstBinding(slot.binding);
    setWrite.setDescriptorCount(1);
    setWrite.setDescriptorType(vk::DescriptorType::eCombinedImageSampler);
    setWrite.setPImageInfo(&image_infos.back());

    writes.push_back(setWrite);
  }

  std::array<vk::CopyDescriptorSet, 0> copies;
  if (!writes.empty()) {
    device_.updateDescriptorSets(writes, copies);
  }

  return true;
}

void RenderPassVK::SetViewportAndScissor(const Command& command) const {
  // set viewport.
  const auto& vp = command.viewport.value_or<Viewport>(
      {.rect = Rect::MakeSize(GetRenderTargetSize())});
  vk::Viewport viewport = vk::Viewport()
                              .setWidth(vp.rect.size.width)
                              .setHeight(-vp.rect.size.height)
                              .setY(vp.rect.size.height)
                              .setMinDepth(0.0f)
                              .setMaxDepth(1.0f);
  command_buffer_->Get().setViewport(0, 1, &viewport);

  // scissor
  const auto& sc =
      command.scissor.value_or(IRect::MakeSize(GetRenderTargetSize()));
  vk::Rect2D scissor =
      vk::Rect2D()
          .setOffset(vk::Offset2D(sc.origin.x, sc.origin.y))
          .setExtent(vk::Extent2D(sc.size.width, sc.size.height));
  command_buffer_->Get().setScissor(0, 1, &scissor);
}

vk::Framebuffer RenderPassVK::CreateFrameBuffer(
    const TextureVK& texture) const {
  auto img_view = texture.GetImageView();
  auto size = texture.GetTextureDescriptor().size;
  vk::FramebufferCreateInfo fb_create_info = vk::FramebufferCreateInfo()
                                                 .setRenderPass(render_pass_)
                                                 .setAttachmentCount(1)
                                                 .setPAttachments(&img_view)
                                                 .setWidth(size.width)
                                                 .setHeight(size.height)
                                                 .setLayers(1);
  auto res = device_.createFramebuffer(fb_create_info);
  FML_CHECK(res.result == vk::Result::eSuccess);
  return res.value;
}

bool RenderPassVK::TransitionImageLayout(vk::Image image,
                                         vk::ImageLayout layout_old,
                                         vk::ImageLayout layout_new,
                                         uint32_t mip_levels) const {
  auto transition_cmd =
      TransitionImageLayoutCommandVK(image, layout_old, layout_new, mip_levels);
  return transition_cmd.Submit(command_buffer_.get());
}

bool RenderPassVK::CopyBufferToImage(const TextureVK& texture_vk) const {
  auto copy_cmd = command_buffer_->GetSingleUseChild();

  const auto& size = texture_vk.GetTextureDescriptor().size;

  // actual copy happens here
  vk::BufferImageCopy region =
      vk::BufferImageCopy()
          .setBufferOffset(0)
          .setBufferRowLength(0)
          .setBufferImageHeight(0)
          .setImageSubresource(
              vk::ImageSubresourceLayers()
                  .setAspectMask(vk::ImageAspectFlagBits::eColor)
                  .setMipLevel(0)
                  .setBaseArrayLayer(0)
                  .setLayerCount(1))
          .setImageOffset(vk::Offset3D(0, 0, 0))
          .setImageExtent(vk::Extent3D(size.width, size.height, 1));

  vk::CommandBufferBeginInfo begin_info;
  begin_info.setFlags(vk::CommandBufferUsageFlagBits::eOneTimeSubmit);
  auto res = copy_cmd.begin(begin_info);

  if (res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to begin command buffer: " << vk::to_string(res);
    return false;
  }

  copy_cmd.copyBufferToImage(texture_vk.GetStagingBuffer(),
                             texture_vk.GetImage(),
                             vk::ImageLayout::eTransferDstOptimal, region);

  res = copy_cmd.end();
  if (res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to end command buffer: " << vk::to_string(res);
    return false;
  }

  return true;
}

const ContextVK& RenderPassVK::GetContextVK() const {
  if (auto context = context_.lock()) {
    const auto& context_vk = ContextVK::Cast(*context);
    return context_vk;
  }

  FML_UNREACHABLE();
}

}  // namespace impeller
