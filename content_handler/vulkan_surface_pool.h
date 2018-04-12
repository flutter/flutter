// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <list>
#include <unordered_map>
#include "flutter/content_handler/vulkan_surface.h"
#include "lib/fxl/macros.h"

namespace flutter_runner {

class VulkanSurfacePool {
 public:
  static const size_t kMaxSurfacesOfSameSize = 3;
  static const size_t kMaxSurfaceAge = 3;

  VulkanSurfacePool(vulkan::VulkanProvider& vulkan_provider,
                    sk_sp<GrContext> context,
                    sk_sp<GrVkBackendContext> backend_context,
                    scenic_lib::Session* mozart_session);

  ~VulkanSurfacePool();

  std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
  AcquireSurface(const SkISize& size);

  void SubmitSurface(
      std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
          surface);

  void AgeAndCollectOldBuffers();

 private:
  using SurfacesSet = std::list<
      std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>>;

  template <class T>
  static void HashCombine(size_t& seed, T const& v) {
    seed ^= std::hash<T>()(v) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
  }

  struct SkISizeHash {
    std::size_t operator()(const SkISize& key) const {
      size_t seed = 0;
      HashCombine(seed, key.fWidth);
      HashCombine(seed, key.fHeight);
      return seed;
    }
  };

  vulkan::VulkanProvider& vulkan_provider_;
  sk_sp<GrContext> context_;
  sk_sp<GrVkBackendContext> backend_context_;
  scenic_lib::Session* mozart_session_;
  std::unordered_map<SkISize, SurfacesSet, SkISizeHash> available_surfaces_;
  std::unordered_map<
      uintptr_t,
      std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>>
      pending_surfaces_;
  size_t trace_surfaces_created_ = 0;
  size_t trace_surfaces_reused_ = 0;

  std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
  GetCachedOrCreateSurface(const SkISize& size);

  std::unique_ptr<VulkanSurface> CreateSurface(const SkISize& size);

  void RecycleSurface(uintptr_t surface_key);

  void TraceStats();

  FXL_DISALLOW_COPY_AND_ASSIGN(VulkanSurfacePool);
};

}  // namespace flutter_runner
