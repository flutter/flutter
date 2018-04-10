// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/rasterizer.h"
#include "flutter/content_handler/vulkan_rasterizer.h"

namespace flutter_runner {

Rasterizer::~Rasterizer() = default;

std::unique_ptr<Rasterizer> Rasterizer::Create() {
  auto vulkan_rasterizer = std::make_unique<VulkanRasterizer>();
  FXL_CHECK(vulkan_rasterizer)
      << "The vulkan rasterizer must be correctly initialized.";
  return vulkan_rasterizer;
}

}  // namespace flutter_runner
