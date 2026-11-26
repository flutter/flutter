// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_SNAPSHOT_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_SNAPSHOT_H_

#include <memory>
#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_vulkan_device_context.h"

namespace flutter {

class FlVulkanSnapshotPool;
struct FlVulkanSnapshotBuffer;

// Completed GPU copy, immutable until GTK releases the final lease. Allocation
// and command resources are reused only after that lifetime boundary.
class FlVulkanSnapshot : public std::enable_shared_from_this<FlVulkanSnapshot> {
 public:
  using Context = FlVulkanDeviceContext;

  static std::shared_ptr<FlVulkanSnapshot> Create(
      const std::shared_ptr<FlVulkanSnapshotPool>& pool,
      VkImage source,
      uint32_t width,
      uint32_t height,
      GError** error);
  ~FlVulkanSnapshot();

  // Main thread only. If GTK cannot import the buffer, return an immutable
  // memory texture of the same frame, without touching the engine image again.
  GdkTexture* CreateTexture(GdkDisplay* display,
                            bool* imported,
                            GError** error);
  const FlGtk4DmabufDescriptor& descriptor() const;

 private:
  explicit FlVulkanSnapshot(std::shared_ptr<FlVulkanSnapshotBuffer> buffer);
  std::shared_ptr<FlVulkanSnapshotBuffer> buffer_;
};
}  // namespace flutter
#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_SNAPSHOT_H_
