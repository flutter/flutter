// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_CONTEXT_VULKAN_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_CONTEXT_VULKAN_H_

#include <memory>
#include "flutter/shell/platform/embedder/tests/embedder_test_context.h"
#include "flutter/testing/test_vulkan_context.h"
#include "flutter/vulkan/vulkan_application.h"
#include "testing/test_vulkan_surface.h"

namespace flutter {
namespace testing {

class EmbedderTestContextVulkan : public EmbedderTestContext {
 public:
  explicit EmbedderTestContextVulkan(std::string assets_path = "");

  ~EmbedderTestContextVulkan() override;

  // |EmbedderTestContext|
  EmbedderTestContextType GetContextType() const override;

  // |EmbedderTestContext|
  size_t GetSurfacePresentCount() const override;

  // |EmbedderTestContext|
  void SetupCompositor() override;

  VkImage GetNextImage(const SkISize& size);

  bool PresentImage(VkImage image);

  static void* InstanceProcAddr(void* user_data,
                                FlutterVulkanInstanceHandle instance,
                                const char* name);

 private:
  std::unique_ptr<TestVulkanSurface> surface_;

  SkISize surface_size_ = SkISize::MakeEmpty();
  size_t present_count_ = 0;

  void SetupSurface(SkISize surface_size) override;

  friend class EmbedderConfigBuilder;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestContextVulkan);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_CONTEXT_VULKAN_H_
