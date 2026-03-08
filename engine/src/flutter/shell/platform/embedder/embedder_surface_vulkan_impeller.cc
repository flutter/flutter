// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_surface_vulkan_impeller.h"

#include <cstring>
#include <utility>

#include "flutter/impeller/entity/vk/entity_shaders_vk.h"
#include "flutter/impeller/entity/vk/framebuffer_blend_shaders_vk.h"
#include "flutter/impeller/entity/vk/modern_shaders_vk.h"
#include "flutter/shell/gpu/gpu_surface_vulkan.h"
#include "impeller/display_list/aiks_context.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain/swapchain_vk.h"
#include "include/gpu/ganesh/GrDirectContext.h"
#include "shell/gpu/gpu_surface_vulkan_impeller.h"

namespace flutter {

EmbedderSurfaceVulkanImpeller::EmbedderSurfaceVulkanImpeller(
    uint32_t /*version*/,
    VkInstance instance,
    size_t instance_extension_count,
    const char** instance_extensions,
    size_t device_extension_count,
    const char** device_extensions,
    VkPhysicalDevice physical_device,
    VkDevice device,
    uint32_t queue_family_index,
    VkQueue queue,
    const VulkanDispatchTable& vulkan_dispatch_table,
    std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder,
    VkSurfaceKHR surface)
    : vk_(fml::MakeRefCounted<vulkan::VulkanProcTable>(
          vulkan_dispatch_table.get_instance_proc_address)),
      vulkan_dispatch_table_(vulkan_dispatch_table),
      external_view_embedder_(std::move(external_view_embedder)) {
  // Make sure all required members of the dispatch table are checked.
  if (!vulkan_dispatch_table_.get_instance_proc_address ||
      (!surface && !vulkan_dispatch_table_.get_next_image) ||
      (!surface && !vulkan_dispatch_table_.present_image)) {
    return;
  }

  std::vector<std::shared_ptr<fml::Mapping>> shader_mappings = {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_vk_data,
                                             impeller_entity_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_modern_shaders_vk_data,
                                             impeller_modern_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_framebuffer_blend_shaders_vk_data,
          impeller_framebuffer_blend_shaders_vk_length),
  };
  impeller::ContextVK::Settings settings;
  settings.shader_libraries_data = shader_mappings;
  settings.proc_address_callback =
      vulkan_dispatch_table.get_instance_proc_address;

  impeller::ContextVK::EmbedderData data;
  data.instance = instance;
  data.physical_device = physical_device;
  data.device = device;
  data.queue = queue;
  data.queue_family_index = queue_family_index;
  data.instance_extensions.reserve(instance_extension_count);
  for (auto i = 0u; i < instance_extension_count; i++) {
    data.instance_extensions.push_back(std::string{instance_extensions[i]});
  }
  data.device_extensions.reserve(device_extension_count);
  for (auto i = 0u; i < device_extension_count; i++) {
    data.device_extensions.push_back(std::string{device_extensions[i]});
  }
  settings.embedder_data = data;

  // The embedder controls the VkInstance and its layers/extensions.
  // Only enable Impeller validation if the embedder actually enabled the
  // debug_utils extension (otherwise CapabilitiesVK will fail trying to
  // require VK_EXT_debug_utils on the embedder-provided instance).
  bool has_debug_utils = false;
  for (size_t i = 0; i < instance_extension_count; i++) {
    if (strcmp(instance_extensions[i], VK_EXT_DEBUG_UTILS_EXTENSION_NAME) ==
        0) {
      has_debug_utils = true;
      break;
    }
  }
  settings.enable_validation = has_debug_utils;

  context_ = impeller::ContextVK::Create(std::move(settings));
  if (!context_) {
    FML_LOG(ERROR) << "Failed to initialize Vulkan Context.";
    return;
  }

  FML_LOG(IMPORTANT) << "Using the Impeller rendering backend (Vulkan)."
                     << (surface != VK_NULL_HANDLE
                             ? " [KHR swapchain mode]"
                             : " [embedder delegate mode]");

