// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"

#include "flutter/fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/render_pass_vk.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

std::shared_ptr<CommandBufferVK> CommandBufferVK::Create(
    std::weak_ptr<const Context> context,
    vk::Device device,
    vk::CommandPool command_pool,
    SurfaceProducerVK* surface_producer) {
  vk::CommandBufferAllocateInfo allocate_info;
  allocate_info.setLevel(vk::CommandBufferLevel::ePrimary);
  allocate_info.setCommandBufferCount(1);
  allocate_info.setCommandPool(command_pool);

  auto res = device.allocateCommandBuffersUnique(allocate_info);
  if (res.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to allocate command buffer: "
                   << vk::to_string(res.result);
    return nullptr;
  }

  vk::UniqueCommandBuffer cmd = std::move(res.value[0]);
  return std::make_shared<CommandBufferVK>(context, device, surface_producer,
                                           command_pool, std::move(cmd));
}

CommandBufferVK::CommandBufferVK(std::weak_ptr<const Context> context,
                                 vk::Device device,
                                 SurfaceProducerVK* surface_producer,
                                 vk::CommandPool command_pool,
                                 vk::UniqueCommandBuffer command_buffer)
    : CommandBuffer(context),
      device_(device),
      command_pool_(command_pool),
      command_buffer_(std::move(command_buffer)),
      surface_producer_(surface_producer) {
  is_valid_ = true;
}

CommandBufferVK::~CommandBufferVK() = default;

void CommandBufferVK::SetLabel(const std::string& label) const {
  if (auto context = context_.lock()) {
    reinterpret_cast<const ContextVK*>(context.get())
        ->SetDebugName(*command_buffer_, label);
  }
}

bool CommandBufferVK::IsValid() const {
  return is_valid_;
}

bool CommandBufferVK::OnSubmitCommands(CompletionCallback callback) {
  // TODO(https://github.com/flutter/flutter/issues/112387)
  // This needs to be the place where the command buffer, renderpass,
  // and the various descriptor sets in use by the command buffer are
  // disposed of.

  if (callback) {
    callback(CommandBuffer::Status::kCompleted);
  }

  return true;
}

std::shared_ptr<RenderPass> CommandBufferVK::OnCreateRenderPass(
    RenderTarget target) {
  std::vector<vk::AttachmentDescription> color_attachments;
  for (const auto& [k, attachment] : target.GetColorAttachments()) {
    const TextureDescriptor& tex_desc =
        attachment.texture->GetTextureDescriptor();

    vk::AttachmentDescription color_attachment;
    color_attachment.setFormat(ToVKImageFormat(tex_desc.format));
    color_attachment.setSamples(ToVKSampleCountFlagBits(tex_desc.sample_count));
    color_attachment.setLoadOp(ToVKAttachmentLoadOp(attachment.load_action));
    color_attachment.setStoreOp(ToVKAttachmentStoreOp(attachment.store_action));

    color_attachment.setStencilLoadOp(vk::AttachmentLoadOp::eDontCare);
    color_attachment.setStencilStoreOp(vk::AttachmentStoreOp::eDontCare);
    color_attachment.setInitialLayout(vk::ImageLayout::eColorAttachmentOptimal);
    color_attachment.setFinalLayout(vk::ImageLayout::ePresentSrcKHR);

    color_attachments.push_back(color_attachment);
  }

  // TODO (kaushikiska): support depth and stencil attachments.

  vk::AttachmentReference color_attachment_ref;
  color_attachment_ref.setAttachment(0);
  color_attachment_ref.setLayout(vk::ImageLayout::eColorAttachmentOptimal);

  vk::SubpassDescription subpass_desc;
  subpass_desc.setPipelineBindPoint(vk::PipelineBindPoint::eGraphics);
  subpass_desc.setColorAttachmentCount(color_attachments.size());
  subpass_desc.setPColorAttachments(&color_attachment_ref);

  vk::RenderPassCreateInfo render_pass_create;
  render_pass_create.setAttachmentCount(color_attachments.size());
  render_pass_create.setPAttachments(color_attachments.data());
  render_pass_create.setSubpassCount(1);
  render_pass_create.setPSubpasses(&subpass_desc);

  auto render_pass_create_res =
      device_.createRenderPassUnique(render_pass_create);
  if (render_pass_create_res.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to create render pass: "
                   << vk::to_string(render_pass_create_res.result);
    return nullptr;
  }

  return std::make_shared<RenderPassVK>(
      context_, device_, std::move(target), std::move(command_buffer_),
      std::move(render_pass_create_res.value), surface_producer_);
}

std::shared_ptr<BlitPass> CommandBufferVK::OnCreateBlitPass() const {
  FML_UNREACHABLE();
}

std::shared_ptr<ComputePass> CommandBufferVK::OnCreateComputePass() const {
  // TODO(dnfield): https://github.com/flutter/flutter/issues/110622
  VALIDATION_LOG << "ComputePasses unimplemented for Vulkan";
  return nullptr;
}

}  // namespace impeller
