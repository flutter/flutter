// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"

#include "flutter/shell/platform/embedder/tests/embedder_test_context_vulkan.h"
#include "flutter/vulkan/vulkan_device.h"  // nogncheck
#include "vulkan/vulkan_core.h"            // nogncheck

namespace flutter::testing {

void EmbedderConfigBuilder::InitializeVulkanRendererConfig() {
  if (context_.GetContextType() != EmbedderTestContextType::kVulkanContext) {
    return;
  }

  vulkan_renderer_config_.struct_size = sizeof(FlutterVulkanRendererConfig);
  vulkan_renderer_config_.version =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->application_->GetAPIVersion();
  vulkan_renderer_config_.instance =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->application_->GetInstance();
  vulkan_renderer_config_.physical_device =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->device_->GetPhysicalDeviceHandle();
  vulkan_renderer_config_.device =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->device_->GetHandle();
  vulkan_renderer_config_.queue_family_index =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->device_->GetGraphicsQueueIndex();
  vulkan_renderer_config_.queue =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->device_->GetQueueHandle();
  vulkan_renderer_config_.get_instance_proc_address_callback =
      EmbedderTestContextVulkan::InstanceProcAddr;
  vulkan_renderer_config_.get_next_image_callback =
      [](void* context,
         const FlutterFrameInfo* frame_info) -> FlutterVulkanImage {
    VkImage image =
        reinterpret_cast<EmbedderTestContextVulkan*>(context)->GetNextImage(
            {static_cast<int>(frame_info->size.width),
             static_cast<int>(frame_info->size.height)});
    return {
        .struct_size = sizeof(FlutterVulkanImage),
        .image = reinterpret_cast<uint64_t>(image),
        .format = VK_FORMAT_R8G8B8A8_UNORM,
    };
  };
  vulkan_renderer_config_.present_image_callback =
      [](void* context, const FlutterVulkanImage* image) -> bool {
    return reinterpret_cast<EmbedderTestContextVulkan*>(context)->PresentImage(
        reinterpret_cast<VkImage>(image->image));
  };
}

void EmbedderConfigBuilder::SetVulkanRendererConfig(
    SkISize surface_size,
    std::optional<FlutterVulkanInstanceProcAddressCallback>
        instance_proc_address_callback) {
  renderer_config_.type = FlutterRendererType::kVulkan;
  FlutterVulkanRendererConfig vulkan_renderer_config = vulkan_renderer_config_;
  if (instance_proc_address_callback.has_value()) {
    vulkan_renderer_config.get_instance_proc_address_callback =
        instance_proc_address_callback.value();
  }
  renderer_config_.vulkan = vulkan_renderer_config;
  context_.SetupSurface(surface_size);
}

}  // namespace flutter::testing
