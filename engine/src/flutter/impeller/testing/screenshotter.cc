// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/testing/screenshotter.h"

namespace impeller {
namespace testing {

#if !IMPELLER_ENABLE_METAL
std::unique_ptr<Screenshot> Screenshotter::MakeMetalScreenshot(
    std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture) {
  FML_LOG(INFO) << "Screenshot not supported for Metal on this platform";
  return nullptr;
}
#endif

#if !IMPELLER_ENABLE_OPENGLES
std::unique_ptr<Screenshot> Screenshotter::MakeOpenGLScreenshot(
    std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture) {
  FML_LOG(INFO) << "Screenshot not supported for OpenGL on this platform";
  return nullptr;
}
#endif

#if !IMPELLER_ENABLE_VULKAN
std::unique_ptr<Screenshot> Screenshotter::MakeVulkanScreenshot(
    std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture) {
  FML_LOG(INFO) << "Screenshot not supported for Vulkan on this platform";
  return nullptr;
}
#endif

std::unique_ptr<Screenshot> Screenshotter::MakeScreenshot(
    std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture) {
  switch (context->GetBackendType()) {
    case Context::BackendType::kMetal:
      return MakeMetalScreenshot(context, texture);

    case Context::BackendType::kOpenGLES:
      return MakeOpenGLScreenshot(context, texture);

    case Context::BackendType::kVulkan:
      return MakeVulkanScreenshot(context, texture);
  }
}

}  // namespace testing
}  // namespace impeller
