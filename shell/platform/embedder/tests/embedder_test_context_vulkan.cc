// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test_context_vulkan.h"

#include <memory>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_compositor_vulkan.h"
#include "flutter/testing/test_vulkan_context.h"
#include "flutter/testing/test_vulkan_surface.h"
#include "flutter/vulkan/vulkan_device.h"
#include "flutter/vulkan/vulkan_proc_table.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

EmbedderTestContextVulkan::EmbedderTestContextVulkan(std::string assets_path)
    : EmbedderTestContext(assets_path), surface_() {
  vulkan_context_ = fml::MakeRefCounted<TestVulkanContext>();
}

EmbedderTestContextVulkan::~EmbedderTestContextVulkan() {}

void EmbedderTestContextVulkan::SetupSurface(SkISize surface_size) {
  FML_CHECK(surface_size_.isEmpty());
  surface_size_ = surface_size;
  surface_ = TestVulkanSurface::Create(*vulkan_context_, surface_size_);
}

size_t EmbedderTestContextVulkan::GetSurfacePresentCount() const {
  return present_count_;
}

VkImage EmbedderTestContextVulkan::GetNextImage(const SkISize& size) {
  return surface_->GetImage();
}

bool EmbedderTestContextVulkan::PresentImage(VkImage image) {
  FireRootSurfacePresentCallbackIfPresent(
      [&]() { return surface_->GetSurfaceSnapshot(); });
  present_count_++;
  return true;
}

EmbedderTestContextType EmbedderTestContextVulkan::GetContextType() const {
  return EmbedderTestContextType::kVulkanContext;
}

void EmbedderTestContextVulkan::SetupCompositor() {
  FML_CHECK(!compositor_) << "Already set up a compositor in this context.";
  FML_CHECK(surface_)
      << "Set up the Vulkan surface before setting up a compositor.";
  compositor_ = std::make_unique<EmbedderTestCompositorVulkan>(
      surface_size_, vulkan_context_->GetGrDirectContext());
}

}  // namespace testing
}  // namespace flutter
