// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_VULKAN_SURFACE_PRODUCER_H_
#define FLUTTER_CONTENT_HANDLER_VULKAN_SURFACE_PRODUCER_H_

#include "flutter/content_handler/vulkan_surface.h"
#include "flutter/content_handler/vulkan_surface_pool.h"
#include "flutter/flow/scene_update_context.h"
#include "flutter/vulkan/vulkan_application.h"
#include "flutter/vulkan/vulkan_device.h"
#include "flutter/vulkan/vulkan_proc_table.h"
#include "flutter/vulkan/vulkan_provider.h"
#include "lib/fsl/tasks/message_loop.h"
#include "lib/fxl/macros.h"
#include "lib/ui/scenic/client/resources.h"
#include "lib/ui/scenic/client/session.h"
#include "third_party/skia/include/gpu/vk/GrVkBackendContext.h"

namespace flutter_runner {

class VulkanSurfaceProducer : public flow::SceneUpdateContext::SurfaceProducer,
                              public vulkan::VulkanProvider {
 public:
  VulkanSurfaceProducer(scenic_lib::Session* mozart_session);

  ~VulkanSurfaceProducer();

  bool IsValid() const { return valid_; }

  // |flow::SceneUpdateContext::SurfaceProducer|
  std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
  ProduceSurface(const SkISize& size) override;

  // |flow::SceneUpdateContext::SurfaceProducer|
  void SubmitSurface(
      std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface> surface)
      override;

  void OnSurfacesPresented(
      std::vector<
          std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>>
          surfaces);

 private:
  // VulkanProvider
  const vulkan::VulkanProcTable& vk() override { return *vk_.get(); }
  const vulkan::VulkanHandle<VkDevice>& vk_device() override {
    return logical_device_->GetHandle();
  }

  // Note: the order here is very important. The proctable must be destroyed
  // last because it contains the function pointers for VkDestroyDevice and
  // VkDestroyInstance. The backend context owns the VkDevice and the
  // VkInstance, so it must be destroyed after the logical device and the
  // application, which own other vulkan objects associated with the device
  // and instance.
  fxl::RefPtr<vulkan::VulkanProcTable> vk_;
  sk_sp<GrVkBackendContext> backend_context_;
  std::unique_ptr<vulkan::VulkanDevice> logical_device_;
  std::unique_ptr<vulkan::VulkanApplication> application_;
  sk_sp<GrContext> context_;
  std::unique_ptr<VulkanSurfacePool> surface_pool_;
  bool valid_ = false;

  bool Initialize(scenic_lib::Session* mozart_session);

  FXL_DISALLOW_COPY_AND_ASSIGN(VulkanSurfaceProducer);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_VULKAN_SURFACE_PRODUCER_H_
