// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_VMA_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_VMA_H_

#include <memory>
#include <mutex>
#include <shared_mutex>
#include <unordered_map>

#include "flutter/flutter_vma/flutter_vma.h"
#include "flutter/fml/trace_event.h"
#include "flutter/fml/unique_object.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

// -----------------------------------------------------------------------------
// Unique handles to VMA allocators.
// -----------------------------------------------------------------------------
struct AllocatorVMATraits {
  static VmaAllocator InvalidValue() { return {}; }

  static bool IsValid(const VmaAllocator& value) {
    return value != InvalidValue();
  }

  static void Free(VmaAllocator allocator) {
    TRACE_EVENT0("impeller", "DestroyAllocator");
    ::vmaDestroyAllocator(allocator);
  }
};

using UniqueAllocatorVMA = fml::UniqueObject<VmaAllocator, AllocatorVMATraits>;

// -----------------------------------------------------------------------------
// Unique handles to VMA pools.
// -----------------------------------------------------------------------------

struct PoolVMA {
  VmaAllocator allocator = {};
  VmaPool pool = {};

  constexpr bool operator==(const PoolVMA& other) const = default;
};

struct PoolVMATraits {
  static PoolVMA InvalidValue() { return {}; }

  static bool IsValid(const PoolVMA& value) {
    return value.allocator != VmaAllocator{};
  }

  static void Free(const PoolVMA& pool) {
    TRACE_EVENT0("impeller", "DestroyPool");
    ::vmaDestroyPool(pool.allocator, pool.pool);
  }
};

using UniquePoolVMA = fml::UniqueObject<PoolVMA, PoolVMATraits>;

// -----------------------------------------------------------------------------
// Unique handles to VMA buffers.
// -----------------------------------------------------------------------------

struct BufferVMA {
  VmaAllocator allocator = {};
  VmaAllocation allocation = {};
  vk::Buffer buffer = {};

  constexpr bool operator==(const BufferVMA& other) const {
    return allocator == other.allocator && allocation == other.allocation &&
           buffer == other.buffer;
  }

  constexpr bool operator!=(const BufferVMA& other) const {
    return !(*this == other);
  }
};

struct BufferVMATraits {
  static BufferVMA InvalidValue() { return {}; }

  static bool IsValid(const BufferVMA& value) {
    return value.allocator != VmaAllocator{};
  }

  static void Free(const BufferVMA& buffer) {
    TRACE_EVENT0("impeller", "DestroyBuffer");
    ::vmaDestroyBuffer(buffer.allocator, static_cast<VkBuffer>(buffer.buffer),
                       buffer.allocation);
  }
};

using UniqueBufferVMA = fml::UniqueObject<BufferVMA, BufferVMATraits>;

// -----------------------------------------------------------------------------
// Unique handles to VMA images.
// -----------------------------------------------------------------------------

struct ImageVMA {
  VmaAllocator allocator = {};
  VmaAllocation allocation = {};
  vk::Image image = {};

  constexpr bool operator==(const ImageVMA& other) const {
    return allocator == other.allocator && allocation == other.allocation &&
           image == other.image;
  }

  constexpr bool operator!=(const ImageVMA& other) const {
    return !(*this == other);
  }
};

struct ImageVMATraits {
  static ImageVMA InvalidValue() { return {}; }

  static bool IsValid(const ImageVMA& value) {
    return value.allocator != VmaAllocator{};
  }

  static void Free(const ImageVMA& image) {
    TRACE_EVENT0("impeller", "DestroyImage");
    ::vmaDestroyImage(image.allocator, static_cast<VkImage>(image.image),
                      image.allocation);
  }
};

using UniqueImageVMA = fml::UniqueObject<ImageVMA, ImageVMATraits>;

// -----------------------------------------------------------------------------
// Tracks live VMA-backed resource payloads so ~ContextVK() / ~AllocatorVK()
// can invalidate them while VmaAllocator and VkDevice are still valid.
// -----------------------------------------------------------------------------
class VmaResourceTracker final {
 public:
  using InvalidateFn = void (*)(void*);

  VmaResourceTracker() = default;
  ~VmaResourceTracker() = default;

  /// Acquire a shared lifecycle lock. Callers performing VMA allocations,
  /// handle reads, or destructions must hold this lock and check `IsShutdown()`
  /// before touching VmaAllocator or VkDevice so they cannot race with
  /// `Shutdown()`.
  std::shared_lock<std::shared_mutex> LockShared() const {
    return std::shared_lock<std::shared_mutex>(lifecycle_mutex_);
  }

  /// Must be called while holding `LockShared()` or `Shutdown()`'s exclusive
  /// lock.
  bool IsShutdown() const { return is_shutdown_; }

  /// Register a live resource payload with a non-virtual invalidation callback.
  /// Must be called while holding `LockShared()` after confirming
  /// `!IsShutdown()`.
  void Register(void* key, InvalidateFn invalidate_fn) {
    std::scoped_lock lock(map_mutex_);
    resources_.emplace(key, invalidate_fn);
  }

  /// Unregister a live resource payload. Must be called while holding
  /// `LockShared()` after confirming `!IsShutdown()`.
  void Unregister(void* key) {
    std::scoped_lock lock(map_mutex_);
    resources_.erase(key);
  }

  /// Mark the tracker shut down and invalidate all remaining live resources.
  /// Runs `on_after_sweep` under the exclusive lifecycle lock so the caller can
  /// destroy VmaPool / VmaAllocator with zero live allocations.
  template <typename Fn>
  void Shutdown(Fn&& on_after_sweep) {
    std::unique_lock lifecycle_lock(lifecycle_mutex_);
    if (is_shutdown_) {
      return;
    }
    is_shutdown_ = true;
    std::unordered_map<void*, InvalidateFn> to_invalidate;
    {
      std::scoped_lock map_lock(map_mutex_);
      to_invalidate.swap(resources_);
    }
    for (const auto& [key, invalidate_fn] : to_invalidate) {
      invalidate_fn(key);
    }
    on_after_sweep();
  }

 private:
  mutable std::shared_mutex lifecycle_mutex_;
  std::mutex map_mutex_;
  std::unordered_map<void*, InvalidateFn> resources_;
  bool is_shutdown_ = false;

  VmaResourceTracker(const VmaResourceTracker&) = delete;
  VmaResourceTracker& operator=(const VmaResourceTracker&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_VMA_H_
