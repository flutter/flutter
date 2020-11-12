// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_vulkan.h"

#include "flutter/fml/logging.h"

namespace flutter {

GPUSurfaceVulkan::GPUSurfaceVulkan(
    GPUSurfaceVulkanDelegate* delegate,
    std::unique_ptr<vulkan::VulkanNativeSurface> native_surface,
    bool render_to_surface)
    : window_(delegate->vk(), std::move(native_surface), render_to_surface),
      render_to_surface_(render_to_surface),
      weak_factory_(this) {}

GPUSurfaceVulkan::~GPUSurfaceVulkan() = default;

bool GPUSurfaceVulkan::IsValid() {
  return window_.IsValid();
}

std::unique_ptr<SurfaceFrame> GPUSurfaceVulkan::AcquireFrame(
    const SkISize& size) {
  // TODO(38466): Refactor GPU surface APIs take into account the fact that an
  // external view embedder may want to render to the root surface.
  if (!render_to_surface_) {
    return std::make_unique<SurfaceFrame>(
        nullptr, true, [](const SurfaceFrame& surface_frame, SkCanvas* canvas) {
          return true;
        });
  }

  auto surface = window_.AcquireSurface();

  if (surface == nullptr) {
    return nullptr;
  }

  SurfaceFrame::SubmitCallback callback =
      [weak_this = weak_factory_.GetWeakPtr()](const SurfaceFrame&,
                                               SkCanvas* canvas) -> bool {
    // Frames are only ever acquired on the raster thread. This is also the
    // thread on which the weak pointer factory is collected (as this instance
    // is owned by the rasterizer). So this use of weak pointers is safe.
    if (canvas == nullptr || !weak_this) {
      return false;
    }
    return weak_this->window_.SwapBuffers();
  };
  return std::make_unique<SurfaceFrame>(std::move(surface), true,
                                        std::move(callback));
}

SkMatrix GPUSurfaceVulkan::GetRootTransformation() const {
  // This backend does not support delegating to the underlying platform to
  // query for root surface transformations. Just return identity.
  SkMatrix matrix;
  matrix.reset();
  return matrix;
}

GrDirectContext* GPUSurfaceVulkan::GetContext() {
  return window_.GetSkiaGrContext();
}

}  // namespace flutter
