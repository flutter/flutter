// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface.h"

#include <utility>

#include "flutter/shell/platform/android/android_surface_gl.h"
#include "flutter/shell/platform/android/android_surface_software.h"
#if SHELL_ENABLE_VULKAN
#include "flutter/shell/platform/android/android_surface_vulkan.h"
#endif  // SHELL_ENABLE_VULKAN

namespace shell {

std::unique_ptr<AndroidSurface> AndroidSurface::Create(
    bool use_software_rendering) {
  if (use_software_rendering) {
    auto software_surface = std::make_unique<AndroidSurfaceSoftware>();
    return software_surface->IsValid() ? std::move(software_surface) : nullptr;
  }
#if SHELL_ENABLE_VULKAN
  auto vulkan_surface = std::make_unique<AndroidSurfaceVulkan>();
  return vulkan_surface->IsValid() ? std::move(vulkan_surface) : nullptr;
#else   // SHELL_ENABLE_VULKAN
  auto gl_surface = std::make_unique<AndroidSurfaceGL>();
  return gl_surface->IsOffscreenContextValid() ? std::move(gl_surface)
                                               : nullptr;
#endif  // SHELL_ENABLE_VULKAN
}

AndroidSurface::~AndroidSurface() = default;

}  // namespace shell
