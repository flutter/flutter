// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <unordered_map>
#include <vector>

#include "flutter/fml/macros.h"
#include "vulkan_surface.h"

namespace flutter_runner {

class VulkanSurfacePool final {
 public:
  // Only keep 12 surfaces at a time.  This value was based on how many
  // surfaces got cached in the old, exact-match-only caching logic.
  static constexpr int kMaxSurfaces = 12;
  // If a surface doesn't get used for 3 or more generations, we discard it.
  static constexpr int kMaxSurfaceAge = 3;

  VulkanSurfacePool(vulkan::VulkanProvider& vulkan_provider,
                    sk_sp<GrDirectContext> context,
                    scenic::Session* scenic_session);

  ~VulkanSurfacePool();

  std::unique_ptr<VulkanSurface> AcquireSurface(const SkISize& size);

  void SubmitSurface(
      std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>
          surface);

  void AgeAndCollectOldBuffers();

  // Shrink all oversized |VulkanSurfaces| in |available_surfaces_| to as
  // small as they can be.
  void ShrinkToFit();

  // For |VulkanSurfaceProducer::HasRetainedNode|.
  bool HasRetainedNode(const flutter::LayerRasterCacheKey& key) const {
    return retained_surfaces_.find(key) != retained_surfaces_.end();
  }
  // For |VulkanSurfaceProducer::GetRetainedNode|.
  scenic::EntityNode* GetRetainedNode(const flutter::LayerRasterCacheKey& key) {
    FML_DCHECK(HasRetainedNode(key));
    return retained_surfaces_[key].vk_surface->GetRetainedNode();
  }

 private:
  // Struct for retained_surfaces_ map.
  struct RetainedSurface {
    // If |is_pending| is true, the |vk_surface| is still under painting
    // (similar to those in |pending_surfaces_|) so we can't recycle the
    // |vk_surface| yet.
    bool is_pending;
    std::unique_ptr<VulkanSurface> vk_surface;
  };

  vulkan::VulkanProvider& vulkan_provider_;
  sk_sp<GrDirectContext> context_;
  scenic::Session* scenic_session_;
  std::vector<std::unique_ptr<VulkanSurface>> available_surfaces_;
  std::unordered_map<uintptr_t, std::unique_ptr<VulkanSurface>>
      pending_surfaces_;

  // Retained surfaces keyed by the layer that created and used the surface.
  flutter::LayerRasterCacheKey::Map<RetainedSurface> retained_surfaces_;

  size_t trace_surfaces_created_ = 0;
  size_t trace_surfaces_reused_ = 0;

  std::unique_ptr<VulkanSurface> GetCachedOrCreateSurface(const SkISize& size);

  std::unique_ptr<VulkanSurface> CreateSurface(const SkISize& size);

  void RecycleSurface(std::unique_ptr<VulkanSurface> surface);

  void RecyclePendingSurface(uintptr_t surface_key);

  // Clear the |is_pending| flag of the retained surface.
  void SignalRetainedReady(flutter::LayerRasterCacheKey key);

  // Remove the corresponding surface from |retained_surfaces| and recycle it.
  // The surface must not be pending.
  void RecycleRetainedSurface(const flutter::LayerRasterCacheKey& key);

  void TraceStats();

  FML_DISALLOW_COPY_AND_ASSIGN(VulkanSurfacePool);
};

}  // namespace flutter_runner
