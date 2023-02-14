// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/deletion_queue_vk.h"
#include "impeller/renderer/backend/vulkan/descriptor_pool_vk.h"
#include "impeller/renderer/backend/vulkan/pipeline_library_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_library_vk.h"
#include "impeller/renderer/backend/vulkan/shader_library_vk.h"
#include "impeller/renderer/backend/vulkan/surface_producer_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/device_capabilities.h"
#include "impeller/renderer/formats.h"

namespace impeller {

namespace vk {

constexpr const char* kKhronosValidationLayerName =
    "VK_LAYER_KHRONOS_validation";

bool HasValidationLayers();

}  // namespace vk

class ContextVK final : public Context, public BackendCast<ContextVK, Context> {
 public:
  static std::shared_ptr<ContextVK> Create(
      PFN_vkGetInstanceProcAddr proc_address_callback,
      const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_data,
      const std::shared_ptr<const fml::Mapping>& pipeline_cache_data,
      std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner,
      const std::string& label);

  // |Context|
  ~ContextVK() override;

  // |Context|
  bool IsValid() const override;

  template <typename T>
  bool SetDebugName(T handle, std::string_view label) const {
    return SetDebugName(*device_, handle, label);
  }

  template <typename T>
  static bool SetDebugName(vk::Device device,
                           T handle,
                           std::string_view label) {
    if (!vk::HasValidationLayers()) {
      // No-op if validation layers are not enabled.
      return true;
    }

    uint64_t handle_ptr =
        reinterpret_cast<uint64_t>(static_cast<typename T::NativeType>(handle));

    std::string label_str = std::string(label);
    auto ret = device.setDebugUtilsObjectNameEXT(
        vk::DebugUtilsObjectNameInfoEXT()
            .setObjectType(T::objectType)
            .setObjectHandle(handle_ptr)
            .setPObjectName(label_str.c_str()));

    if (ret != vk::Result::eSuccess) {
      VALIDATION_LOG << "unable to set debug name";
      return false;
    }

    return true;
  }

  vk::Instance GetInstance() const;

  void SetupSwapchain(vk::UniqueSurfaceKHR surface);

  std::unique_ptr<Surface> AcquireSurface(size_t current_frame);

  std::unique_ptr<DescriptorPoolVK> CreateDescriptorPool() const;

#ifdef FML_OS_ANDROID
  vk::UniqueSurfaceKHR CreateAndroidSurface(ANativeWindow* window) const;
#endif  // FML_OS_ANDROID

  vk::Queue GetGraphicsQueue() const;

  std::unique_ptr<CommandPoolVK> CreateGraphicsCommandPool() const;

 private:
  std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner_;
  vk::UniqueInstance instance_;
  vk::UniqueDebugUtilsMessengerEXT debug_messenger_;
  vk::PhysicalDevice physical_device_;
  vk::UniqueDevice device_;
  std::shared_ptr<Allocator> allocator_;
  std::shared_ptr<ShaderLibraryVK> shader_library_;
  std::shared_ptr<SamplerLibraryVK> sampler_library_;
  std::shared_ptr<PipelineLibraryVK> pipeline_library_;
  uint32_t graphics_queue_idx_;
  vk::Queue graphics_queue_;
  vk::Queue compute_queue_;
  vk::Queue transfer_queue_;
  vk::Queue present_queue_;
  vk::UniqueSurfaceKHR surface_;
  vk::Format surface_format_;
  std::unique_ptr<SwapchainVK> swapchain_;
  std::unique_ptr<SurfaceProducerVK> surface_producer_;
  std::shared_ptr<WorkQueue> work_queue_;
  std::unique_ptr<IDeviceCapabilities> device_capabilities_;
  bool is_valid_ = false;

  ContextVK(
      PFN_vkGetInstanceProcAddr proc_address_callback,
      const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_data,
      const std::shared_ptr<const fml::Mapping>& pipeline_cache_data,
      std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner,
      const std::string& label);

  // |Context|
  std::shared_ptr<Allocator> GetResourceAllocator() const override;

  // |Context|
  std::shared_ptr<ShaderLibrary> GetShaderLibrary() const override;

  // |Context|
  std::shared_ptr<SamplerLibrary> GetSamplerLibrary() const override;

  // |Context|
  std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const override;

  // |Context|
  std::shared_ptr<CommandBuffer> CreateCommandBuffer() const override;

  // |Context|
  PixelFormat GetColorAttachmentPixelFormat() const override;

  // |Context|
  std::shared_ptr<WorkQueue> GetWorkQueue() const override;

  // |Context|
  const IDeviceCapabilities& GetDeviceCapabilities() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(ContextVK);
};

}  // namespace impeller