  // If a VkSurfaceKHR was provided, set up the KHR swapchain path.
  // This is the same code path used by Android -- Impeller manages
  // swapchain creation, image acquisition, presentation, frame throttling,
  // and resource lifecycle internally.
  if (surface != VK_NULL_HANDLE) {
    use_khr_swapchain_ = true;
    surface_context_vk_ = context_->CreateSurfaceContext();
    if (!surface_context_vk_) {
      FML_LOG(ERROR) << "Failed to create SurfaceContextVK.";
      return;
    }

    // Create the KHR swapchain from the provided VkSurfaceKHR.
    // The VkSurfaceKHR is wrapped in a vk::UniqueSurfaceKHR so Impeller
    // can manage its lifetime and pass it to KHRSwapchainImplVK.
    auto vk_surface = impeller::vk::UniqueSurfaceKHR(
        surface, {static_cast<impeller::vk::Instance>(instance)});

    // Query the surface extent so the swapchain starts at the correct size.
    // On X11, VkSurfaceCapabilitiesKHR.currentExtent reports the window
    // dimensions directly. On Wayland, currentExtent is the special value
    // {0xFFFFFFFF, 0xFFFFFFFF} (meaning the application chooses), so we
    // fall back to a reasonable default; the correct size will be set via
    // UpdateSurfaceSize() when the first window metrics event arrives.
    impeller::ISize initial_size{800, 600};  // fallback for Wayland
    auto get_caps =
        reinterpret_cast<PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR>(
            vulkan_dispatch_table.get_instance_proc_address(
                instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR"));
    if (get_caps) {
      VkSurfaceCapabilitiesKHR caps{};
      if (get_caps(physical_device, surface, &caps) == VK_SUCCESS) {
        constexpr uint32_t kCurrentExtentsPlaceholder = 0xFFFFFFFF;
        if (caps.currentExtent.width != kCurrentExtentsPlaceholder &&
            caps.currentExtent.height != kCurrentExtentsPlaceholder &&
            caps.currentExtent.width > 0 && caps.currentExtent.height > 0) {
          initial_size =
              impeller::ISize{static_cast<int64_t>(caps.currentExtent.width),
                              static_cast<int64_t>(caps.currentExtent.height)};
        }
      }
    }

    if (!surface_context_vk_->SetWindowSurface(std::move(vk_surface),
                                               initial_size)) {
      FML_LOG(ERROR) << "Failed to set up KHR swapchain.";
      use_khr_swapchain_ = false;
      surface_context_vk_.reset();
      return;
    }
    FML_DLOG(INFO) << "KHR swapchain initialized. Impeller manages "
                      "all swapchain operations.";
  }

  valid_ = true;
}

EmbedderSurfaceVulkanImpeller::~EmbedderSurfaceVulkanImpeller() = default;

std::shared_ptr<impeller::Context>
EmbedderSurfaceVulkanImpeller::CreateImpellerContext() const {
  // In KHR mode, return the SurfaceContextVK so Impeller uses it
  // as its rendering context (which includes swapchain access).
  if (use_khr_swapchain_ && surface_context_vk_) {
    return surface_context_vk_;
  }
  return context_;
}

// |GPUSurfaceVulkanDelegate|
const vulkan::VulkanProcTable& EmbedderSurfaceVulkanImpeller::vk() {
  return *vk_;
}

// |GPUSurfaceVulkanDelegate|
FlutterVulkanImage EmbedderSurfaceVulkanImpeller::AcquireImage(
    const DlISize& size) {
  FML_DCHECK(vulkan_dispatch_table_.get_next_image)
      << "AcquireImage called but get_next_image delegate is not set. "
         "This should not happen in KHR swapchain mode.";
  return vulkan_dispatch_table_.get_next_image(size);
}

// |GPUSurfaceVulkanDelegate|
bool EmbedderSurfaceVulkanImpeller::PresentImage(VkImage image,
                                                 VkFormat format) {
  FML_DCHECK(vulkan_dispatch_table_.present_image)
      << "PresentImage called but present_image delegate is not set. "
         "This should not happen in KHR swapchain mode.";
  return vulkan_dispatch_table_.present_image(image, format);
}

// |EmbedderSurface|
bool EmbedderSurfaceVulkanImpeller::IsValid() const {
  return valid_;
}

// |EmbedderSurface|
std::unique_ptr<Surface> EmbedderSurfaceVulkanImpeller::CreateGPUSurface() {
  if (use_khr_swapchain_) {
    // KHR swapchain path: pass nullptr delegate, SurfaceContextVK as context.
    // Impeller manages everything internally (like Android).
    return std::make_unique<GPUSurfaceVulkanImpeller>(nullptr,
                                                      surface_context_vk_);
  }
  // Legacy delegate path: embedder provides images via callbacks.
  return std::make_unique<GPUSurfaceVulkanImpeller>(this, context_);
}

// |EmbedderSurface|
void EmbedderSurfaceVulkanImpeller::UpdateSurfaceSize(int64_t width,
                                                      int64_t height) {
  if (use_khr_swapchain_ && surface_context_vk_ && width > 0 && height > 0) {
    surface_context_vk_->UpdateSurfaceSize(impeller::ISize{width, height});
  }
}

std::shared_ptr<impeller::SurfaceContextVK>
EmbedderSurfaceVulkanImpeller::GetSurfaceContext() const {
  return surface_context_vk_;
}

// |EmbedderSurface|
sk_sp<GrDirectContext> EmbedderSurfaceVulkanImpeller::CreateResourceContext()
    const {
  return nullptr;
}

}  // namespace flutter
