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

namespace flutter {

std::unique_ptr<AndroidSurface> AndroidSurface::Create(
    std::shared_ptr<AndroidContext> android_context,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade) {
  std::unique_ptr<AndroidSurface> surface;
  switch (android_context->RenderingApi()) {
    case AndroidRenderingAPI::kSoftware:
      surface = std::make_unique<AndroidSurfaceSoftware>(jni_facade);
      break;
    case AndroidRenderingAPI::kOpenGLES:
      surface = std::make_unique<AndroidSurfaceGL>(android_context, jni_facade);
      break;
    case AndroidRenderingAPI::kVulkan:
#if SHELL_ENABLE_VULKAN
      surface = std::make_unique<AndroidSurfaceVulkan>(jni_facade);
#endif  // SHELL_ENABLE_VULKAN
      break;
  }
  FML_CHECK(surface);
  return surface->IsValid() ? std::move(surface) : nullptr;
  ;
}

AndroidSurface::~AndroidSurface() = default;

}  // namespace flutter
