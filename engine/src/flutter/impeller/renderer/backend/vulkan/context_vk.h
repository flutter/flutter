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
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/surface.h"

namespace impeller {

bool HasValidationLayers();

class CommandEncoderVK;
class DebugReportVK;
class FenceWaiterVK;

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
  std::shared_ptr<WorkQueue> GetWorkQueue() const override;

  // |Context|
  const std::shared_ptr<const Capabilities>& GetCapabilities() const override;

  template <typename T>
  bool SetDebugName(T handle, std::string_view label) const {
    return SetDebugName(*device_, handle, label);
  }

  template <typename T>
  static bool SetDebugName(vk::Device device,
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

  vk::Instance GetInstance() const;

  vk::Device GetDevice() const;

  [[nodiscard]] bool SetWindowSurface(vk::UniqueSurfaceKHR surface);

  std::unique_ptr<Surface> AcquireNextSurface();

#ifdef FML_OS_ANDROID
  vk::UniqueSurfaceKHR CreateAndroidSurface(ANativeWindow* window) const;
#endif  // FML_OS_ANDROID

  vk::Queue GetGraphicsQueue() const;

  QueueVK GetGraphicsQueueInfo() const;

  vk::PhysicalDevice GetPhysicalDevice() const;

  std::shared_ptr<FenceWaiterVK> GetFenceWaiter() const;

 private:
  std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner_;
  vk::UniqueInstance instance_;
  std::unique_ptr<DebugReportVK> debug_report_;
  vk::PhysicalDevice physical_device_;
  vk::UniqueDevice device_;
  std::shared_ptr<Allocator> allocator_;
  std::shared_ptr<ShaderLibraryVK> shader_library_;
  std::shared_ptr<SamplerLibraryVK> sampler_library_;
  std::shared_ptr<PipelineLibraryVK> pipeline_library_;
  vk::Queue graphics_queue_ = {};
  vk::Queue compute_queue_ = {};
  vk::Queue transfer_queue_ = {};
  QueueVK graphics_queue_info_ = {};
  QueueVK compute_queue_info_ = {};
  QueueVK transfer_queue_info_ = {};
  std::shared_ptr<SwapchainVK> swapchain_;
  std::shared_ptr<WorkQueue> work_queue_;
  std::shared_ptr<const Capabilities> device_capabilities_;
  std::shared_ptr<FenceWaiterVK> fence_waiter_;

  bool is_valid_ = false;

  ContextVK();

  void Setup(
      PFN_vkGetInstanceProcAddr proc_address_callback,
      const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_data,
      const std::shared_ptr<const fml::Mapping>& pipeline_cache_data,
      std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner,
      const std::string& label);

  std::unique_ptr<CommandEncoderVK> CreateGraphicsCommandEncoder() const;

  FML_DISALLOW_COPY_AND_ASSIGN(ContextVK);
};

}  // namespace impeller
