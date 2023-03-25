// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/render_pass_vk.h"

#include <array>
#include <cstdint>
#include <unordered_map>
#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/pipeline_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_vk.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/sampler.h"
#include "impeller/renderer/shader_types.h"
#include "vulkan/vulkan_enums.hpp"
#include "vulkan/vulkan_structs.hpp"

namespace impeller {

static vk::AttachmentDescription CreateAttachmentDescription(
    const Attachment& attachment,
    bool resolve_texture = false) {
  const auto& texture =
      resolve_texture ? attachment.resolve_texture : attachment.texture;
  if (!texture) {
    return {};
  }
  const auto& texture_vk = TextureVK::Cast(*texture);
  const auto& desc = texture->GetTextureDescriptor();
  const auto current_layout = texture_vk.GetLayout();

  auto load_action = attachment.load_action;
  auto store_action = attachment.store_action;

  if (current_layout == vk::ImageLayout::eUndefined) {
    load_action = LoadAction::kClear;
  }

  if (desc.storage_mode == StorageMode::kDeviceTransient) {
    store_action = StoreAction::kDontCare;
  }

  const auto attachment_desc =
      CreateAttachmentDescription(desc.format,        //
                                  desc.sample_count,  //
                                  load_action,        //
                                  store_action,       //
                                  current_layout      //
      );

  // Instead of transitioning layouts manually using barriers, we are going to
  // make the subpass perform our transitions.
  texture_vk.SetLayoutWithoutEncoding(attachment_desc.finalLayout);

  return attachment_desc;
}

SharedHandleVK<vk::RenderPass> RenderPassVK::CreateVKRenderPass(
    const ContextVK& context) const {
  std::vector<vk::AttachmentDescription> attachments;

  std::vector<vk::AttachmentReference> color_refs;
  std::vector<vk::AttachmentReference> resolve_refs;
  vk::AttachmentReference depth_stencil_ref = kUnusedAttachmentReference;

  // Spec says: "Each element of the pColorAttachments array corresponds to an
  // output location in the shader, i.e. if the shader declares an output
  // variable decorated with a Location value of X, then it uses the attachment
  // provided in pColorAttachments[X]. If the attachment member of any element
  // of pColorAttachments is VK_ATTACHMENT_UNUSED."
  //
  // Just initialize all the elements as unused and fill in the valid bind
  // points in the loop below.
  color_refs.resize(render_target_.GetMaxColorAttacmentBindIndex() + 1u,
                    kUnusedAttachmentReference);
  resolve_refs.resize(render_target_.GetMaxColorAttacmentBindIndex() + 1u,
                      kUnusedAttachmentReference);

  for (const auto& [bind_point, color] : render_target_.GetColorAttachments()) {
    color_refs[bind_point] =
        vk::AttachmentReference{static_cast<uint32_t>(attachments.size()),
                                vk::ImageLayout::eColorAttachmentOptimal};
    attachments.emplace_back(CreateAttachmentDescription(color));
    if (color.resolve_texture) {
      resolve_refs[bind_point] =
          vk::AttachmentReference{static_cast<uint32_t>(attachments.size()),
                                  vk::ImageLayout::eColorAttachmentOptimal};
      attachments.emplace_back(CreateAttachmentDescription(color, true));
    }
  }

  if (auto depth = render_target_.GetDepthAttachment(); depth.has_value()) {
    depth_stencil_ref = vk::AttachmentReference{
        static_cast<uint32_t>(attachments.size()),
        vk::ImageLayout::eDepthStencilAttachmentOptimal};
    attachments.emplace_back(CreateAttachmentDescription(depth.value()));
  }

  if (auto stencil = render_target_.GetStencilAttachment();
      stencil.has_value()) {
    depth_stencil_ref = vk::AttachmentReference{
        static_cast<uint32_t>(attachments.size()),
        vk::ImageLayout::eDepthStencilAttachmentOptimal};
    attachments.emplace_back(CreateAttachmentDescription(stencil.value()));
  }

  vk::SubpassDescription subpass_desc;
  subpass_desc.pipelineBindPoint = vk::PipelineBindPoint::eGraphics;
  subpass_desc.setColorAttachments(color_refs);
  subpass_desc.setResolveAttachments(resolve_refs);
  subpass_desc.setPDepthStencilAttachment(&depth_stencil_ref);

  vk::RenderPassCreateInfo render_pass_desc;
  render_pass_desc.setAttachments(attachments);
  render_pass_desc.setPSubpasses(&subpass_desc);
  render_pass_desc.setSubpassCount(1u);

  auto [result, pass] =
      context.GetDevice().createRenderPassUnique(render_pass_desc);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to create render pass: " << vk::to_string(result);
    return {};
  }
  context.SetDebugName(pass.get(), debug_label_.c_str());
  return MakeSharedVK(std::move(pass));
}

