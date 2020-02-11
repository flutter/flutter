// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vulkan_surface_pool.h"

#include <algorithm>
#include <string>

#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace flutter_runner {

namespace {

std::string ToString(const SkISize& size) {
  return "{width: " + std::to_string(size.width()) +
         ", height: " + std::to_string(size.height()) + "}";
}

}  // namespace

VulkanSurfacePool::VulkanSurfacePool(vulkan::VulkanProvider& vulkan_provider,
                                     sk_sp<GrContext> context,
                                     scenic::Session* scenic_session)
    : vulkan_provider_(vulkan_provider),
      context_(std::move(context)),
      scenic_session_(scenic_session) {}

VulkanSurfacePool::~VulkanSurfacePool() {}

std::unique_ptr<VulkanSurface> VulkanSurfacePool::AcquireSurface(
    const SkISize& size) {
  auto surface = GetCachedOrCreateSurface(size);

  if (surface == nullptr) {
    FML_DLOG(ERROR) << "Could not acquire surface";
    return nullptr;
  }

  if (!surface->FlushSessionAcquireAndReleaseEvents()) {
    FML_DLOG(ERROR) << "Could not flush acquire/release events for buffer.";
    return nullptr;
  }

  return surface;
}

std::unique_ptr<VulkanSurface> VulkanSurfacePool::GetCachedOrCreateSurface(
    const SkISize& size) {
  TRACE_EVENT2("flutter", "VulkanSurfacePool::GetCachedOrCreateSurface",
               "width", size.width(), "height", size.height());
  // First try to find a surface that exactly matches |size|.
  {
    auto exact_match_it =
        std::find_if(available_surfaces_.begin(), available_surfaces_.end(),
                     [&size](const auto& surface) {
                       return surface->IsValid() && surface->GetSize() == size;
                     });
    if (exact_match_it != available_surfaces_.end()) {
      auto acquired_surface = std::move(*exact_match_it);
      available_surfaces_.erase(exact_match_it);
      TRACE_EVENT_INSTANT0("flutter", "Exact match found");
      return acquired_surface;
    }
  }

  // Then, look for a surface that has enough |VkDeviceMemory| to hold a
  // |VkImage| of size |size|, but is currently holding a |VkImage| of a
  // different size.
  VulkanImage vulkan_image;
  if (!CreateVulkanImage(vulkan_provider_, size, &vulkan_image)) {
    FML_DLOG(ERROR) << "Failed to create a VkImage of size: " << ToString(size);
    return nullptr;
  }

  auto best_it = available_surfaces_.end();
  for (auto it = available_surfaces_.begin(); it != available_surfaces_.end();
       ++it) {
    const auto& surface = *it;
    if (!surface->IsValid() || surface->GetAllocationSize() <
                                   vulkan_image.vk_memory_requirements.size) {
      continue;
    }
    if (best_it == available_surfaces_.end() ||
        surface->GetAllocationSize() < (*best_it)->GetAllocationSize()) {
      best_it = it;
    }
  }

  // If no such surface exists, then create a new one.
  if (best_it == available_surfaces_.end()) {
    TRACE_EVENT_INSTANT0("flutter", "No available surfaces");
    return CreateSurface(size);
  }

  auto acquired_surface = std::move(*best_it);
  available_surfaces_.erase(best_it);
  bool swap_succeeded =
      acquired_surface->BindToImage(context_, std::move(vulkan_image));
  if (!swap_succeeded) {
    FML_DLOG(ERROR) << "Failed to swap VulkanSurface to new VkImage of size: "
                    << ToString(size);
    TRACE_EVENT_INSTANT0("flutter", "failed to swap, making new");
    return CreateSurface(size);
  }
  TRACE_EVENT_INSTANT0("flutter", "Using differently sized image");
  FML_DCHECK(acquired_surface->IsValid());
  trace_surfaces_reused_++;
  return acquired_surface;
}

