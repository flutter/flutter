// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vulkan/vulkan.h>

#include "flutter/shell/gpu/gpu_surface_vulkan_delegate.h"
#include "flutter/shell/gpu/gpu_surface_vulkan_impeller.h"
#include "flutter/testing/test_vulkan_context.h"
#include "flutter/testing/test_vulkan_surface.h"
#include "gtest/gtest.h"
#include "impeller/entity/vk/entity_shaders_vk.h"
#include "impeller/entity/vk/framebuffer_blend_shaders_vk.h"
#include "impeller/entity/vk/modern_shaders_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"

namespace flutter {
namespace testing {

std::vector<std::shared_ptr<fml::Mapping>> ShaderLibraryMappings() {
  return {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_vk_data,
                                             impeller_entity_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_modern_shaders_vk_data,
                                             impeller_modern_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_framebuffer_blend_shaders_vk_data,
          impeller_framebuffer_blend_shaders_vk_length),
  };
}

class TestGPUSurfaceVulkanDelegate : public GPUSurfaceVulkanDelegate {
 public:
  TestGPUSurfaceVulkanDelegate()
      : vk_(fml::MakeRefCounted<vulkan::VulkanProcTable>(
            vkGetInstanceProcAddr)),
        test_context_(fml::MakeRefCounted<TestVulkanContext>()) {}

  const vulkan::VulkanProcTable& vk() override { return *vk_; }

  FlutterVulkanImage AcquireImage(const DlISize& size) override {
    ++acquire_count_;
    if (!test_surface_ || surface_size_ != size) {
      test_surface_ = TestVulkanSurface::Create(*test_context_, size);
      surface_size_ = size;
    }

    return {
        .struct_size = sizeof(FlutterVulkanImage),
        .image = test_surface_
                     ? reinterpret_cast<uint64_t>(test_surface_->GetImage())
                     : 0u,
        .format = VK_FORMAT_R8G8B8A8_UNORM,
    };
  }

  bool PresentImage(VkImage image, VkFormat format) override {
    ++present_count_;
    return true;
  }

  int acquire_count() const { return acquire_count_; }
  int present_count() const { return present_count_; }

 private:
  int acquire_count_ = 0;
  int present_count_ = 0;
  fml::RefPtr<vulkan::VulkanProcTable> vk_;
  fml::RefPtr<TestVulkanContext> test_context_;
  std::unique_ptr<TestVulkanSurface> test_surface_;
  DlISize surface_size_ = {};
};

TEST(GPUSurfaceVulkanImpeller, DisposesThreadLocalResources) {
  impeller::ContextVK::Settings context_settings;
  context_settings.proc_address_callback = vkGetInstanceProcAddr;
  context_settings.shader_libraries_data = ShaderLibraryMappings();
  auto context = impeller::ContextVK::Create(std::move(context_settings));

  TestGPUSurfaceVulkanDelegate delegate;

  std::unique_ptr<Surface> surface =
      std::make_unique<GPUSurfaceVulkanImpeller>(&delegate, context);

  // Add a command pool to the global map.
  auto pool = context->GetCommandPoolRecycler()->Get();
  EXPECT_EQ(impeller::CommandPoolRecyclerVK::GetGlobalPoolCount(*context), 1);

  // Check that AcquireFrame disposes thread local resources and removes
  // the pool from the global map.
  auto frame = surface->AcquireFrame(DlISize(100, 100));
  EXPECT_EQ(impeller::CommandPoolRecyclerVK::GetGlobalPoolCount(*context), 0);
}

/// An external view embedder presents the frame's layers itself, so the root
/// surface must neither acquire an image nor present one. It used to do both:
/// the engine presented an unrendered root image after every composited frame,
/// which on an embedder that recycles scanout buffers overwrote the frame just
/// shown -- one good frame, then black.
TEST(GPUSurfaceVulkanImpeller, DoesNotPresentWhenNotRenderingToSurface) {
  impeller::ContextVK::Settings context_settings;
  context_settings.proc_address_callback = vkGetInstanceProcAddr;
  context_settings.shader_libraries_data = ShaderLibraryMappings();
  auto context = impeller::ContextVK::Create(std::move(context_settings));

  TestGPUSurfaceVulkanDelegate delegate;
  std::unique_ptr<Surface> surface = std::make_unique<GPUSurfaceVulkanImpeller>(
      &delegate, context, /*render_to_surface=*/false);

  // Held before the frame, so the dispose below is observable.
  auto pool = context->GetCommandPoolRecycler()->Get();
  EXPECT_EQ(impeller::CommandPoolRecyclerVK::GetGlobalPoolCount(*context), 1);

  auto frame = surface->AcquireFrame(DlISize(100, 100));
  ASSERT_NE(frame, nullptr);
  EXPECT_TRUE(frame->Submit());

  EXPECT_EQ(delegate.acquire_count(), 0)
      << "acquired an embedder image while the compositor owns presentation";
  EXPECT_EQ(delegate.present_count(), 0)
      << "presented the root surface over the compositor's layers";
  // Not presenting is not a reason to stop the per-frame upkeep: the raster
  // thread would otherwise hold these pools for the life of the engine.
  EXPECT_EQ(impeller::CommandPoolRecyclerVK::GetGlobalPoolCount(*context), 0)
      << "thread-local pools survived a frame the compositor presented";
}

/// The default still renders to the surface, which is what a compositor-less
/// embedder relies on.
TEST(GPUSurfaceVulkanImpeller, PresentsWhenRenderingToSurface) {
  impeller::ContextVK::Settings context_settings;
  context_settings.proc_address_callback = vkGetInstanceProcAddr;
  context_settings.shader_libraries_data = ShaderLibraryMappings();
  auto context = impeller::ContextVK::Create(std::move(context_settings));

  TestGPUSurfaceVulkanDelegate delegate;
  std::unique_ptr<Surface> surface =
      std::make_unique<GPUSurfaceVulkanImpeller>(&delegate, context);

  auto frame = surface->AcquireFrame(DlISize(100, 100));
  ASSERT_NE(frame, nullptr);
  EXPECT_GT(delegate.acquire_count(), 0);
}

TEST(GPUSurfaceVulkanImpeller, RecreatesTransientsWhenFrameSizeChanges) {
  impeller::ContextVK::Settings context_settings;
  context_settings.proc_address_callback = vkGetInstanceProcAddr;
  context_settings.shader_libraries_data = ShaderLibraryMappings();
  auto context = impeller::ContextVK::Create(std::move(context_settings));

  TestGPUSurfaceVulkanDelegate delegate;

  auto surface = std::make_unique<GPUSurfaceVulkanImpeller>(&delegate, context);

  auto frame = surface->AcquireFrame(DlISize(100, 100));
  ASSERT_NE(frame, nullptr);
  auto transients = surface->transients_;
  ASSERT_NE(transients, nullptr);
  EXPECT_EQ(surface->transients_size_, impeller::ISize(100, 100));

  frame = surface->AcquireFrame(DlISize(100, 100));
  ASSERT_NE(frame, nullptr);
  EXPECT_EQ(surface->transients_, transients);
  EXPECT_EQ(surface->transients_size_, impeller::ISize(100, 100));

  frame = surface->AcquireFrame(DlISize(200, 100));
  ASSERT_NE(frame, nullptr);
  EXPECT_NE(surface->transients_, transients);
  EXPECT_EQ(surface->transients_size_, impeller::ISize(200, 100));
}

}  // namespace testing
}  // namespace flutter
