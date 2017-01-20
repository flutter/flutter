// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/rasterizer.h"

#include "flutter/content_handler/software_rasterizer.h"

#if FLUTTER_ENABLE_VULKAN
#include "flutter/content_handler/vulkan_rasterizer.h"
#endif  // FLUTTER_ENABLE_VULKAN

namespace flutter_runner {

Rasterizer::~Rasterizer() = default;

std::unique_ptr<Rasterizer> Rasterizer::Create() {
#if FLUTTER_ENABLE_VULKAN
  auto vulkan_rasterizer = std::make_unique<VulkanRasterizer>();

  if (!vulkan_rasterizer->IsValid()) {
    FTL_DLOG(INFO) << "Could not initialize a valid vulkan rasterizer. "
                      "Attempting to fallback to the software rasterizer.";
    return std::make_unique<SoftwareRasterizer>();
  }

  FTL_DLOG(INFO) << "Successfully initialized a valid vulkan rasterizer.";

  return vulkan_rasterizer;
#else  // FLUTTER_ENABLE_VULKAN
  return std::make_unique<SoftwareRasterizer>();
#endif  // FLUTTER_ENABLE_VULKAN
}

}  // namespace flutter_runner
