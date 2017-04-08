// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_
#define FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_

#include <memory>

#include "apps/mozart/services/buffers/cpp/buffer_producer.h"
#include "flutter/content_handler/rasterizer.h"
#include "flutter/flow/compositor_context.h"
#include "flutter/vulkan/vulkan_application.h"
#include "flutter/vulkan/vulkan_device.h"
#include "lib/ftl/macros.h"
#include "third_party/skia/include/gpu/vk/GrVkBackendContext.h"

namespace flutter_runner {

class VulkanRasterizer : public Rasterizer {
 public:
  VulkanRasterizer();

  ~VulkanRasterizer() override;

  bool IsValid() const;

  void SetScene(fidl::InterfaceHandle<mozart::Scene> scene) override;

  void Draw(std::unique_ptr<flow::LayerTree> layer_tree,
            ftl::Closure callback) override;

 private:
  class VulkanSurfaceProducer
      : public flow::SceneUpdateContext::SurfaceProducer {
   public:
    VulkanSurfaceProducer();
    sk_sp<SkSurface> ProduceSurface(SkISize size,
                                    mozart::ImagePtr* out_image) override;
    bool Tick();
    bool IsValid() const { return valid_; }

   private:
    struct Surface {
      sk_sp<SkSurface> sk_surface;
      mx::vmo vmo;
      mx::eventpair local_retention_event;
      mx::eventpair remote_retention_event;
      mx::eventpair fence_event;
      VkImage vk_image;
      VkDeviceMemory vk_memory;

      Surface(sk_sp<SkSurface> sk_surface,
              mx::vmo vmo,
              mx::eventpair local_retention_event,
              mx::eventpair remote_retention_event,
              mx::eventpair fence_event,
              VkImage vk_image,
              VkDeviceMemory vk_memory)
          : sk_surface(std::move(sk_surface)),
            vmo(std::move(vmo)),
            local_retention_event(std::move(local_retention_event)),
            remote_retention_event(std::move(remote_retention_event)),
            fence_event(std::move(fence_event)),
            vk_image(vk_image),
            vk_memory(vk_memory) {}
    };
    std::vector<Surface> surfaces_;

    sk_sp<GrContext> context_;
    sk_sp<GrVkBackendContext> backend_context_;
    std::unique_ptr<vulkan::VulkanApplication> application_;
    std::unique_ptr<vulkan::VulkanDevice> logical_device_;
    bool valid_;

    bool Initialize();
  };

  flow::CompositorContext compositor_context_;
  mozart::ScenePtr scene_;
  bool valid_;
  std::unique_ptr<VulkanSurfaceProducer> surface_producer_;

  bool CreateOrRecreateSurfaces(uint32_t width, uint32_t height);
  bool Draw(std::unique_ptr<flow::LayerTree> layer_tree);

  FTL_DISALLOW_COPY_AND_ASSIGN(VulkanRasterizer);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_
