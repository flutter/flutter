// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_VULKAN_IMPELLER_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_VULKAN_IMPELLER_H_

#include <array>
#include <cstdint>
#include <unordered_map>

#include "flutter/common/graphics/gl_context_switch.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/impeller/renderer/context.h"
#include "flutter/shell/gpu/gpu_surface_vulkan_delegate.h"
#include "impeller/renderer/backend/vulkan/swapchain/swapchain_transients_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace flutter {

namespace testing {
FML_TEST_CLASS(GPUSurfaceVulkanImpeller,
               RecreatesTransientsWhenFrameSizeChanges);
}  // namespace testing

class GPUSurfaceVulkanImpeller final : public Surface {
 public:
  GPUSurfaceVulkanImpeller(GPUSurfaceVulkanDelegate* delegate,
                           std::shared_ptr<impeller::Context> context,
                           bool render_to_surface);

  // |Surface|
  ~GPUSurfaceVulkanImpeller() override;

  // |Surface|
  bool IsValid() override;

 private:
  FML_FRIEND_TEST(testing::GPUSurfaceVulkanImpeller,
                  RecreatesTransientsWhenFrameSizeChanges);

  /// Maximum number of frames that can be in-flight simultaneously.
  /// Matches the KHR swapchain's kMaxFramesInFlight = 2.
  static constexpr size_t kMaxFramesInFlight = 2u;

  /// Maximum time (nanoseconds) to wait for a frame fence before skipping
  /// the frame. 100ms provides generous headroom for normal rendering
  /// (including high-DPI, heavy shader workloads, and debug builds) while
  /// still dropping frames under extreme GPU pressure to prevent resource
  /// exhaustion. The primary backpressure mechanism is the 2-fence ring
  /// itself; this timeout is a secondary safety net.
  static constexpr uint64_t kFrameSkipTimeoutNs = 100'000'000u;

  /// Maximum time (nanoseconds) to wait for in-flight frames when draining
  /// fences on resize or teardown. Fences are only unsignaled while a
  /// submitted frame is executing, so this bound is never reached in normal
  /// operation; it protects against waiting forever on a wedged driver.
  static constexpr uint64_t kFenceDrainTimeoutNs = 5'000'000'000u;  // 5 s.

  GPUSurfaceVulkanDelegate* delegate_;
  std::shared_ptr<impeller::Context> impeller_context_;
  std::shared_ptr<impeller::AiksContext> aiks_context_;
  std::shared_ptr<impeller::SwapchainTransientsVK> transients_;
  /// The size of the textures in [transients_]
  impeller::ISize transients_size_ = {};

  // Cached image views keyed by VkImage handle. Image views are created once
  // per embedder-provided image and reused across frames to avoid per-frame
  // allocation (which leaks one VkImageView per frame). Cleared when the
  // embedder's images are recreated (frame size change), since the old
  // VkImages become invalid.
  std::unordered_map<uint64_t, impeller::vk::UniqueImageView>
      cached_image_views_;

  // Frame throttling fences.
  //
  // Without throttling, the CPU can queue frames much faster than the GPU
  // processes them (especially in debug builds). Each queued frame creates
  // fences and holds tracked resources (textures, buffers, command pools).
  // Under heavy workloads this causes unbounded resource accumulation and
  // eventually VK_ERROR_OUT_OF_HOST_MEMORY.
  //
  // The KHR swapchain enforces back-pressure via WaitForFence() at the start
  // of each AcquireNextDrawable. This replicates that for the
  // embedder-managed image path with a ring of fences.
  std::array<impeller::vk::UniqueFence, kMaxFramesInFlight> frame_fences_;
  size_t current_fence_index_ = 0;

  // False when an external view embedder handles rendering: the frame is
  // then a no-op and content reaches the screen through embedder-provided
  // backing stores, matching GPUSurfaceGLImpeller.
  bool render_to_surface_ = true;

  bool is_valid_ = false;

  // |Surface|
  std::unique_ptr<SurfaceFrame> AcquireFrame(const DlISize& size) override;

  // |Surface|
  DlMatrix GetRootTransformation() const override;

  // |Surface|
  GrDirectContext* GetContext() override;

  // |Surface|
  std::unique_ptr<GLContextResult> MakeRenderContextCurrent() override;

  // |Surface|
  bool EnableRasterCache() const override;

  // |Surface|
  std::shared_ptr<impeller::AiksContext> GetAiksContext() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(GPUSurfaceVulkanImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_VULKAN_IMPELLER_H_