RenderPassVK::RenderPassVK(const std::shared_ptr<const Context>& context,
                           const RenderTarget& target,
                           std::weak_ptr<CommandEncoderVK> encoder)
    : RenderPass(context, target), encoder_(std::move(encoder)) {
  is_valid_ = true;
}

RenderPassVK::~RenderPassVK() = default;

bool RenderPassVK::IsValid() const {
  return is_valid_;
}

void RenderPassVK::OnSetLabel(std::string label) {
  debug_label_ = std::move(label);
}

static vk::ClearColorValue VKClearValueFromColor(Color color) {
  vk::ClearColorValue value;
  value.setFloat32(
      std::array<float, 4>{color.red, color.green, color.blue, color.alpha});
  return value;
}

static vk::ClearDepthStencilValue VKClearValueFromDepthStencil(uint32_t stencil,
                                                               Scalar depth) {
  vk::ClearDepthStencilValue value;
  value.depth = depth;
  value.stencil = stencil;
  return value;
}

static std::vector<vk::ClearValue> GetVKClearValues(
    const RenderTarget& target) {
  std::vector<vk::ClearValue> clears;

  for (const auto& [_, color] : target.GetColorAttachments()) {
    clears.emplace_back(VKClearValueFromColor(color.clear_color));
    if (color.resolve_texture) {
      clears.emplace_back(VKClearValueFromColor(color.clear_color));
    }
  }

  const auto& depth = target.GetDepthAttachment();
  const auto& stencil = target.GetStencilAttachment();

  if (depth.has_value()) {
    clears.emplace_back(VKClearValueFromDepthStencil(
        stencil ? stencil->clear_stencil : 0u, depth->clear_depth));
  }

  if (stencil.has_value()) {
    clears.emplace_back(VKClearValueFromDepthStencil(
        stencil->clear_stencil, depth ? depth->clear_depth : 0.0f));
  }

  return clears;
}

SharedHandleVK<vk::Framebuffer> RenderPassVK::CreateVKFramebuffer(
    const ContextVK& context,
    const vk::RenderPass& pass) const {
  vk::FramebufferCreateInfo fb_info;

  fb_info.renderPass = pass;

  const auto target_size = render_target_.GetRenderTargetSize();
  fb_info.width = target_size.width;
  fb_info.height = target_size.height;

  fb_info.layers = 1u;

  std::vector<vk::ImageView> attachments;

  // This bit must be consistent to ensure compatibility with the pass created
  // earlier. Follow this order: Color attachments, then depth, then stencil.
  for (const auto& [_, color] : render_target_.GetColorAttachments()) {
    // The bind point doesn't matter here since that information is present in
    // the render pass.
    attachments.emplace_back(TextureVK::Cast(*color.texture).GetImageView());
    if (color.resolve_texture) {
      attachments.emplace_back(
          TextureVK::Cast(*color.resolve_texture).GetImageView());
    }
  }
  if (auto depth = render_target_.GetDepthAttachment(); depth.has_value()) {
    attachments.emplace_back(TextureVK::Cast(*depth->texture).GetImageView());
  }
  if (auto stencil = render_target_.GetStencilAttachment();
      stencil.has_value()) {
    attachments.emplace_back(TextureVK::Cast(*stencil->texture).GetImageView());
  }

  fb_info.setAttachments(attachments);

  auto [result, framebuffer] =
      context.GetDevice().createFramebufferUnique(fb_info);

  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create framebuffer: " << vk::to_string(result);
    return {};
  }

  return MakeSharedVK(std::move(framebuffer));
}

