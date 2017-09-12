// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <trace/event.h>

#include "flutter/content_handler/vulkan_surface_pool.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace flutter_runner {

VulkanSurfacePool::VulkanSurfacePool(vulkan::VulkanProcTable& p_vk,
                                     sk_sp<GrContext> context,
                                     sk_sp<GrVkBackendContext> backend_context,
                                     scenic_lib::Session* mozart_session)
    : vk_(p_vk),
      context_(std::move(context)),
      backend_context_(std::move(backend_context)),
      mozart_session_(mozart_session) {}

VulkanSurfacePool::~VulkanSurfacePool() {}

std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
VulkanSurfacePool::AcquireSurface(const SkISize& size) {
  auto surface = GetCachedOrCreateSurface(size);

  if (surface == nullptr) {
    FXL_DLOG(ERROR) << "Could not acquire surface";
    return nullptr;
  }

  if (!surface->FlushSessionAcquireAndReleaseEvents()) {
    FXL_DLOG(ERROR) << "Could not flush acquir/release events for buffer.";
    return nullptr;
  }

  return surface;
}

std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
VulkanSurfacePool::GetCachedOrCreateSurface(const SkISize& size) {
  auto found_in_available = available_surfaces_.find(size);
  if (found_in_available == available_surfaces_.end()) {
    return CreateSurface(size);
  }
  SurfacesSet& available_surfaces = found_in_available->second;
  FXL_DCHECK(available_surfaces.size() > 0);
  auto acquired_surface = std::move(available_surfaces.back());
  available_surfaces.pop_back();
  if (available_surfaces.size() == 0) {
    available_surfaces_.erase(found_in_available);
  }
  if (acquired_surface->IsValid()) {
    trace_surfaces_reused_++;
    return acquired_surface;
  }
  // This is only likely to happen if the surface was invalidated between the
  // time it was sent into the available buffers cache and accessed now.
  // Extremely unlikely.
  return CreateSurface(size);
}

void VulkanSurfacePool::SubmitSurface(
    std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
        p_surface) {
  if (!p_surface) {
    return;
  }

  uintptr_t surface_key = reinterpret_cast<uintptr_t>(p_surface.get());

  auto insert_iterator =
      pending_surfaces_.insert(std::make_pair(surface_key,          // key
                                              std::move(p_surface)  // value
                                              ));

  if (insert_iterator.second) {
    insert_iterator.first->second->SignalWritesFinished(
        std::bind(&VulkanSurfacePool::RecycleSurface, this, surface_key));
  }
}

std::unique_ptr<VulkanSurface> VulkanSurfacePool::CreateSurface(
    const SkISize& size) {
  auto surface = std::make_unique<VulkanSurface>(
      vk_, context_, backend_context_, mozart_session_, size);
  if (!surface->IsValid()) {
    return nullptr;
  }
  trace_surfaces_created_++;
  return surface;
}

void VulkanSurfacePool::RecycleSurface(uintptr_t surface_key) {
  // Before we do anything, we must clear the surface from the collection of
  // pending surfaces.
  auto found_in_pending = pending_surfaces_.find(surface_key);
  if (found_in_pending == pending_surfaces_.end()) {
    return;
  }

  // Grab a hold of the surface to recycle and clear the entry in the pending
  // surfaces collection.
  std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
      surface_to_recycle = std::move(found_in_pending->second);
  pending_surfaces_.erase(found_in_pending);

  // The surface may have become invalid (for example it the fences could
  // not be reset).
  if (!surface_to_recycle->IsValid()) {
    return;
  }

  // Recycle the buffer by putting it in the list of available surfaces if the
  // maximum size of buffers in the collection is not already present.
  auto& available_surfaces = available_surfaces_[surface_to_recycle->GetSize()];
  if (available_surfaces.size() < kMaxSurfacesOfSameSize) {
    available_surfaces.emplace_back(std::move(surface_to_recycle));
  }
}

void VulkanSurfacePool::AgeAndCollectOldBuffers() {
  std::vector<SkISize> sizes_to_erase;
  for (auto& surface_iterator : available_surfaces_) {
    SurfacesSet& old_surfaces = surface_iterator.second;
    SurfacesSet new_surfaces;
    for (auto& surface : old_surfaces) {
      if (surface->AdvanceAndGetAge() < kMaxSurfaceAge) {
        new_surfaces.emplace_back(std::move(surface));
      }
    }
    if (new_surfaces.size() == 0) {
      sizes_to_erase.emplace_back(surface_iterator.first);
    }
    old_surfaces.swap(new_surfaces);
  }
  for (const auto& size : sizes_to_erase) {
    available_surfaces_.erase(size);
  }
  TraceStats();
}

void VulkanSurfacePool::TraceStats() {
  // Resources held in cached buffers.
  size_t cached_surfaces = 0;
  size_t cached_surfaces_bytes = 0;
  for (const auto& surfaces : available_surfaces_) {
    const auto surface_count = surfaces.second.size();
    cached_surfaces += surface_count;
    // TODO(chinmaygarde): Assuming for now that all surfaces are 32bpp.
    cached_surfaces_bytes +=
        (surfaces.first.fWidth * surfaces.first.fHeight * 4 * surface_count);
  }

  // Resources held by Skia.
  int skia_resources = 0;
  size_t skia_bytes = 0;
  context_->getResourceCacheUsage(&skia_resources, &skia_bytes);
  const size_t skia_cache_purgeable =
      context_->getResourceCachePurgeableBytes();

  TRACE_COUNTER("flutter", "SurfacePool", 0u,                     //
                "CachedCount", cached_surfaces,                   //
                "CachedBytes", cached_surfaces_bytes,             //
                "Created", trace_surfaces_created_,               //
                "Reused", trace_surfaces_reused_,                 //
                "PendingInCompositor", pending_surfaces_.size(),  //
                "SkiaCacheResources", skia_resources,             //
                "SkiaCacheBytes", skia_bytes,                     //
                "SkiaCachePurgeable", skia_cache_purgeable        //
  );

  // Reset per present/frame stats.
  trace_surfaces_created_ = 0;
  trace_surfaces_reused_ = 0;
}

}  // namespace flutter_runner
