// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/testing/screenshotter.h"

#include "flutter/impeller/testing/metal/metal_screenshotter.h"
#include "flutter/impeller/testing/vulkan/vulkan_screenshotter.h"

namespace impeller {
namespace testing {

std::unique_ptr<Screenshot> Screenshotter::MakeScreenshot(
    std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture) {
  switch (context->GetBackendType()) {
    case Context::BackendType::kMetal:
      return MetalScreenshotter::MakeScreenshot(context, texture);

    case Context::BackendType::kOpenGLES:
    case Context::BackendType::kVulkan:
      return VulkanScreenshotter::MakeScreenshot(context, texture);
  }
}

}  // namespace testing
}  // namespace impeller
