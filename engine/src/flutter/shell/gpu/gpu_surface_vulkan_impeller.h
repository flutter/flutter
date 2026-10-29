// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_VULKAN_IMPELLER_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_VULKAN_IMPELLER_H_

#include "flutter/common/graphics/gl_context_switch.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/impeller/renderer/context.h"
#include "flutter/shell/gpu/gpu_surface_vulkan_delegate.h"
#include "impeller/renderer/backend/vulkan/swapchain/swapchain_transients_vk.h"

namespace flutter {

namespace testing {
FML_TEST_CLASS(GPUSurfaceVulkanImpeller,
               RecreatesTransientsWhenFrameSizeChanges);
}  // namespace testing

class GPUSurfaceVulkanImpeller final : public Surface {
 public:
  /// @param  render_to_surface  False when an external view embedder owns
  ///                            presentation, in which case this surface must
  ///                            neither acquire nor present an image: the
  ///                            compositor presents the layers instead, and a
  ///                            root-surface present would overwrite them.
  explicit GPUSurfaceVulkanImpeller(GPUSurfaceVulkanDelegate* delegate,
                                    std::shared_ptr<impeller::Context> context,
                                    bool render_to_surface = true);

  // |Surface|
  ~GPUSurfaceVulkanImpeller() override;

  // |Surface|
  bool IsValid() override;

 private:
  FML_FRIEND_TEST(testing::GPUSurfaceVulkanImpeller,
                  RecreatesTransientsWhenFrameSizeChanges);

  GPUSurfaceVulkanDelegate* delegate_;
  bool render_to_surface_ = true;
  std::shared_ptr<impeller::Context> impeller_context_;
  std::shared_ptr<impeller::AiksContext> aiks_context_;
  std::shared_ptr<impeller::SwapchainTransientsVK> transients_;
  /// The size of the textures in [transients_]
  impeller::ISize transients_size_ = {};
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
