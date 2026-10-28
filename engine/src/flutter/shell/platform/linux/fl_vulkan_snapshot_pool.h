// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_SNAPSHOT_POOL_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_SNAPSHOT_POOL_H_

#include <memory>
#include <mutex>
#include <vector>

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_vulkan_device_context.h"

namespace flutter {
class FlVulkanSnapshot;
class FlVulkanSnapshotPool;

// One export allocation and its raster-thread command resources. GTK keeps a
// lease, not ownership of the Vulkan resources, until its last texture
// releases.
struct FlVulkanSnapshotBuffer {
  explicit FlVulkanSnapshotBuffer(const FlVulkanDeviceContext& context);
  ~FlVulkanSnapshotBuffer();

 private:
  friend class FlVulkanSnapshot;
  friend class FlVulkanSnapshotPool;
  template <typename T>
  T Proc(const char* name) const {
    return reinterpret_cast<T>(context.get_proc(context.device, name));
  }
  bool Initialize(uint32_t width, uint32_t height, GError** error);
  bool Copy(VkImage source, GError** error);
  FlVulkanDeviceContext context;
  FlGtk4DmabufDescriptor descriptor = {};
  VkBuffer buffer = VK_NULL_HANDLE;
  VkDeviceMemory memory = VK_NULL_HANDLE;
  VkDeviceSize allocation_size = 0;
  VkCommandPool command_pool = VK_NULL_HANDLE;
  VkCommandBuffer command = VK_NULL_HANDLE;
  VkFence fence = VK_NULL_HANDLE;
  int fd = -1;
  bool busy = true;
  bool healthy = true;
  bool foreign_owned = false;
};

// Bounded per-manager pool. Acquisition/copies run on the raster thread; any
// thread may return a lease. Returning never invokes Vulkan. Final destruction
// is dispatched independently of the engine, including after engine teardown.
class FlVulkanSnapshotPool
    : public std::enable_shared_from_this<FlVulkanSnapshotPool> {
 public:
  struct Stats {
    size_t allocations = 0;
    size_t reuses = 0;
    size_t exhaustions = 0;
    size_t slots = 0;
    VkDeviceSize memory_bytes = 0;
  };
  static std::shared_ptr<FlVulkanSnapshotPool> Create(
      const FlVulkanDeviceContext& context,
      size_t capacity = 3);
  std::shared_ptr<FlVulkanSnapshotBuffer> Copy(VkImage source,
                                               uint32_t width,
                                               uint32_t height,
                                               GError** error);
  Stats stats() const;
  ~FlVulkanSnapshotPool();

 private:
  FlVulkanSnapshotPool(const FlVulkanDeviceContext& context, size_t capacity);
  void Release(FlVulkanSnapshotBuffer* buffer);
  FlVulkanDeviceContext context_;
  const size_t capacity_;
  mutable std::mutex mutex_;
  std::vector<std::unique_ptr<FlVulkanSnapshotBuffer>> slots_;
  Stats stats_;
};
}  // namespace flutter
#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_SNAPSHOT_POOL_H_
