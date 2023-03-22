// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/render_pass_vk.h"

#include <array>
#include <cstdint>
#include <vector>

#include "fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/pipeline_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_vk.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/sampler.h"
#include "impeller/renderer/shader_types.h"
#include "vulkan/vulkan_enums.hpp"
#include "vulkan/vulkan_structs.hpp"

namespace impeller {

static vk::AttachmentDescription CreateAttachmentDescription(
    const Attachment& attachment,
    AttachmentKind kind,
    bool resolve_texture = false) {
  const auto& texture = resolve_texture
                            ? attachment.resolve_texture->GetTextureDescriptor()
                            : attachment.texture->GetTextureDescriptor();
  return CreateAttachmentDescription(texture.format,          //
                                     texture.sample_count,    //
                                     kind,                    //
                                     attachment.load_action,  //
                                     attachment.store_action  //
  );
}

static vk::UniqueRenderPass CreateVKRenderPass(const vk::Device& device,
                                               const RenderTarget& target) {
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
  color_refs.resize(target.GetMaxColorAttacmentBindIndex() + 1u,
                    kUnusedAttachmentReference);
  resolve_refs.resize(target.GetMaxColorAttacmentBindIndex() + 1u,
                      kUnusedAttachmentReference);

  for (const auto& [bind_point, color] : target.GetColorAttachments()) {
    color_refs[bind_point] =
        vk::AttachmentReference{static_cast<uint32_t>(attachments.size()),
                                vk::ImageLayout::eColorAttachmentOptimal};
    attachments.emplace_back(
        CreateAttachmentDescription(color, AttachmentKind::kColor));
    if (color.resolve_texture) {
      resolve_refs[bind_point] =
          vk::AttachmentReference{static_cast<uint32_t>(attachments.size()),
                                  vk::ImageLayout::eColorAttachmentOptimal};
      attachments.emplace_back(
          CreateAttachmentDescription(color, AttachmentKind::kColor, true));
    }
  }

  if (auto depth = target.GetDepthAttachment(); depth.has_value()) {
    depth_stencil_ref = vk::AttachmentReference{
        static_cast<uint32_t>(attachments.size()),
        vk::ImageLayout::eDepthStencilAttachmentOptimal};
    attachments.emplace_back(
        CreateAttachmentDescription(depth.value(), AttachmentKind::kDepth));
  } else if (auto stencil = target.GetStencilAttachment();
             stencil.has_value()) {
    depth_stencil_ref = vk::AttachmentReference{
        static_cast<uint32_t>(attachments.size()),
        vk::ImageLayout::eDepthStencilAttachmentOptimal};
    attachments.emplace_back(
        CreateAttachmentDescription(stencil.value(), AttachmentKind::kStencil));
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

  auto [result, pass] = device.createRenderPassUnique(render_pass_desc);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to create render pass: " << vk::to_string(result);
    return {};
  }

  return std::move(pass);
}

RenderPassVK::RenderPassVK(const std::shared_ptr<const Context>& context,
                           const RenderTarget& target,
                           std::weak_ptr<CommandEncoderVK> encoder)
    : RenderPass(context, target),
      render_pass_(
          CreateVKRenderPass(ContextVK::Cast(*context).GetDevice(), target)),
      encoder_(std::move(encoder)) {
  if (!render_pass_) {
    return;
  }
  is_valid_ = true;
}

RenderPassVK::~RenderPassVK() = default;

bool RenderPassVK::IsValid() const {
  return is_valid_;
}

void RenderPassVK::OnSetLabel(std::string label) {
  auto context = GetContext().lock();
  if (!context) {
    return;
  }
  ContextVK::Cast(*context).SetDebugName(*render_pass_, label.c_str());
  debug_label_ = std::move(label);
}

static vk::ClearColorValue VKClearValueFromColor(Color color) {
  vk::ClearColorValue value;
  value.setFloat32(
      std::array<float, 4>{color.red, color.green, color.blue, color.alpha});
  return value;
}

static vk::ClearDepthStencilValue VKClearValueFromDepth(Scalar depth) {
  vk::ClearDepthStencilValue value;
  value.depth = depth;
  return value;
}

static vk::ClearDepthStencilValue VKClearValueFromStencil(uint32_t stencil) {
  vk::ClearDepthStencilValue value;
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

  if (auto depth = target.GetDepthAttachment(); depth.has_value()) {
    clears.emplace_back(VKClearValueFromDepth(depth->clear_depth));
  }

  if (auto stencil = target.GetStencilAttachment(); stencil.has_value()) {
    clears.emplace_back(VKClearValueFromStencil(stencil->clear_stencil));
  }

  return clears;
}

static vk::UniqueFramebuffer CreateFramebuffer(const vk::Device& device,
                                               const RenderTarget& target,
                                               const vk::RenderPass& pass) {
  vk::FramebufferCreateInfo fb_info;

  fb_info.renderPass = pass;

  const auto target_size = target.GetRenderTargetSize();
  fb_info.width = target_size.width;
  fb_info.height = target_size.height;

  fb_info.layers = 1u;

  std::vector<vk::ImageView> attachments;

  // This bit must be consistent to ensure compatibility with the pass created
  // earlier. Follow this order: Color attachments, then depth, then stencil.
  for (const auto& [_, color] : target.GetColorAttachments()) {
    // The bind point doesn't matter here since that information is present in
    // the render pass.
    attachments.emplace_back(TextureVK::Cast(*color.texture).GetImageView());
    if (color.resolve_texture) {
      attachments.emplace_back(
          TextureVK::Cast(*color.resolve_texture).GetImageView());
    }
  }
  if (auto depth = target.GetDepthAttachment(); depth.has_value()) {
    attachments.emplace_back(TextureVK::Cast(*depth->texture).GetImageView());
  }
  if (auto stencil = target.GetStencilAttachment(); stencil.has_value()) {
    attachments.emplace_back(TextureVK::Cast(*stencil->texture).GetImageView());
  }

  fb_info.setAttachments(attachments);

  auto [result, framebuffer] = device.createFramebufferUnique(fb_info);

  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create framebuffer: " << vk::to_string(result);
    return {};
  }

