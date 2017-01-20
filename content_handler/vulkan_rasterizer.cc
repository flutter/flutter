// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/vulkan_rasterizer.h"

#include <utility>

#include "flutter/vulkan/vulkan_native_surface_magma.h"

namespace flutter_runner {

VulkanRasterizer::VulkanRasterizer() : compositor_context_(nullptr) {
  auto proc_table = ftl::MakeRefCounted<vulkan::VulkanProcTable>();

  if (!proc_table->HasAcquiredMandatoryProcAddresses()) {
    return;
  }

  auto native_surface = std::make_unique<vulkan::VulkanNativeSurfaceMagma>();

  if (!native_surface->IsValid()) {
    return;
  }

  auto window = std::make_unique<vulkan::VulkanWindow>(
      proc_table, std::move(native_surface));

  if (!window->IsValid()) {
    return;
  }

  window_ = std::move(window);
}

VulkanRasterizer::~VulkanRasterizer() = default;

bool VulkanRasterizer::IsValid() const {
  return window_ == nullptr ? false : window_->IsValid();
}

void VulkanRasterizer::SetScene(fidl::InterfaceHandle<mozart::Scene> scene) {
  // TODO: Composition is currently unsupported using the Vulkan backend.
}

void VulkanRasterizer::Draw(std::unique_ptr<flow::LayerTree> layer_tree,
                            ftl::Closure callback) {
  Draw(std::move(layer_tree));
  callback();
}

bool VulkanRasterizer::Draw(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (layer_tree == nullptr) {
    FTL_DLOG(INFO) << "Layer tree was not valid.";
    return false;
  }

  if (!window_->IsValid()) {
    FTL_DLOG(INFO) << "Vulkan window was not valid.";
    return false;
  }

  auto surface = window_->AcquireSurface();

  if (!surface && surface->getCanvas() != nullptr) {
    FTL_DLOG(INFO) << "Could not acquire a vulkan surface.";
    return false;
  }

  {
    auto compositor_frame = compositor_context_.AcquireFrame(
        window_->GetSkiaGrContext(),  // GrContext*
        surface->getCanvas(),         // SkCanvas
        true                          // instrumentation
        );

    layer_tree->Raster(compositor_frame);
  }

  if (!window_->SwapBuffers()) {
    FTL_DLOG(INFO) << "Could not swap buffers successfully.";
    return false;
  }

  return true;
}

}  // namespace flutter_runner
