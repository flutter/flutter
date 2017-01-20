// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_vulkan.h"
#include "lib/ftl/logging.h"

namespace shell {

GPUSurfaceVulkan::GPUSurfaceVulkan(
    ftl::RefPtr<vulkan::VulkanProcTable> proc_table,
    std::unique_ptr<vulkan::VulkanNativeSurface> native_surface)
    : window_(std::move(proc_table), std::move(native_surface)),
      weak_factory_(this) {}

GPUSurfaceVulkan::~GPUSurfaceVulkan() = default;

bool GPUSurfaceVulkan::Setup() {
  // This backend does not have an explicit setup task post initialization.
  return window_.IsValid();
}

bool GPUSurfaceVulkan::IsValid() {
  return window_.IsValid();
}

std::unique_ptr<SurfaceFrame> GPUSurfaceVulkan::AcquireFrame(
    const SkISize& size) {
  auto surface = window_.AcquireSurface();

  if (surface == nullptr) {
    return nullptr;
  }

  return std::make_unique<SurfaceFrame>(
      std::move(surface),
      [weak_this = weak_factory_.GetWeakPtr()](SkCanvas * canvas)->bool {
        // Frames are only ever acquired on the GPU thread. This is also the
        // thread on which the weak pointer factory is collected (as this
        // instance is owned by the rasterizer). So this use of weak pointers is
        // safe.
        if (canvas == nullptr || !weak_this) {
          return false;
        }
        return weak_this->window_.SwapBuffers();
      });
}

GrContext* GPUSurfaceVulkan::GetContext() {
  return window_.GetSkiaGrContext();
}

}  // namespace shell
