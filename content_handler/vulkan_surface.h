// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <lib/async/cpp/wait.h>
#include <zx/event.h>
#include <zx/vmo.h>

#include <memory>

#include "flutter/flow/scene_update_context.h"
#include "flutter/vulkan/vulkan_command_buffer.h"
#include "flutter/vulkan/vulkan_handle.h"
#include "flutter/vulkan/vulkan_proc_table.h"
#include "flutter/vulkan/vulkan_provider.h"
#include "lib/fxl/macros.h"
#include "lib/ui/scenic/client/resources.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/vk/GrVkBackendContext.h"

namespace flutter_runner {

class VulkanSurface : public flow::SceneUpdateContext::SurfaceProducerSurface {
 public:
  VulkanSurface(vulkan::VulkanProvider& vulkan_provider,
                sk_sp<GrContext> context,
                sk_sp<GrVkBackendContext> backend_context,
                scenic_lib::Session* session,
                const SkISize& size);

  ~VulkanSurface() override;

  size_t AdvanceAndGetAge() override;

  bool FlushSessionAcquireAndReleaseEvents() override;

  bool IsValid() const override;

  SkISize GetSize() const override;

  // Note: It is safe for the caller to collect the surface in the
  // |on_writes_committed| callback.
  void SignalWritesFinished(
      std::function<void(void)> on_writes_committed) override;

  // |flow::SceneUpdateContext::SurfaceProducerSurface|
  scenic_lib::Image* GetImage() override;

  // |flow::SceneUpdateContext::SurfaceProducerSurface|
  sk_sp<SkSurface> GetSkiaSurface() const override;

  const vulkan::VulkanHandle<VkImage>& GetVkImage() { return vk_image_; }

  const vulkan::VulkanHandle<VkSemaphore>& GetAcquireVkSemaphore() {
    return acquire_semaphore_;
  }

  vulkan::VulkanCommandBuffer* GetCommandBuffer(
      const vulkan::VulkanHandle<VkCommandPool>& pool) {
    if (!command_buffer_)
      command_buffer_ = std::make_unique<vulkan::VulkanCommandBuffer>(
          vulkan_provider_.vk(), vulkan_provider_.vk_device(), pool);
    return command_buffer_.get();
  }

  const vulkan::VulkanHandle<VkFence>& GetCommandBufferFence() {
    return command_buffer_fence_;
  }

 private:
  async_wait_result_t OnHandleReady(async_t* async,
                                    zx_status_t status,
                                    const zx_packet_signal_t* signal);

  bool AllocateDeviceMemory(sk_sp<GrContext> context,
                            const SkISize& size,
                            zx::vmo& exported_vmo);

  bool SetupSkiaSurface(sk_sp<GrContext> context,
                        const SkISize& size,
                        SkColorType color_type,
                        const VkImageCreateInfo& image_create_info,
                        const VkMemoryRequirements& memory_reqs);

  bool CreateFences();

  bool PushSessionImageSetupOps(scenic_lib::Session* session,
                                zx::vmo exported_vmo);

  void Reset();

  vulkan::VulkanHandle<VkSemaphore> SemaphoreFromEvent(
      const zx::event& event) const;

  vulkan::VulkanProvider& vulkan_provider_;
  sk_sp<GrVkBackendContext> backend_context_;
  scenic_lib::Session* session_;
  vulkan::VulkanHandle<VkImage> vk_image_;
  vulkan::VulkanHandle<VkDeviceMemory> vk_memory_;
  vulkan::VulkanHandle<VkFence> command_buffer_fence_;
  sk_sp<SkSurface> sk_surface_;
  std::unique_ptr<scenic_lib::Image> session_image_;
  zx::event acquire_event_;
  vulkan::VulkanHandle<VkSemaphore> acquire_semaphore_;
  std::unique_ptr<vulkan::VulkanCommandBuffer> command_buffer_;
  zx::event release_event_;
  async_t* async_;
  async::WaitMethod<VulkanSurface, &VulkanSurface::OnHandleReady> wait_;
  std::function<void()> pending_on_writes_committed_;
  size_t age_ = 0;
  bool valid_ = false;

  FXL_DISALLOW_COPY_AND_ASSIGN(VulkanSurface);
};

}  // namespace flutter_runner