static bool UpdateBindingLayouts(const Bindings& bindings,
                                 const vk::CommandBuffer& buffer) {
  LayoutTransition transition;
  transition.cmd_buffer = buffer;
  transition.src_access = vk::AccessFlagBits::eColorAttachmentWrite |
                          vk::AccessFlagBits::eTransferWrite;
  transition.src_stage = vk::PipelineStageFlagBits::eColorAttachmentOutput |
                         vk::PipelineStageFlagBits::eTransfer;
  transition.dst_access = vk::AccessFlagBits::eShaderRead;
  transition.dst_stage = vk::PipelineStageFlagBits::eFragmentShader;

  transition.new_layout = vk::ImageLayout::eShaderReadOnlyOptimal;

  for (const auto& [_, texture] : bindings.textures) {
    if (!TextureVK::Cast(*texture.resource).SetLayout(transition)) {
      return false;
    }
  }
  return true;
}

static bool UpdateBindingLayouts(const Command& command,
                                 const vk::CommandBuffer& buffer) {
  return UpdateBindingLayouts(command.vertex_bindings, buffer) &&
         UpdateBindingLayouts(command.fragment_bindings, buffer);
}

static bool UpdateBindingLayouts(const std::vector<Command>& commands,
                                 const vk::CommandBuffer& buffer) {
  for (const auto& command : commands) {
    if (!UpdateBindingLayouts(command, buffer)) {
      return false;
    }
  }
  return true;
}

static bool AllocateAndBindDescriptorSets(const ContextVK& context,
                                          const Command& command,
                                          CommandEncoderVK& encoder,
                                          const PipelineVK& pipeline) {
  auto desc_set =
      encoder.AllocateDescriptorSet(pipeline.GetDescriptorSetLayout());
  if (!desc_set) {
    return false;
  }

  auto& allocator = *context.GetResourceAllocator();

  std::unordered_map<uint32_t, vk::DescriptorBufferInfo> buffers;
  std::unordered_map<uint32_t, vk::DescriptorImageInfo> images;
  std::vector<vk::WriteDescriptorSet> writes;

  auto bind_images = [&encoder,  //
                      &images,   //
                      &writes,   //
                      &desc_set  //
  ](const Bindings& bindings) -> bool {
    for (const auto& [index, sampler_handle] : bindings.samplers) {
      if (bindings.textures.find(index) == bindings.textures.end()) {
        return false;
      }

      auto texture = bindings.textures.at(index).resource;
      const auto& texture_vk = TextureVK::Cast(*texture);
      const SamplerVK& sampler = SamplerVK::Cast(*sampler_handle.resource);

      if (!encoder.Track(texture) ||
          !encoder.Track(sampler.GetSharedSampler())) {
        return false;
      }

      const SampledImageSlot& slot = bindings.sampled_images.at(index);

      vk::DescriptorImageInfo image_info;
      image_info.imageLayout = vk::ImageLayout::eShaderReadOnlyOptimal;
      image_info.sampler = sampler.GetSampler();
      image_info.imageView = texture_vk.GetImageView();

      vk::WriteDescriptorSet write_set;
      write_set.dstSet = desc_set.value();
      write_set.dstBinding = slot.binding;
      write_set.descriptorCount = 1u;
      write_set.descriptorType = vk::DescriptorType::eCombinedImageSampler;
      write_set.pImageInfo = &(images[slot.binding] = image_info);

      writes.push_back(write_set);
    }

    return true;
  };

  auto bind_buffers = [&allocator,  //
                       &encoder,    //
                       &buffers,    //
                       &writes,     //
                       &desc_set    //
  ](const Bindings& bindings) -> bool {
    for (const auto& [buffer_index, view] : bindings.buffers) {
      const auto& buffer_view = view.resource.buffer;

      auto device_buffer = buffer_view->GetDeviceBuffer(allocator);
      if (!device_buffer) {
        VALIDATION_LOG << "Failed to get device buffer for vertex binding";
        return false;
      }

      auto buffer = DeviceBufferVK::Cast(*device_buffer).GetBuffer();
      if (!buffer) {
        return false;
      }

      // Reserved index used for per-vertex data.
      if (buffer_index == VertexDescriptor::kReservedVertexBufferIndex) {
        continue;
      }

      if (!encoder.Track(device_buffer)) {
        return false;
      }

      uint32_t offset = view.resource.range.offset;

      vk::DescriptorBufferInfo buffer_info;
      buffer_info.buffer = buffer;
      buffer_info.offset = offset;
      buffer_info.range = view.resource.range.length;

      const ShaderUniformSlot& uniform = bindings.uniforms.at(buffer_index);

      vk::WriteDescriptorSet write_set;
      write_set.dstSet = desc_set.value();
      write_set.dstBinding = uniform.binding;
      write_set.descriptorCount = 1u;
      write_set.descriptorType = vk::DescriptorType::eUniformBuffer;
      write_set.pBufferInfo = &(buffers[uniform.binding] = buffer_info);

      writes.push_back(write_set);
    }
    return true;
  };

  if (!bind_buffers(command.vertex_bindings) ||
      !bind_buffers(command.fragment_bindings) ||
      !bind_images(command.fragment_bindings)) {
    return false;
  }

  context.GetDevice().updateDescriptorSets(writes, {});

  encoder.GetCommandBuffer().bindDescriptorSets(
      vk::PipelineBindPoint::eGraphics,  // bind point
      pipeline.GetPipelineLayout(),      // layout
      0,                                 // first set
      {vk::DescriptorSet{*desc_set}},    // sets
      nullptr                            // offsets
  );
  return true;
}