void VulkanSurfacePool::SubmitSurface(
    std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>
        p_surface) {
  TRACE_EVENT0("flutter", "VulkanSurfacePool::SubmitSurface");

  // This cast is safe because |VulkanSurface| is the only implementation of
  // |SurfaceProducerSurface| for Flutter on Fuchsia.  Additionally, it is
  // required, because we need to access |VulkanSurface| specific information
  // of the surface (such as the amount of VkDeviceMemory it contains).
  auto vulkan_surface = std::unique_ptr<VulkanSurface>(
      static_cast<VulkanSurface*>(p_surface.release()));
  if (!vulkan_surface) {
    return;
  }

  const flutter::LayerRasterCacheKey& retained_key =
      vulkan_surface->GetRetainedKey();

  // TODO(https://bugs.fuchsia.dev/p/fuchsia/issues/detail?id=44141): Re-enable
  // retained surfaces after we find out why textures are being prematurely
  // recycled.
  const bool kUseRetainedSurfaces = false;
  if (kUseRetainedSurfaces && retained_key.id() != 0) {
    // Add the surface to |retained_surfaces_| if its retained key has a valid
    // layer id (|retained_key.id()|).
    //
    // We have to add the entry to |retained_surfaces_| map early when it's
    // still pending (|is_pending| = true). Otherwise (if we add the surface
    // later when |SignalRetainedReady| is called), Flutter would fail to find
    // the retained node before the painting is done (which could take multiple
    // frames). Flutter would then create a new |VulkanSurface| for the layer
    // upon the failed lookup. The new |VulkanSurface| would invalidate this
    // surface, and before the new |VulkanSurface| is done painting, another
    // newer |VulkanSurface| is likely to be created to replace the new
    // |VulkanSurface|. That would make the retained rendering much less useful
    // in improving the performance.
    auto insert_iterator = retained_surfaces_.insert(std::make_pair(
        retained_key, RetainedSurface({true, std::move(vulkan_surface)})));
    if (insert_iterator.second) {
      insert_iterator.first->second.vk_surface->SignalWritesFinished(std::bind(
          &VulkanSurfacePool::SignalRetainedReady, this, retained_key));
    }
  } else {
    uintptr_t surface_key = reinterpret_cast<uintptr_t>(vulkan_surface.get());
    auto insert_iterator = pending_surfaces_.insert(std::make_pair(
        surface_key,               // key
        std::move(vulkan_surface)  // value
        ));
    if (insert_iterator.second) {
      insert_iterator.first->second->SignalWritesFinished(std::bind(
          &VulkanSurfacePool::RecyclePendingSurface, this, surface_key));
    }
  }
}

std::unique_ptr<VulkanSurface> VulkanSurfacePool::CreateSurface(
    const SkISize& size) {
  TRACE_EVENT2("flutter", "VulkanSurfacePool::CreateSurface", "width",
               size.width(), "height", size.height());
  auto surface = std::make_unique<VulkanSurface>(vulkan_provider_, context_,
                                                 scenic_session_, size);
  if (!surface->IsValid()) {
    return nullptr;
  }
  trace_surfaces_created_++;
  return surface;
}

void VulkanSurfacePool::RecyclePendingSurface(uintptr_t surface_key) {
  // Before we do anything, we must clear the surface from the collection of
  // pending surfaces.
  auto found_in_pending = pending_surfaces_.find(surface_key);
  if (found_in_pending == pending_surfaces_.end()) {
    return;
  }

  // Grab a hold of the surface to recycle and clear the entry in the pending
  // surfaces collection.
  auto surface_to_recycle = std::move(found_in_pending->second);
  pending_surfaces_.erase(found_in_pending);

  RecycleSurface(std::move(surface_to_recycle));
}

void VulkanSurfacePool::RecycleSurface(std::unique_ptr<VulkanSurface> surface) {
  // The surface may have become invalid (for example it the fences could
  // not be reset).
  if (!surface->IsValid()) {
    return;
  }

  TRACE_EVENT0("flutter", "VulkanSurfacePool::RecycleSurface");
  // Recycle the buffer by putting it in the list of available surfaces if we
  // have not reached the maximum amount of cached surfaces.
  if (available_surfaces_.size() < kMaxSurfaces) {
    available_surfaces_.push_back(std::move(surface));
  } else {
    TRACE_EVENT_INSTANT0("flutter", "Too many surfaces in pool, dropping");
  }
  TraceStats();
}

void VulkanSurfacePool::RecycleRetainedSurface(
    const flutter::LayerRasterCacheKey& key) {
  auto it = retained_surfaces_.find(key);
  if (it == retained_surfaces_.end()) {
    return;
  }

  // The surface should not be pending.
  FML_DCHECK(!it->second.is_pending);

  auto surface_to_recycle = std::move(it->second.vk_surface);
  retained_surfaces_.erase(it);
  RecycleSurface(std::move(surface_to_recycle));
}

void VulkanSurfacePool::SignalRetainedReady(flutter::LayerRasterCacheKey key) {
  retained_surfaces_[key].is_pending = false;
}

