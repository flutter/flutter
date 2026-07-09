// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/render_pass_builder_vk.h"

#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"

namespace impeller {

namespace {
// Compute the final layout for a given image state.
vk::ImageLayout ComputeFinalLayout(bool is_swapchain, SampleCount count) {
  if (is_swapchain || count != SampleCount::kCount1) {
    return vk::ImageLayout::eGeneral;
  }
  return vk::ImageLayout::eShaderReadOnlyOptimal;
}
}  // namespace

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

RenderPassBuilderVK& RenderPassBuilderVK::SetFramebufferFetchEnabled(
    bool enabled) {
  supports_framebuffer_fetch_ = enabled;
  return *this;
}

RenderPassBuilderVK& RenderPassBuilderVK::SetColorAttachment(
    size_t index,
    PixelFormat format,
    SampleCount sample_count,
    LoadAction load_action,
    StoreAction store_action,
    vk::ImageLayout current_layout,
    bool is_swapchain) {
  vk::AttachmentDescription desc;
  desc.format = ToVKImageFormat(format);
  desc.samples = ToVKSampleCount(sample_count);
  desc.loadOp = ToVKAttachmentLoadOp(load_action);
  desc.storeOp = ToVKAttachmentStoreOp(store_action, false);
  desc.stencilLoadOp = vk::AttachmentLoadOp::eDontCare;
  desc.stencilStoreOp = vk::AttachmentStoreOp::eDontCare;
  if (load_action == LoadAction::kLoad) {
    desc.initialLayout = current_layout;
  } else {
    desc.initialLayout = vk::ImageLayout::eUndefined;
  }
  desc.finalLayout = ComputeFinalLayout(is_swapchain, sample_count);

  const bool performs_resolves = StoreActionPerformsResolve(store_action);
  if (index == 0u) {
    color0_ = desc;

    if (performs_resolves) {
      desc.storeOp = ToVKAttachmentStoreOp(store_action, true);
      desc.samples = vk::SampleCountFlagBits::e1;
      desc.finalLayout = ComputeFinalLayout(is_swapchain, SampleCount::kCount1);
      color0_resolve_ = desc;
    } else {
      color0_resolve_ = std::nullopt;
    }
  } else {
    colors_[index] = desc;
    if (performs_resolves) {
      desc.storeOp = ToVKAttachmentStoreOp(store_action, true);
      desc.samples = vk::SampleCountFlagBits::e1;
      desc.finalLayout = ComputeFinalLayout(is_swapchain, SampleCount::kCount1);
      resolves_[index] = desc;
    } else {
      resolves_.erase(index);
    }
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
  auto color_attachments_count =
      colors_.empty() ? 0u : colors_.rbegin()->first + 1u;
  if (color0_.has_value()) {
    color_attachments_count++;
  }

  std::array<vk::AttachmentDescription, kMaxAttachments> attachments;
  std::array<vk::AttachmentReference, kMaxColorAttachments> color_refs;
  std::array<vk::AttachmentReference, kMaxColorAttachments> resolve_refs;
  vk::AttachmentReference depth_stencil_ref = kUnusedAttachmentReference;
  size_t attachments_index = 0;
  size_t color_index = 0;
  size_t resolve_index = 0;

  if (color0_.has_value()) {
    vk::AttachmentReference color_ref;
    color_ref.attachment = attachments_index;
    color_ref.layout = vk::ImageLayout::eGeneral;
    color_refs.at(color_index++) = color_ref;
    attachments.at(attachments_index++) = color0_.value();

    if (color0_resolve_.has_value()) {
      vk::AttachmentReference resolve_ref;
      resolve_ref.attachment = attachments_index;
      resolve_ref.layout = vk::ImageLayout::eGeneral;
      resolve_refs.at(resolve_index++) = resolve_ref;
      attachments.at(attachments_index++) = color0_resolve_.value();
    } else {
      resolve_refs.at(resolve_index++) = kUnusedAttachmentReference;
    }
  }

  for (const auto& color : colors_) {
    vk::AttachmentReference color_ref;
    color_ref.attachment = attachments_index;
    color_ref.layout = vk::ImageLayout::eGeneral;
    color_refs.at(color_index++) = color_ref;
    attachments.at(attachments_index++) = color.second;

    if (auto found = resolves_.find(color.first); found != resolves_.end()) {
      vk::AttachmentReference resolve_ref;
      resolve_ref.attachment = attachments_index;
      resolve_ref.layout = vk::ImageLayout::eGeneral;
      resolve_refs.at(resolve_index++) = resolve_ref;
      attachments.at(attachments_index++) = found->second;
    } else {
      resolve_refs.at(resolve_index++) = kUnusedAttachmentReference;
    }
  }

  if (depth_stencil_.has_value()) {
    depth_stencil_ref.attachment = attachments_index;
    depth_stencil_ref.layout = vk::ImageLayout::eDepthStencilAttachmentOptimal;
    attachments.at(attachments_index++) = depth_stencil_.value();
  }

  vk::SubpassDescription subpass0;
  subpass0.pipelineBindPoint = vk::PipelineBindPoint::eGraphics;
  if (supports_framebuffer_fetch_) {
    subpass0.setPInputAttachments(color_refs.data());
    subpass0.setInputAttachmentCount(color_index);
  } else {
    subpass0.setPInputAttachments(nullptr);
    subpass0.setInputAttachmentCount(0);
  }
  subpass0.setPColorAttachments(color_refs.data());
  subpass0.setColorAttachmentCount(color_index);
  subpass0.setPResolveAttachments(resolve_refs.data());

  subpass0.setPDepthStencilAttachment(&depth_stencil_ref);

  // Build subpass dependencies. When framebuffer fetch is supported, a
  // self-dependency (subpass 0 -> subpass 0) is included so that fragment
  // shaders can read back the color attachment as an input attachment.
  // When framebuffer fetch is not supported (e.g. Mesa dzn), the
  // self-dependency is omitted because some drivers (D3D12 translation
  // layers) fail when a subpass self-dependency is present.
  constexpr size_t kMaxDeps = 3;
  vk::SubpassDependency deps[kMaxDeps];
  size_t dep_count = 0;

  // Incoming external dependency. If the attachments were previously used
  // as attachments for a render pass, or sampled from/transfered to,
  // then these operations must complete before we resolve anything
  // to the onscreen.
  // Note: dependencyFlags is {} (no flags) because VK_DEPENDENCY_BY_REGION_BIT
  // is only meaningful for self-dependencies (srcSubpass == dstSubpass).
  // Per Vulkan spec section 7.1, for non-self-dependencies the by-region
  // flag is implementation-dependent and may be silently ignored.
  deps[dep_count].srcSubpass = VK_SUBPASS_EXTERNAL;
  deps[dep_count].dstSubpass = 0u;
  // Include depth/stencil stages when a depth attachment is present.
  // The previous render pass writes depth at eLateFragmentTests; the
  // implicit layout transition inside vkCmdBeginRenderPass also writes
  // the depth image, so we must synchronize that previous write against
  // the new implicit write. This fixes SYNC-HAZARD-WRITE-AFTER-WRITE on
  // vkCmdBeginRenderPass reported by VK_LAYER_KHRONOS_validation sync.
  deps[dep_count].srcStageMask =
      vk::PipelineStageFlagBits::eColorAttachmentOutput |
      vk::PipelineStageFlagBits::eFragmentShader |
      (depth_stencil_.has_value()
           ? (vk::PipelineStageFlagBits::eEarlyFragmentTests |
              vk::PipelineStageFlagBits::eLateFragmentTests)
           : vk::PipelineStageFlags{});
  deps[dep_count].srcAccessMask =
      vk::AccessFlagBits::eShaderRead |
      vk::AccessFlagBits::eColorAttachmentWrite |
      (depth_stencil_.has_value()
           ? vk::AccessFlagBits::eDepthStencilAttachmentWrite
           : vk::AccessFlags{});
  deps[dep_count].dstStageMask =
      vk::PipelineStageFlagBits::eColorAttachmentOutput |
      (depth_stencil_.has_value()
           ? vk::PipelineStageFlagBits::eEarlyFragmentTests
           : vk::PipelineStageFlags{});
  deps[dep_count].dstAccessMask =
      vk::AccessFlagBits::eColorAttachmentWrite |
      (depth_stencil_.has_value()
           ? (vk::AccessFlagBits::eDepthStencilAttachmentWrite |
              vk::AccessFlagBits::eDepthStencilAttachmentRead)
           : vk::AccessFlags{});
  deps[dep_count].dependencyFlags = {};
  dep_count++;

  if (supports_framebuffer_fetch_) {
    // Self dependency for reading back the framebuffer, necessary for
    // programmable blend support / framebuffer fetch.
    deps[dep_count].srcSubpass = 0u;  // first subpass
    deps[dep_count].dstSubpass = 0u;  // to itself
    deps[dep_count].srcStageMask = kSelfDependencySrcStageMask;
    deps[dep_count].srcAccessMask = kSelfDependencySrcAccessMask;
    deps[dep_count].dstStageMask = kSelfDependencyDstStageMask;
    deps[dep_count].dstAccessMask = kSelfDependencyDstAccessMask;
    deps[dep_count].dependencyFlags = kSelfDependencyFlags;
    dep_count++;
  }

  // Outgoing external dependency. The resolve step or color attachment must
  // complete before we can sample from the image. This dependency is ignored
  // for the onscreen as we will already insert a barrier before presenting
  // the swapchain. Also cover depth writes so the next render pass's incoming
  // dependency can see them.
  // dependencyFlags is {} for the same reason as the incoming dependency
  // (VK_DEPENDENCY_BY_REGION_BIT is meaningless for VK_SUBPASS_EXTERNAL).
  deps[dep_count].srcSubpass = 0u;  // first subpass
  deps[dep_count].dstSubpass = VK_SUBPASS_EXTERNAL;
  deps[dep_count].srcStageMask =
      vk::PipelineStageFlagBits::eColorAttachmentOutput |
      (depth_stencil_.has_value()
           ? vk::PipelineStageFlagBits::eLateFragmentTests
           : vk::PipelineStageFlags{});
  deps[dep_count].srcAccessMask =
      vk::AccessFlagBits::eColorAttachmentWrite |
      (depth_stencil_.has_value()
           ? vk::AccessFlagBits::eDepthStencilAttachmentWrite
           : vk::AccessFlags{});
  deps[dep_count].dstStageMask = vk::PipelineStageFlagBits::eFragmentShader;
  deps[dep_count].dstAccessMask = vk::AccessFlagBits::eShaderRead;
  deps[dep_count].dependencyFlags = {};
  dep_count++;

  vk::RenderPassCreateInfo render_pass_desc;
  render_pass_desc.setPAttachments(attachments.data());
  render_pass_desc.setAttachmentCount(attachments_index);
  render_pass_desc.setSubpasses(subpass0);
  render_pass_desc.setPDependencies(deps);
  render_pass_desc.setDependencyCount(dep_count);

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

// Visible for testing.
std::optional<vk::AttachmentDescription> RenderPassBuilderVK::GetColor0()
    const {
  return color0_;
}

// Visible for testing.
std::optional<vk::AttachmentDescription> RenderPassBuilderVK::GetColor0Resolve()
    const {
  return color0_resolve_;
}

}  // namespace impeller
