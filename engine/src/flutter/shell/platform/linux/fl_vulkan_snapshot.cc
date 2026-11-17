// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_vulkan_snapshot.h"

#include "flutter/shell/platform/linux/fl_linux_gtk4_debug.h"
#include "flutter/shell/platform/linux/fl_vulkan_snapshot_pool.h"

namespace flutter {
std::shared_ptr<FlVulkanSnapshot> FlVulkanSnapshot::Create(
    const std::shared_ptr<FlVulkanSnapshotPool>& pool,
    VkImage source,
    uint32_t width,
    uint32_t height,
    GError** error) {
  auto buffer = pool->Copy(source, width, height, error);
  if (!buffer)
    return nullptr;
  return std::shared_ptr<FlVulkanSnapshot>(
      new FlVulkanSnapshot(std::move(buffer)));
}

FlVulkanSnapshot::FlVulkanSnapshot(
    std::shared_ptr<FlVulkanSnapshotBuffer> buffer)
    : buffer_(std::move(buffer)) {}

FlVulkanSnapshot::~FlVulkanSnapshot() = default;

const FlGtk4DmabufDescriptor& FlVulkanSnapshot::descriptor() const {
  return buffer_->descriptor;
}

GdkTexture* FlVulkanSnapshot::CreateTexture(GdkDisplay* display,
                                            bool* imported,
                                            GError** error) {
  *imported = false;
  if (display &&
      fl_gtk_runtime_dmabuf_format_supported(
          display, buffer_->descriptor.fourcc, buffer_->descriptor.modifier)) {
    auto* reference = new std::shared_ptr<FlVulkanSnapshot>(shared_from_this());
    g_autoptr(GError) import_error = nullptr;
    GdkTexture* texture = fl_gtk_runtime_build_dmabuf_texture(
        display, &buffer_->descriptor,
        [](gpointer data) {
          delete static_cast<std::shared_ptr<FlVulkanSnapshot>*>(data);
        },
        reference, &import_error);
    if (texture) {
      *imported = true;
      return texture;
    }
    delete reference;
    flutter_linux_gtk4_dbg("vulkan-dmabuf", "import-failed=%s",
                           import_error ? import_error->message : "unknown");
  }
  void* mapped = nullptr;
  size_t length =
      size_t(buffer_->descriptor.planes[0].stride) * buffer_->descriptor.height;
  VkResult result = buffer_->Proc<PFN_vkMapMemory>("vkMapMemory")(
      buffer_->context.device, buffer_->memory, 0, length, 0, &mapped);
  if (result != VK_SUCCESS) {
    g_set_error(error, g_quark_from_static_string("fl-vulkan-snapshot-error"),
                result, "vkMapMemory(export fallback) failed (VkResult %d)",
                result);
    return nullptr;
  }
  g_autoptr(GBytes) bytes = g_bytes_new(mapped, length);
  buffer_->Proc<PFN_vkUnmapMemory>("vkUnmapMemory")(buffer_->context.device,
                                                    buffer_->memory);
  return gdk_memory_texture_new(buffer_->descriptor.width,
                                buffer_->descriptor.height,
                                GDK_MEMORY_R8G8B8A8_PREMULTIPLIED, bytes,
                                buffer_->descriptor.planes[0].stride);
}
}  // namespace flutter
