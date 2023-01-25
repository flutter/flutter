// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/swapchain_details_vk.h"

#include "impeller/base/validation.h"

namespace impeller {

std::unique_ptr<SwapchainDetailsVK> SwapchainDetailsVK::Create(
    vk::PhysicalDevice physical_device,
    vk::SurfaceKHR surface) {
  FML_DCHECK(surface) << "surface provided as nullptr";

  auto capabilities_res = physical_device.getSurfaceCapabilitiesKHR(surface);
  if (capabilities_res.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to get surface capabilities: "
                   << vk::to_string(capabilities_res.result);
    return nullptr;
  }
  vk::SurfaceCapabilitiesKHR capabilities = capabilities_res.value;

  auto surface_formats_res = physical_device.getSurfaceFormatsKHR(surface);
  if (surface_formats_res.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to get surface formats: "
                   << vk::to_string(surface_formats_res.result);
    return nullptr;
  }
  std::vector<vk::SurfaceFormatKHR> surface_formats = surface_formats_res.value;

  auto surface_present_modes_res =
      physical_device.getSurfacePresentModesKHR(surface);
  if (surface_present_modes_res.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to get surface present modes: "
                   << vk::to_string(surface_present_modes_res.result);
    return nullptr;
  }
  std::vector<vk::PresentModeKHR> surface_present_modes =
      surface_present_modes_res.value;

  const auto composite_alphas = capabilities.supportedCompositeAlpha;
  vk::CompositeAlphaFlagBitsKHR composite_alpha;
  if (composite_alphas & vk::CompositeAlphaFlagBitsKHR::eOpaque) {
    composite_alpha = vk::CompositeAlphaFlagBitsKHR::eOpaque;
  } else if (composite_alphas & vk::CompositeAlphaFlagBitsKHR::eInherit) {
    composite_alpha = vk::CompositeAlphaFlagBitsKHR::eInherit;
  } else {
    VALIDATION_LOG << "No supported composite alpha found.";
    return nullptr;
  }

  return std::make_unique<SwapchainDetailsVK>(
      capabilities, surface_formats, surface_present_modes, composite_alpha);
}

vk::SurfaceFormatKHR SwapchainDetailsVK::PickSurfaceFormat() const {
  for (const auto& format : surface_formats_) {
    if ((format.format == vk::Format::eR8G8B8A8Unorm ||
         format.format == vk::Format::eB8G8R8A8Unorm) &&
        format.colorSpace == vk::ColorSpaceKHR::eSrgbNonlinear) {
      return format;
    }
  }

  VALIDATION_LOG << "Picking a sub-optimal surface format.";
  return surface_formats_[0];
}

vk::PresentModeKHR SwapchainDetailsVK::PickPresentationMode() const {
  for (const auto& mode : present_modes_) {
    if (mode == vk::PresentModeKHR::eMailbox) {
      return mode;
    }
  }

  FML_LOG(ERROR) << "Picking a sub-optimal presentation mode.";
  // Vulkan spec dictates that FIFO is always available.
  return vk::PresentModeKHR::eFifo;
}

vk::CompositeAlphaFlagBitsKHR SwapchainDetailsVK::PickCompositeAlpha() const {
  return composite_alpha_;
}

vk::Extent2D SwapchainDetailsVK::PickExtent() const {
  if (surface_capabilities_.currentExtent.width !=
      std::numeric_limits<uint32_t>::max()) {
    return surface_capabilities_.currentExtent;
  }

  vk::Extent2D actual_extent = {
      std::max(surface_capabilities_.minImageExtent.width,
               std::min(surface_capabilities_.maxImageExtent.width,
                        surface_capabilities_.currentExtent.width)),
      std::max(surface_capabilities_.minImageExtent.height,
               std::min(surface_capabilities_.maxImageExtent.height,
                        surface_capabilities_.currentExtent.height))};
  return actual_extent;
}

uint32_t SwapchainDetailsVK::GetImageCount() const {
  uint32_t image_count = surface_capabilities_.minImageCount;
  // for triple buffering
  return image_count + 1;
}

vk::SurfaceTransformFlagBitsKHR SwapchainDetailsVK::GetTransform() const {
  return surface_capabilities_.currentTransform;
}

SwapchainDetailsVK::SwapchainDetailsVK(
    vk::SurfaceCapabilitiesKHR capabilities,
    std::vector<vk::SurfaceFormatKHR> surface_formats,
    std::vector<vk::PresentModeKHR> surface_present_modes,
    vk::CompositeAlphaFlagBitsKHR composite_alpha)
    : surface_capabilities_(capabilities),
      surface_formats_(std::move(surface_formats)),
      present_modes_(std::move(surface_present_modes)),
      composite_alpha_(composite_alpha) {}

SwapchainDetailsVK::~SwapchainDetailsVK() = default;

}  // namespace impeller
