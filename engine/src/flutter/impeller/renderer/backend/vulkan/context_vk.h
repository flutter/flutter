// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/unique_fd.h"
#include "impeller/base/backend_cast.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/device_holder.h"
#include "impeller/renderer/backend/vulkan/pipeline_library_vk.h"
#include "impeller/renderer/backend/vulkan/queue_vk.h"
#include "impeller/renderer/backend/vulkan/sampler_library_vk.h"
#include "impeller/renderer/backend/vulkan/shader_library_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/surface.h"

namespace impeller {

bool HasValidationLayers();

class CommandEncoderVK;
class DebugReportVK;
class FenceWaiterVK;

class ContextVK final : public Context,
                        public BackendCast<ContextVK, Context>,
                        public std::enable_shared_from_this<ContextVK> {
 public:
  struct Settings {
    PFN_vkGetInstanceProcAddr proc_address_callback = nullptr;
    std::vector<std::shared_ptr<fml::Mapping>> shader_libraries_data;
    fml::UniqueFD cache_directory;
    std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner;
    bool enable_validation = false;

    Settings() = default;

    Settings(Settings&&) = default;
  };

  static std::shared_ptr<ContextVK> Create(Settings settings);

  uint64_t GetHash() const { return hash_; }

  // |Context|
  ~ContextVK() override;

  // |Context|
  std::string DescribeGpuModel() const override;

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
  const std::shared_ptr<const Capabilities>& GetCapabilities() const override;

  template <typename T>
  bool SetDebugName(T handle, std::string_view label) const {
    return SetDebugName(GetDevice(), handle, label);
  }

  template <typename T>
  static bool SetDebugName(const vk::Device& device,
                           T handle,
                           std::string_view label) {
    if (!HasValidationLayers()) {
      // No-op if validation layers are not enabled.
      return true;
    }

    auto c_handle = static_cast<typename T::CType>(handle);

    vk::DebugUtilsObjectNameInfoEXT info;
    info.objectType = T::objectType;
    info.pObjectName = label.data();
    info.objectHandle = reinterpret_cast<decltype(info.objectHandle)>(c_handle);

    if (device.setDebugUtilsObjectNameEXT(info) != vk::Result::eSuccess) {
      VALIDATION_LOG << "Unable to set debug name: " << label;
      return false;
    }

    return true;
  }

  std::shared_ptr<DeviceHolder> GetDeviceHolder() const {
    return device_holder_;
  }

  vk::Instance GetInstance() const;

  const vk::Device& GetDevice() const;

  const std::shared_ptr<fml::ConcurrentTaskRunner>
  GetConcurrentWorkerTaskRunner() const;

  [[nodiscard]] bool SetWindowSurface(vk::UniqueSurfaceKHR surface);

  std::unique_ptr<Surface> AcquireNextSurface();

#ifdef FML_OS_ANDROID
  vk::UniqueSurfaceKHR CreateAndroidSurface(ANativeWindow* window) const;
#endif  // FML_OS_ANDROID

  const std::shared_ptr<QueueVK>& GetGraphicsQueue() const;

  vk::PhysicalDevice GetPhysicalDevice() const;

  std::shared_ptr<FenceWaiterVK> GetFenceWaiter() const;

 private:
  struct DeviceHolderImpl : public DeviceHolder {
    // |DeviceHolder|
    const vk::Device& GetDevice() const override { return device.get(); }
    vk::UniqueInstance instance;
    vk::PhysicalDevice physical_device;
    vk::UniqueDevice device;
  };

  std::shared_ptr<DeviceHolderImpl> device_holder_;
  std::unique_ptr<DebugReportVK> debug_report_;
  std::shared_ptr<Allocator> allocator_;
  std::shared_ptr<ShaderLibraryVK> shader_library_;
  std::shared_ptr<SamplerLibraryVK> sampler_library_;
  std::shared_ptr<PipelineLibraryVK> pipeline_library_;
  QueuesVK queues_;
  std::shared_ptr<SwapchainVK> swapchain_;
  std::shared_ptr<const Capabilities> device_capabilities_;
  std::shared_ptr<FenceWaiterVK> fence_waiter_;
  std::string device_name_;
  std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner_;
  const uint64_t hash_;

  bool is_valid_ = false;

  ContextVK();

  void Setup(Settings settings);

  std::unique_ptr<CommandEncoderVK> CreateGraphicsCommandEncoder() const;

  FML_DISALLOW_COPY_AND_ASSIGN(ContextVK);
};

}  // namespace impeller
