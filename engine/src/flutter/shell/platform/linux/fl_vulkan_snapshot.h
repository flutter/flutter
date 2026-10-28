// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_SNAPSHOT_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_SNAPSHOT_H_

#include <memory>
#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_vulkan_device_context.h"

namespace flutter {

// Immutable GPU copy of an engine backing image. Its allocation and exported
// descriptor outlive both the backing store and the engine when GTK retains it.
// No Vulkan commands run from GTK's texture release callback.
class FlVulkanSnapshot : public std::enable_shared_from_this<FlVulkanSnapshot> {
 public:
  using Context = FlVulkanDeviceContext;

  static std::shared_ptr<FlVulkanSnapshot> Create(const Context& context,
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
  const FlGtk4DmabufDescriptor& descriptor() const { return descriptor_; }

 private:
  explicit FlVulkanSnapshot(const Context& context) : context_(context) {}
  template <typename T>
  T Proc(const char* name) const {
    return reinterpret_cast<T>(context_.get_proc(context_.device, name));
  }
  Context context_;
  VkBuffer buffer_ = VK_NULL_HANDLE;
  VkDeviceMemory memory_ = VK_NULL_HANDLE;
  FlGtk4DmabufDescriptor descriptor_ = {};
  int fd_ = -1;
};
}  // namespace flutter
#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_SNAPSHOT_H_