static void SetViewportAndScissor(const Command& command,
                                  const vk::CommandBuffer& cmd_buffer,
                                  const ISize& target_size) {
  // Set the viewport.
  const auto& vp = command.viewport.value_or<Viewport>(
      {.rect = Rect::MakeSize(target_size)});
  vk::Viewport viewport = vk::Viewport()
                              .setWidth(vp.rect.size.width)
                              .setHeight(-vp.rect.size.height)
                              .setY(vp.rect.size.height)
                              .setMinDepth(0.0f)
                              .setMaxDepth(1.0f);
  cmd_buffer.setViewport(0, 1, &viewport);

  // Set the scissor rect.
  const auto& sc = command.scissor.value_or(IRect::MakeSize(target_size));
  vk::Rect2D scissor =
      vk::Rect2D()
          .setOffset(vk::Offset2D(sc.origin.x, sc.origin.y))
          .setExtent(vk::Extent2D(sc.size.width, sc.size.height));
  cmd_buffer.setScissor(0, 1, &scissor);
}

static bool EncodeCommand(const Context& context,
                          const Command& command,
                          CommandEncoderVK& encoder,
                          const ISize& target_size) {
  if (command.index_count == 0u || command.instance_count == 0u) {
    return true;
  }

  fml::ScopedCleanupClosure pop_marker(
      [&encoder]() { encoder.PopDebugGroup(); });
  if (!command.label.empty()) {
    encoder.PushDebugGroup(command.label.c_str());
  } else {
    pop_marker.Release();
  }

  const auto& cmd_buffer = encoder.GetCommandBuffer();

  const auto& pipeline_vk = PipelineVK::Cast(*command.pipeline);

  if (!AllocateAndBindDescriptorSets(ContextVK::Cast(context),  //
                                     command,                   //
                                     encoder,                   //
                                     pipeline_vk                //
                                     )) {
    return false;
  }

  cmd_buffer.bindPipeline(vk::PipelineBindPoint::eGraphics,
                          pipeline_vk.GetPipeline());

  // Set the viewport and scissors.
  SetViewportAndScissor(command, cmd_buffer, target_size);

  // Set the stencil reference.
  cmd_buffer.setStencilReference(
      vk::StencilFaceFlagBits::eVkStencilFrontAndBack,
      command.stencil_reference);

  // Configure vertex and index and buffers for binding.
  auto vertex_buffer_view = command.GetVertexBuffer();
  auto index_buffer_view = command.index_buffer;

  if (!vertex_buffer_view || !index_buffer_view) {
    return false;
  }

  auto& allocator = *context.GetResourceAllocator();

  auto vertex_buffer = vertex_buffer_view.buffer->GetDeviceBuffer(allocator);
  auto index_buffer = index_buffer_view.buffer->GetDeviceBuffer(allocator);

  if (!vertex_buffer || !index_buffer) {
    VALIDATION_LOG << "Failed to acquire device buffers"
                   << " for vertex and index buffer views";
    return false;
  }

  if (!encoder.Track(vertex_buffer) || !encoder.Track(index_buffer)) {
    return false;
  }

  // Bind the vertex buffer.
  auto vertex_buffer_handle = DeviceBufferVK::Cast(*vertex_buffer).GetBuffer();
  vk::Buffer vertex_buffers[] = {vertex_buffer_handle};
  vk::DeviceSize vertex_buffer_offsets[] = {vertex_buffer_view.range.offset};
  cmd_buffer.bindVertexBuffers(0u, 1u, vertex_buffers, vertex_buffer_offsets);

  // Bind the index buffer.
  auto index_buffer_handle = DeviceBufferVK::Cast(*index_buffer).GetBuffer();
  cmd_buffer.bindIndexBuffer(index_buffer_handle,
                             index_buffer_view.range.offset,
                             ToVKIndexType(command.index_type));

  // Engage!
  cmd_buffer.drawIndexed(command.index_count,     // index count
                         command.instance_count,  // instance count
                         0u,                      // first index
                         command.base_vertex,     // vertex offset
                         0u                       // first instance
  );
  return true;
}

