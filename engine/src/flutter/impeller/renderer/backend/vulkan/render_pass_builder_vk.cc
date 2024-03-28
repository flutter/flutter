// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/render_pass_builder_vk.h"

#include <vector>

#include "impeller/renderer/backend/vulkan/formats_vk.h"

namespace impeller {

constexpr auto kSelfDependencySrcStageMask =
    vk::PipelineStageFlagBits::eColorAttachmentOutput;
constexpr auto kSelfDependencySrcAccessMask =
    vk::AccessFlagBits::eColorAttachmentWrite;

constexpr auto kSelfDependencyDstStageMask =
    vk::PipelineStageFlagBits::eFragmentShader;
constexpr auto kSelfDependencyDstAccessMask =
    vk::AccessFlagBits::eInputAttachmentRead;

constexpr auto kSelfDependencyFlags = vk::DependencyFlagBits::eByRegion;

RenderPassBuilderVK::RenderPassBuilderVK() = default;

RenderPassBuilderVK::~RenderPassBuilderVK() = default;

RenderPassBuilderVK& RenderPassBuilderVK::SetColorAttachment(
    size_t index,
    PixelFormat format,
    SampleCount sample_count,
    LoadAction load_action,
    StoreAction store_action) {
  vk::AttachmentDescription desc;
  desc.format = ToVKImageFormat(format);
  desc.samples = ToVKSampleCount(sample_count);
  desc.loadOp = ToVKAttachmentLoadOp(load_action);
  desc.storeOp = ToVKAttachmentStoreOp(store_action, false);
  desc.stencilLoadOp = vk::AttachmentLoadOp::eDontCare;
  desc.stencilStoreOp = vk::AttachmentStoreOp::eDontCare;
  desc.initialLayout = vk::ImageLayout::eGeneral;
  desc.finalLayout = vk::ImageLayout::eGeneral;
  colors_[index] = desc;

  if (StoreActionPerformsResolve(store_action)) {
    desc.storeOp = ToVKAttachmentStoreOp(store_action, true);
    desc.samples = vk::SampleCountFlagBits::e1;
    resolves_[index] = desc;
  } else {
    resolves_.erase(index);
  }
  return *this;
}

RenderPassBuilderVK& RenderPassBuilderVK::SetDepthStencilAttachment(
    PixelFormat format,
    SampleCount sample_count,
    LoadAction load_action,
    StoreAction store_action) {
  vk::AttachmentDescription desc;
  desc.format = ToVKImageFormat(format);
  desc.samples = ToVKSampleCount(sample_count);
  desc.loadOp = ToVKAttachmentLoadOp(load_action);
  desc.storeOp = ToVKAttachmentStoreOp(store_action, false);
  desc.stencilLoadOp = desc.loadOp;    // Not separable in Impeller.
  desc.stencilStoreOp = desc.storeOp;  // Not separable in Impeller.
  desc.initialLayout = vk::ImageLayout::eUndefined;
  desc.finalLayout = vk::ImageLayout::eDepthStencilAttachmentOptimal;
  depth_stencil_ = desc;
  return *this;
}

RenderPassBuilderVK& RenderPassBuilderVK::SetStencilAttachment(
    PixelFormat format,
    SampleCount sample_count,
    LoadAction load_action,
    StoreAction store_action) {
  vk::AttachmentDescription desc;
  desc.format = ToVKImageFormat(format);
  desc.samples = ToVKSampleCount(sample_count);
  desc.loadOp = vk::AttachmentLoadOp::eDontCare;
  desc.storeOp = vk::AttachmentStoreOp::eDontCare;
  desc.stencilLoadOp = ToVKAttachmentLoadOp(load_action);
  desc.stencilStoreOp = ToVKAttachmentStoreOp(store_action, false);
  desc.initialLayout = vk::ImageLayout::eUndefined;
  desc.finalLayout = vk::ImageLayout::eDepthStencilAttachmentOptimal;
  depth_stencil_ = desc;
  return *this;
}

vk::UniqueRenderPass RenderPassBuilderVK::Build(
    const vk::Device& device) const {
  // This must be less than `VkPhysicalDeviceLimits::maxColorAttachments` but we
  // are not checking.
  const auto color_attachments_count =
      colors_.empty() ? 0u : colors_.rbegin()->first + 1u;

  std::vector<vk::AttachmentDescription> attachments;

  std::vector<vk::AttachmentReference> color_refs(color_attachments_count,
                                                  kUnusedAttachmentReference);
  std::vector<vk::AttachmentReference> resolve_refs(color_attachments_count,
                                                    kUnusedAttachmentReference);
  vk::AttachmentReference depth_stencil_ref = kUnusedAttachmentReference;

  for (const auto& color : colors_) {
    vk::AttachmentReference color_ref;
    color_ref.attachment = attachments.size();
    color_ref.layout = vk::ImageLayout::eGeneral;
    color_refs[color.first] = color_ref;
    attachments.push_back(color.second);

    if (auto found = resolves_.find(color.first); found != resolves_.end()) {
      vk::AttachmentReference resolve_ref;
      resolve_ref.attachment = attachments.size();
      resolve_ref.layout = vk::ImageLayout::eGeneral;
      resolve_refs[color.first] = resolve_ref;
      attachments.push_back(found->second);
    }
  }

  if (depth_stencil_.has_value()) {
    depth_stencil_ref.attachment = attachments.size();
    depth_stencil_ref.layout = vk::ImageLayout::eGeneral;
    attachments.push_back(depth_stencil_.value());
  }

  vk::SubpassDescription subpass0;
  subpass0.pipelineBindPoint = vk::PipelineBindPoint::eGraphics;
  subpass0.setInputAttachments(color_refs);
  subpass0.setColorAttachments(color_refs);
  subpass0.setResolveAttachments(resolve_refs);
  subpass0.setPDepthStencilAttachment(&depth_stencil_ref);

  vk::SubpassDependency self_dep;
  self_dep.srcSubpass = 0u;  // first subpass
  self_dep.dstSubpass = 0u;  // to itself
  self_dep.srcStageMask = kSelfDependencySrcStageMask;
  self_dep.srcAccessMask = kSelfDependencySrcAccessMask;
  self_dep.dstStageMask = kSelfDependencyDstStageMask;
  self_dep.dstAccessMask = kSelfDependencyDstAccessMask;
  self_dep.dependencyFlags = kSelfDependencyFlags;

  vk::RenderPassCreateInfo render_pass_desc;
  render_pass_desc.setAttachments(attachments);
  render_pass_desc.setSubpasses(subpass0);
  render_pass_desc.setDependencies(self_dep);

  auto [result, pass] = device.createRenderPassUnique(render_pass_desc);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to create render pass: " << vk::to_string(result);
    return {};
  }
  return std::move(pass);
}