void VulkanSurfacePool::AgeAndCollectOldBuffers() {
  TRACE_EVENT0("flutter", "VulkanSurfacePool::AgeAndCollectOldBuffers");

  // Remove all surfaces that are no longer valid or are too old.
  size_t size_before = available_surfaces_.size();
  available_surfaces_.erase(
      std::remove_if(available_surfaces_.begin(), available_surfaces_.end(),
                     [&](auto& surface) {
                       return !surface->IsValid() ||
                              surface->AdvanceAndGetAge() >= kMaxSurfaceAge;
                     }),
      available_surfaces_.end());
  TRACE_EVENT1("flutter", "AgeAndCollect", "aged surfaces",
               (size_before - available_surfaces_.size()));

  // Look for a surface that has both a larger |VkDeviceMemory| allocation
  // than is necessary for its |VkImage|, and has a stable size history.
  auto surface_to_remove_it = std::find_if(
      available_surfaces_.begin(), available_surfaces_.end(),
      [](const auto& surface) {
        return surface->IsOversized() && surface->HasStableSizeHistory();
      });
  // If we found such a surface, then destroy it and cache a new one that only
  // uses a necessary amount of memory.
  if (surface_to_remove_it != available_surfaces_.end()) {
    TRACE_EVENT_INSTANT0("flutter", "replacing surface with smaller one");
    auto size = (*surface_to_remove_it)->GetSize();
    available_surfaces_.erase(surface_to_remove_it);
    auto new_surface = CreateSurface(size);
    if (new_surface != nullptr) {
      available_surfaces_.push_back(std::move(new_surface));
    } else {
      FML_DLOG(ERROR) << "Failed to create a new shrunk surface";
    }
  }

  // Recycle retained surfaces that are not used and not pending in this frame.
  //
  // It's safe to recycle any retained surfaces that are not pending no matter
  // whether they're used or not. Hence if there's memory pressure, feel free to
  // recycle all retained surfaces that are not pending.
  std::vector<flutter::LayerRasterCacheKey> recycle_keys;
  for (auto& [key, retained_surface] : retained_surfaces_) {
    if (retained_surface.is_pending ||
        retained_surface.vk_surface->IsUsedInRetainedRendering()) {
      // Reset the flag for the next frame
      retained_surface.vk_surface->ResetIsUsedInRetainedRendering();
    } else {
      recycle_keys.push_back(key);
    }
  }
  for (auto& key : recycle_keys) {
    RecycleRetainedSurface(key);
  }

  TraceStats();
}

void VulkanSurfacePool::ShrinkToFit() {
  TRACE_EVENT0("flutter", "VulkanSurfacePool::ShrinkToFit");
  // Reset all oversized surfaces in |available_surfaces_| so that the old
  // surfaces and new surfaces don't exist at the same time at any point,
  // reducing our peak memory footprint.
  std::vector<SkISize> sizes_to_recreate;
  for (auto& surface : available_surfaces_) {
    if (surface->IsOversized()) {
      sizes_to_recreate.push_back(surface->GetSize());
      surface.reset();
    }
  }
  available_surfaces_.erase(std::remove(available_surfaces_.begin(),
                                        available_surfaces_.end(), nullptr),
                            available_surfaces_.end());
  for (const auto& size : sizes_to_recreate) {
    auto surface = CreateSurface(size);
    if (surface != nullptr) {
      available_surfaces_.push_back(std::move(surface));
    } else {
      FML_DLOG(ERROR) << "Failed to create resized surface";
    }
  }

  TraceStats();
}

void VulkanSurfacePool::TraceStats() {
  // Resources held in cached buffers.
  size_t cached_surfaces_bytes = 0;
  size_t retained_surfaces_bytes = 0;

  for (const auto& surface : available_surfaces_) {
    cached_surfaces_bytes += surface->GetAllocationSize();
  }
  for (const auto& retained_entry : retained_surfaces_) {
    retained_surfaces_bytes +=
        retained_entry.second.vk_surface->GetAllocationSize();
  }

  // Resources held by Skia.
  int skia_resources = 0;
  size_t skia_bytes = 0;
  context_->getResourceCacheUsage(&skia_resources, &skia_bytes);
  const size_t skia_cache_purgeable =
      context_->getResourceCachePurgeableBytes();

  TRACE_COUNTER("flutter", "SurfacePoolCounts", 0u, "CachedCount",
                available_surfaces_.size(),                       //
                "Created", trace_surfaces_created_,               //
                "Reused", trace_surfaces_reused_,                 //
                "PendingInCompositor", pending_surfaces_.size(),  //
                "Retained", retained_surfaces_.size(),            //
                "SkiaCacheResources", skia_resources              //
  );

  TRACE_COUNTER("flutter", "SurfacePoolBytes", 0u,          //
                "CachedBytes", cached_surfaces_bytes,       //
                "RetainedBytes", retained_surfaces_bytes,   //
                "SkiaCacheBytes", skia_bytes,               //
                "SkiaCachePurgeable", skia_cache_purgeable  //
  );

  // Reset per present/frame stats.
  trace_surfaces_created_ = 0;
  trace_surfaces_reused_ = 0;
}

}  // namespace flutter_runner
