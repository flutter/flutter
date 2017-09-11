// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include "lib/ui/scenic/client/resources.h"
#include "flutter/flow/scene_update_context.h"
#include "flutter/vulkan/vulkan_handle.h"
#include "flutter/vulkan/vulkan_proc_table.h"
#include "lib/fxl/macros.h"
#include "lib/mtl/tasks/message_loop.h"
#include "lib/mtl/tasks/message_loop_handler.h"
#include "mx/event.h"
#include "mx/vmo.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/vk/GrVkBackendContext.h"

namespace flutter_runner {

class VulkanSurface : public flow::SceneUpdateContext::SurfaceProducerSurface,
                      public mtl::MessageLoopHandler {
 public:
  VulkanSurface(vulkan::VulkanProcTable& p_vk,
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

  // This transfers ownership of the GrBackendSemaphore but not the underlying
  // VkSemaphore (i.e. it is ok to let the returned GrBackendSemaphore go out of
  // scope but it is not ok to call VkDestroySemaphore on the underlying
  // VkSemaphore)
  GrBackendSemaphore GetAcquireSemaphore() const;

private:
  vulkan::VulkanProcTable& vk_;
  sk_sp<GrVkBackendContext> backend_context_;
  scenic_lib::Session* session_;
  vulkan::VulkanHandle<VkImage> vk_image_;
  vulkan::VulkanHandle<VkDeviceMemory> vk_memory_;
  sk_sp<SkSurface> sk_surface_;
  std::unique_ptr<scenic_lib::Image> session_image_;
  mx::event acquire_event_;
  vulkan::VulkanHandle<VkSemaphore> acquire_semaphore_;
  mx::event release_event_;
  mtl::MessageLoop::HandlerKey event_handler_key_ = 0;
  std::function<void(void)> pending_on_writes_committed_;
  size_t age_ = 0;
  bool valid_ = false;

  // |mtl::MessageLoopHandler|
  void OnHandleReady(mx_handle_t handle,
                     mx_signals_t pending,
                     uint64_t count) override;

  bool AllocateDeviceMemory(sk_sp<GrContext> context,
                            const SkISize& size,
                            mx::vmo& exported_vmo);

  bool SetupSkiaSurface(sk_sp<GrContext> context,
                        const SkISize& size,
                        const VkImageCreateInfo& image_create_info,
                        const VkMemoryRequirements& memory_reqs);

  bool CreateFences();

  bool PushSessionImageSetupOps(scenic_lib::Session* session,
                                mx::vmo exported_vmo);

  void Reset();

  vulkan::VulkanHandle<VkSemaphore>
  SemaphoreFromEvent(const mx::event &event) const;

  FXL_DISALLOW_COPY_AND_ASSIGN(VulkanSurface);
};

}  // namespace flutter_runner