void InsertBarrierForInputAttachmentRead(const vk::CommandBuffer& buffer,
                                         const vk::Image& image) {
  // This barrier must be a subset of the masks specified in the subpass
  // dependency setup.
  vk::ImageMemoryBarrier barrier;
  barrier.srcAccessMask = kSelfDependencySrcAccessMask;
  barrier.dstAccessMask = kSelfDependencyDstAccessMask;
  barrier.oldLayout = vk::ImageLayout::eGeneral;
  barrier.newLayout = vk::ImageLayout::eGeneral;
  barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  barrier.image = image;

  vk::ImageSubresourceRange image_levels;
  image_levels.aspectMask = vk::ImageAspectFlagBits::eColor;
  image_levels.baseArrayLayer = 0u;
  image_levels.baseMipLevel = 0u;
  image_levels.layerCount = VK_REMAINING_ARRAY_LAYERS;
  image_levels.levelCount = VK_REMAINING_MIP_LEVELS;
  barrier.subresourceRange = image_levels;

  buffer.pipelineBarrier(kSelfDependencySrcStageMask,  //
                         kSelfDependencyDstStageMask,  //
                         kSelfDependencyFlags,         //
                         {},                           //
                         {},                           //
                         barrier                       //
  );
}

const std::map<size_t, vk::AttachmentDescription>&
RenderPassBuilderVK::GetColorAttachments() const {
  return colors_;
}

const std::map<size_t, vk::AttachmentDescription>&
RenderPassBuilderVK::GetResolves() const {
  return resolves_;
}

const std::optional<vk::AttachmentDescription>&
RenderPassBuilderVK::GetDepthStencil() const {
  return depth_stencil_;
}

}  // namespace impeller