  return std::move(framebuffer);
}

static bool ConfigureRenderTargetAttachmentLayouts(
    const RenderTarget& target,
    const vk::CommandBuffer& command_buffer) {
  for (const auto& [_, color] : target.GetColorAttachments()) {
    if (!TextureVK::Cast(*color.texture)
             .SetLayout(vk::ImageLayout::eColorAttachmentOptimal,
                        command_buffer)) {
      return false;
    }
    if (color.resolve_texture) {
      if (!TextureVK::Cast(*color.resolve_texture)
               .SetLayout(vk::ImageLayout::eColorAttachmentOptimal,
                          command_buffer)) {
        return false;
      }
    }
  }
  if (auto depth = target.GetDepthAttachment(); depth.has_value()) {
    if (!TextureVK::Cast(*depth->texture)
             .SetLayout(vk::ImageLayout::eDepthAttachmentOptimal,
                        command_buffer)) {
      return false;
    }
  }
  if (auto stencil = target.GetStencilAttachment(); stencil.has_value()) {
    if (!TextureVK::Cast(*stencil->texture)
             .SetLayout(vk::ImageLayout::eStencilAttachmentOptimal,
                        command_buffer)) {
      return false;
    }
  }
  return true;
}

static bool UpdateBindingLayouts(const Bindings& bindings,
                                 const vk::CommandBuffer& buffer) {
  for (const auto& [_, texture] : bindings.textures) {
    if (!TextureVK::Cast(*texture.resource)
             .SetLayout(vk::ImageLayout::eShaderReadOnlyOptimal, buffer)) {
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

static bool UpdateDescriptorSets(vk::Device device,
                                 const Bindings& bindings,
                                 Allocator& allocator,
                                 vk::DescriptorSet desc_set,
                                 CommandEncoderVK& encoder) {
  std::vector<vk::WriteDescriptorSet> writes;

  //----------------------------------------------------------------------------
  /// Setup buffer descriptors.
  ///
  std::vector<vk::DescriptorBufferInfo> buffer_desc;
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

    // Reserved index used for per-vertex data.
    if (buffer_index == VertexDescriptor::kReservedVertexBufferIndex) {
      continue;
    }

    if (!encoder.Track(device_buffer)) {
      return false;
    }

    uint32_t offset = view.resource.range.offset;

    vk::DescriptorBufferInfo desc_buffer_info;
    desc_buffer_info.setBuffer(buffer);
    desc_buffer_info.setOffset(offset);
    desc_buffer_info.setRange(view.resource.range.length);
    buffer_desc.push_back(desc_buffer_info);

    const ShaderUniformSlot& uniform = bindings.uniforms.at(buffer_index);

    vk::WriteDescriptorSet write_set;
    write_set.setDstSet(desc_set);
    write_set.setDstBinding(uniform.binding);
    write_set.setDescriptorCount(1);
    write_set.setDescriptorType(vk::DescriptorType::eUniformBuffer);
    write_set.setPBufferInfo(&buffer_desc.back());

    writes.push_back(write_set);
  }

  //----------------------------------------------------------------------------
  /// Setup image descriptors.
  ///
  std::vector<vk::DescriptorImageInfo> image_descs;
  for (const auto& [index, sampler_handle] : bindings.samplers) {
    if (bindings.textures.find(index) == bindings.textures.end()) {
      VALIDATION_LOG << "Missing texture for sampler: " << index;
      return false;
    }

    auto texture = bindings.textures.at(index).resource;
    if (texture->NeedsMipmapGeneration()) {
      VALIDATION_LOG
          << "Texture at binding index " << index
          << " has a mip count > 1, but the mipmap has not been generated.";
      return false;
    }
    const auto& texture_vk = TextureVK::Cast(*texture);
    const SamplerVK& sampler = SamplerVK::Cast(*sampler_handle.resource);

    if (!encoder.Track(texture) || !encoder.Track(sampler.GetSharedSampler())) {
      return false;
    }

    const SampledImageSlot& slot = bindings.sampled_images.at(index);

    vk::DescriptorImageInfo desc_image_info;
    desc_image_info.setImageLayout(vk::ImageLayout::eShaderReadOnlyOptimal);
    desc_image_info.setSampler(sampler.GetSamplerVK());
    desc_image_info.setImageView(texture_vk.GetImageView());
    image_descs.push_back(desc_image_info);

    vk::WriteDescriptorSet write_set;
    write_set.setDstSet(desc_set);
    write_set.setDstBinding(slot.binding);
    write_set.setDescriptorCount(1);
    write_set.setDescriptorType(vk::DescriptorType::eCombinedImageSampler);
    write_set.setPImageInfo(&image_descs.back());

    writes.push_back(write_set);
  }

  if (writes.empty()) {
    return true;
  }
  device.updateDescriptorSets(writes, {});
  return true;
}

static bool AllocateAndBindDescriptorSets(
    const ContextVK& context,
    const Command& command,
    CommandEncoderVK& encoder,
    PipelineCreateInfoVK* pipeline_create_info) {
  auto& allocator = *context.GetResourceAllocator();
  vk::PipelineLayout pipeline_layout =
      pipeline_create_info->GetPipelineLayout();

  vk::DescriptorSetAllocateInfo alloc_info;
  std::array<vk::DescriptorSetLayout, 1> dsls = {
      pipeline_create_info->GetDescriptorSetLayout(),
  };

  alloc_info.setDescriptorPool(context.GetDescriptorPool());
  alloc_info.setSetLayouts(dsls);

  auto [sets_result, sets] =
      context.GetDevice().allocateDescriptorSetsUnique(alloc_info);
  if (sets_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to allocate descriptor sets: "
                   << vk::to_string(sets_result);
    return false;
  }

  const auto set = MakeSharedVK<vk::DescriptorSet>(std::move(sets[0]));

  if (!encoder.Track(set)) {
    return false;
  }

  bool update_vertex_descriptors =
      UpdateDescriptorSets(context.GetDevice(),      //
                           command.vertex_bindings,  //
                           allocator,                //
                           *set,                     //
                           encoder                   //
      );
  if (!update_vertex_descriptors) {
    return false;
  }
  bool update_frag_descriptors =
      UpdateDescriptorSets(context.GetDevice(),        //
                           command.fragment_bindings,  //
                           allocator,                  //
                           *set,                       //
                           encoder                     //
      );
  if (!update_frag_descriptors) {
    return false;
  }

  encoder.GetCommandBuffer().bindDescriptorSets(
      vk::PipelineBindPoint::eGraphics,  // bind point
      pipeline_layout,                   // layout
      0,                                 // first set
      {vk::DescriptorSet{*set}},         // sets
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

  auto& pipeline_vk = PipelineVK::Cast(*command.pipeline);
  PipelineCreateInfoVK* pipeline_create_info = pipeline_vk.GetCreateInfo();

  if (!AllocateAndBindDescriptorSets(ContextVK::Cast(context),  //
                                     command,                   //
                                     encoder,                   //
                                     pipeline_create_info       //
                                     )) {
    return false;
  }

  cmd_buffer.bindPipeline(vk::PipelineBindPoint::eGraphics,
                          pipeline_create_info->GetVKPipeline());

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
  auto vertex_buffer_handle =
      DeviceBufferVK::Cast(*vertex_buffer).GetVKBufferHandle();
  vk::Buffer vertex_buffers[] = {vertex_buffer_handle};
  vk::DeviceSize vertex_buffer_offsets[] = {vertex_buffer_view.range.offset};
  cmd_buffer.bindVertexBuffers(0u, 1u, vertex_buffers, vertex_buffer_offsets);

  // Bind the index buffer.
  auto index_buffer_handle =
      DeviceBufferVK::Cast(*index_buffer).GetVKBufferHandle();
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
  if (!IsValid()) {
    return false;
  }

  if (commands_.empty()) {
    return true;
  }

  const auto& vk_context = ContextVK::Cast(context);

  const auto& render_target = GetRenderTarget();
  if (!render_target.HasColorAttachment(0u)) {
    VALIDATION_LOG
        << "Render target doesn't have a color attachment at index 0.";
    return false;
  }

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

  if (!ConfigureRenderTargetAttachmentLayouts(render_target, cmd_buffer)) {
    VALIDATION_LOG << "Could not complete attachment layout transitions.";
    return false;
  }

  const auto& target_size = render_target.GetRenderTargetSize();

  auto framebuffer = MakeSharedVK(
      CreateFramebuffer(vk_context.GetDevice(), render_target_, *render_pass_));
  if (!encoder->Track(framebuffer)) {
    return false;
  }

  auto clear_values = GetVKClearValues(render_target);

  vk::RenderPassBeginInfo pass_info;
  pass_info.renderPass = *render_pass_;
  pass_info.framebuffer = *framebuffer;
  pass_info.renderArea.extent.width = static_cast<uint32_t>(target_size.width);
  pass_info.renderArea.extent.height =
      static_cast<uint32_t>(target_size.height);
  pass_info.setClearValues(clear_values);

  {
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
