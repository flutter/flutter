// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_
#define FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_

#include <memory>
#include <queue>
#include <unordered_map>
#include <vector>

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
      : public flow::SceneUpdateContext::SurfaceProducer,
        private mtl::MessageLoopHandler {
   public:
    VulkanSurfaceProducer();
    sk_sp<SkSurface> ProduceSurface(SkISize size,
                                    mozart::ImagePtr* out_image) override;

    void Tick();
    bool FinishFrame();
    bool IsValid() const { return valid_; }

   private:
    // |mtl::MessageLoopHandler|
    void OnHandleReady(mx_handle_t handle, mx_signals_t pending) override;

    struct Surface {
      sk_sp<GrVkBackendContext> backend_context;
      sk_sp<SkSurface> sk_surface;
      mx::vmo vmo;
      mx::eventpair local_retention_event;
      mx::eventpair remote_retention_event;
      VkImage vk_image;
      VkDeviceMemory vk_memory;

      Surface(sk_sp<GrVkBackendContext> backend_context,
              sk_sp<SkSurface> sk_surface,
              mx::vmo vmo,
              mx::eventpair local_retention_event,
              mx::eventpair remote_retention_event,
              VkImage vk_image,
              VkDeviceMemory vk_memory)
          : backend_context(std::move(backend_context)),
            sk_surface(std::move(sk_surface)),
            vmo(std::move(vmo)),
            local_retention_event(std::move(local_retention_event)),
            remote_retention_event(std::move(remote_retention_event)),
            vk_image(vk_image),
            vk_memory(vk_memory) {}

      ~Surface() {
        FTL_DCHECK(backend_context);
        vkFreeMemory(backend_context->fDevice, vk_memory, NULL);
        vkDestroyImage(backend_context->fDevice, vk_image, NULL);
      }
    };

    std::unique_ptr<Surface> CreateSurface(uint32_t width, uint32_t height);

    struct Swapchain {
      std::queue<std::unique_ptr<Surface>> queue;
      uint32_t tick_count = 0;
      static constexpr uint32_t kMaxSurfaces = 3;
      static constexpr uint32_t kMaxTickBeforeDiscard = 3;
    };

    using size_key_t = uint64_t;
    static size_key_t MakeSizeKey(uint32_t width, uint32_t height) {
      return (static_cast<uint64_t>(width) << 32) |
             static_cast<uint64_t>(height);
    }

    // These three containers hold surfaces in various stages of recycling

    // Buffers exist in available_surfaces_ when they are ready to be recycled
    // ProduceSurface will look here for an appropriately sized surface before
    // creating a new one
    // The Swapchain's tick_count is incremented in Tick and decremented when
    // a surface is taken from the queue, when the tick count goes above
    // kMaxTickBeforeDiscard the Swapchain is discarded. Newly surfaces are
    // added to the queue iff there aar less than kMaxSurfaces already in the
    // queue
    std::unordered_map<size_key_t, Swapchain> available_surfaces_;

    struct PendingSurfaceInfo {
      mtl::MessageLoop::HandlerKey handler_key;
      std::unique_ptr<Surface> surface;
      mx::eventpair production_fence;
    };
    // Surfaces produced by ProduceSurface live in outstanding_surfaces_ until
    // FinishFrame is called, at which point they are moved to pending_surfaces_
    std::vector<PendingSurfaceInfo> outstanding_surfaces_;
    // Surfaces exist in pendind surfaces until they are released by the buffer
    // consumer
    std::unordered_map<mx_handle_t, PendingSurfaceInfo> pending_surfaces_;

    sk_sp<GrContext> context_;
    sk_sp<GrVkBackendContext> backend_context_;
    std::unique_ptr<vulkan::VulkanApplication> application_;
    std::unique_ptr<vulkan::VulkanDevice> logical_device_;
    bool valid_;

    bool Initialize();
  };

  flow::CompositorContext compositor_context_;
  mozart::ScenePtr scene_;
  std::unique_ptr<VulkanSurfaceProducer> surface_producer_;

  bool Draw(std::unique_ptr<flow::LayerTree> layer_tree);

  FTL_DISALLOW_COPY_AND_ASSIGN(VulkanRasterizer);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_VULKAN_RASTERIZER_H_
