// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <lib/async/cpp/time.h>
#include <lib/async/default.h>
#include <lib/syslog/global.h>

#include "flutter/flow/scene_update_context.h"
#include "flutter/fml/macros.h"
#include "flutter/vulkan/vulkan_application.h"
#include "flutter/vulkan/vulkan_device.h"
#include "flutter/vulkan/vulkan_proc_table.h"
#include "flutter/vulkan/vulkan_provider.h"
#include "lib/ui/scenic/cpp/resources.h"
#include "lib/ui/scenic/cpp/session.h"
#include "logging.h"
#include "vulkan_surface.h"
#include "vulkan_surface_pool.h"

namespace flutter_runner {

class VulkanSurfaceProducer final
    : public flutter::SceneUpdateContext::SurfaceProducer,
      public vulkan::VulkanProvider {
 public:
  VulkanSurfaceProducer(scenic::Session* scenic_session);

  ~VulkanSurfaceProducer();

  bool IsValid() const { return valid_; }

  // |flutter::SceneUpdateContext::SurfaceProducer|
  std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>
  ProduceSurface(const SkISize& size,
                 const flutter::LayerRasterCacheKey& layer_key,
                 std::unique_ptr<scenic::EntityNode> entity_node) override;

  // |flutter::SceneUpdateContext::SurfaceProducer|
  void SubmitSurface(
      std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>
          surface) override;

  // |flutter::SceneUpdateContext::HasRetainedNode|
  bool HasRetainedNode(const flutter::LayerRasterCacheKey& key) const override {
    return surface_pool_->HasRetainedNode(key);
  }

  // |flutter::SceneUpdateContext::GetRetainedNode|
  scenic::EntityNode* GetRetainedNode(
      const flutter::LayerRasterCacheKey& key) override {
    return surface_pool_->GetRetainedNode(key);
  }

  void OnSurfacesPresented(
      std::vector<
          std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>>
          surfaces);

  void OnSessionSizeChangeHint(float width_change_factor,
                               float height_change_factor) {
    FX_LOGF(INFO, LOG_TAG,
            "VulkanSurfaceProducer:OnSessionSizeChangeHint %f, %f",
            width_change_factor, height_change_factor);
  }

  GrContext* gr_context() { return context_.get(); }

 private:
  // VulkanProvider
  const vulkan::VulkanProcTable& vk() override { return *vk_.get(); }
  const vulkan::VulkanHandle<VkDevice>& vk_device() override {
    return logical_device_->GetHandle();
  }

  bool TransitionSurfacesToExternal(
      const std::vector<
          std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>>&
          surfaces);

  // Note: the order here is very important. The proctable must be destroyed
  // last because it contains the function pointers for VkDestroyDevice and
  // VkDestroyInstance.
  fml::RefPtr<vulkan::VulkanProcTable> vk_;
  std::unique_ptr<vulkan::VulkanApplication> application_;
  std::unique_ptr<vulkan::VulkanDevice> logical_device_;
  sk_sp<GrContext> context_;
  std::unique_ptr<VulkanSurfacePool> surface_pool_;
  bool valid_ = false;

  // Keep track of the last time we produced a surface.  This is used to
  // determine whether it is safe to shrink |surface_pool_| or not.
  zx::time last_produce_time_ = async::Now(async_get_default_dispatcher());
  fml::WeakPtrFactory<VulkanSurfaceProducer> weak_factory_{this};

  bool Initialize(scenic::Session* scenic_session);

  // Disallow copy and assignment.
  VulkanSurfaceProducer(const VulkanSurfaceProducer&) = delete;
  VulkanSurfaceProducer& operator=(const VulkanSurfaceProducer&) = delete;
};

}  // namespace flutter_runner
