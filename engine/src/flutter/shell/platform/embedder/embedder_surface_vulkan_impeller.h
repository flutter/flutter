// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SURFACE_VULKAN_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SURFACE_VULKAN_IMPELLER_H_

#include "flutter/shell/common/context_options.h"
#include "flutter/shell/gpu/gpu_surface_vulkan.h"
#include "flutter/shell/gpu/gpu_surface_vulkan_delegate.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_external_view_embedder.h"
#include "flutter/shell/platform/embedder/embedder_surface.h"
#include "flutter/vulkan/procs/vulkan_proc_table.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"

namespace flutter {

class EmbedderSurfaceVulkanImpeller final : public EmbedderSurface,
                                            public GPUSurfaceVulkanDelegate {
 public:
  struct VulkanDispatchTable {
    /// Resolves Vulkan function pointers from the instance. Required.
    PFN_vkGetInstanceProcAddr get_instance_proc_address;
    /// Acquires the next swapchain image for rendering.
    /// Required for the delegate path; unused when a VkSurfaceKHR is provided.
    std::function<FlutterVulkanImage(const DlISize& frame_size)> get_next_image;
    /// Presents a rendered image to the display.
    /// Required for the delegate path; unused when a VkSurfaceKHR is provided.
    std::function<bool(VkImage image, VkFormat format)> present_image;
  };

  /// Creates an embedder surface for Vulkan+Impeller rendering.
  ///
  /// When |surface| is VK_NULL_HANDLE (default/legacy), the delegate path
  /// is used: the embedder provides swapchain images via callbacks.
  ///
  /// When |surface| is a valid VkSurfaceKHR, the KHR swapchain path is used:
  /// Impeller manages swapchain, frame throttling, and resource lifecycle
  /// internally -- identical to the Android Vulkan path.
  EmbedderSurfaceVulkanImpeller(
      uint32_t version,
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
      VkSurfaceKHR surface = VK_NULL_HANDLE);

  ~EmbedderSurfaceVulkanImpeller() override;

  // |GPUSurfaceVulkanDelegate|
  const vulkan::VulkanProcTable& vk() override;

  // |GPUSurfaceVulkanDelegate|
  FlutterVulkanImage AcquireImage(const DlISize& size) override;

  // |GPUSurfaceVulkanDelegate|
  bool PresentImage(VkImage image, VkFormat format) override;

  // |GPUSurfaceVulkanDelegate|
  std::shared_ptr<impeller::Context> CreateImpellerContext() const override;

  // |EmbedderSurface|
  void UpdateSurfaceSize(int64_t width, int64_t height) override;

  /// Returns the SurfaceContextVK used in KHR swapchain mode.
  /// Returns nullptr in delegate mode. Used by EmbedderEngine to update
  /// the swapchain size on viewport metrics changes.
  std::shared_ptr<impeller::SurfaceContextVK> GetSurfaceContext() const;

 private:
  bool valid_ = false;
  fml::RefPtr<vulkan::VulkanProcTable> vk_;
  VulkanDispatchTable vulkan_dispatch_table_;
  std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder_;
  std::shared_ptr<impeller::ContextVK> context_;

  /// When true, uses Impeller's KHR swapchain path (like Android).
  bool use_khr_swapchain_ = false;

  /// SurfaceContextVK -- only created in KHR swapchain mode.
  std::shared_ptr<impeller::SurfaceContextVK> surface_context_vk_;

  // |EmbedderSurface|
  bool IsValid() const override;

  // |EmbedderSurface|
  std::unique_ptr<Surface> CreateGPUSurface() override;

  // |EmbedderSurface|
  sk_sp<GrDirectContext> CreateResourceContext() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderSurfaceVulkanImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SURFACE_VULKAN_IMPELLER_H_