bool RenderPassVK::OnEncodeCommands(const Context& context) const {
  TRACE_EVENT0("impeller", "RenderPassVK::OnEncodeCommands");
  if (!IsValid()) {
    return false;
  }

  const auto& vk_context = ContextVK::Cast(context);

  auto encoder = encoder_.lock();
  if (!encoder) {
    VALIDATION_LOG << "Command encoder died before commands could be encoded.";
    return false;
  }

  fml::ScopedCleanupClosure pop_marker(
      [&encoder]() { encoder->PopDebugGroup(); });
  if (!debug_label_.empty()) {
    encoder->PushDebugGroup(debug_label_.c_str());
  } else {
    pop_marker.Release();
  }

  auto cmd_buffer = encoder->GetCommandBuffer();

  if (!UpdateBindingLayouts(commands_, cmd_buffer)) {
    return false;
  }

  render_target_.IterateAllAttachments(
      [&encoder](const auto& attachment) -> bool {
        encoder->Track(attachment.texture);
        encoder->Track(attachment.resolve_texture);
        return true;
      });

  const auto& target_size = render_target_.GetRenderTargetSize();

  auto render_pass = CreateVKRenderPass(vk_context);
  if (!render_pass) {
    VALIDATION_LOG << "Could not create renderpass.";
    return false;
  }

  auto framebuffer = CreateVKFramebuffer(vk_context, *render_pass);
  if (!framebuffer) {
    VALIDATION_LOG << "Could not create framebuffer.";
    return false;
  }

  if (!encoder->Track(framebuffer) || !encoder->Track(render_pass)) {
    return false;
  }

  auto clear_values = GetVKClearValues(render_target_);

  vk::RenderPassBeginInfo pass_info;
  pass_info.renderPass = *render_pass;
  pass_info.framebuffer = *framebuffer;
  pass_info.renderArea.extent.width = static_cast<uint32_t>(target_size.width);
  pass_info.renderArea.extent.height =
      static_cast<uint32_t>(target_size.height);
  pass_info.setClearValues(clear_values);

  {
    TRACE_EVENT0("impeller", "EncodeRenderPassCommands");
    cmd_buffer.beginRenderPass(pass_info, vk::SubpassContents::eInline);

    fml::ScopedCleanupClosure end_render_pass(
        [cmd_buffer]() { cmd_buffer.endRenderPass(); });

    for (const auto& command : commands_) {
      if (!command.pipeline) {
        continue;
      }

      if (!EncodeCommand(context, command, *encoder, target_size)) {
        return false;
      }
    }
  }

  return true;
}

}  // namespace impeller
