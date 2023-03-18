// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/pipeline_library_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_library_vk.h"
#include "impeller/renderer/backend/vulkan/shader_library_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/device_capabilities.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/surface.h"

namespace impeller {

namespace vk {

// TODO(csg): Move this to its own TU for validations.
constexpr const char* kKhronosValidationLayerName =
    "VK_LAYER_KHRONOS_validation";

bool HasValidationLayers();

}  // namespace vk

class CommandEncoderVK;

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
  const IDeviceCapabilities& GetDeviceCapabilities() const override;

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
      VALIDATION_LOG << "Unable to set debug name: " << label;
      return false;
    }

    return true;
  }

  vk::Instance GetInstance() const;

  vk::Device GetDevice() const;

  [[nodiscard]] bool SetWindowSurface(vk::UniqueSurfaceKHR surface);

  std::unique_ptr<Surface> AcquireNextSurface();

#ifdef FML_OS_ANDROID
  vk::UniqueSurfaceKHR CreateAndroidSurface(ANativeWindow* window) const;
#endif  // FML_OS_ANDROID

  vk::Queue GetGraphicsQueue() const;

  vk::CommandPool GetGraphicsCommandPool() const;

  vk::DescriptorPool GetDescriptorPool() const;

  vk::PhysicalDevice GetPhysicalDevice() const;

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
  vk::Queue graphics_queue_ = {};
  vk::Queue compute_queue_ = {};
  vk::Queue transfer_queue_ = {};
  std::shared_ptr<SwapchainVK> swapchain_;
  std::unique_ptr<IDeviceCapabilities> device_capabilities_;
  vk::UniqueCommandPool graphics_command_pool_;
  vk::UniqueDescriptorPool descriptor_pool_;
  bool is_valid_ = false;

  ContextVK(
      PFN_vkGetInstanceProcAddr proc_address_callback,
      const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_data,
      const std::shared_ptr<const fml::Mapping>& pipeline_cache_data,
      std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner,
      const std::string& label);

  std::unique_ptr<CommandEncoderVK> CreateGraphicsCommandEncoder() const;

  FML_DISALLOW_COPY_AND_ASSIGN(ContextVK);
};

}  // namespace impeller
