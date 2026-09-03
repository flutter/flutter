// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/golden_tests/vulkan_golden_screenshotter.h"

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/impeller/testing/vulkan/vulkan_screenshotter.h"
#define GLFW_INCLUDE_NONE
#include "third_party/glfw/include/GLFW/glfw3.h"

namespace impeller {
namespace testing {

VulkanGoldenScreenshotter::VulkanGoldenScreenshotter(
    const std::unique_ptr<PlaygroundImpl>& playground)
    : playground_(playground) {
  FML_CHECK(playground_);
}

VulkanGoldenScreenshotter::~VulkanGoldenScreenshotter() = default;

std::unique_ptr<Screenshot> VulkanGoldenScreenshotter::MakeScreenshot(
    const AiksContext& aiks_context,
    const std::shared_ptr<Texture>& texture) {
  return VulkanScreenshotter::MakeScreenshot(aiks_context.GetContext(),
                                             texture);
}

PlaygroundImpl& VulkanGoldenScreenshotter::GetPlayground() {
  return *playground_;
}

}  // namespace testing
}  // namespace impeller
