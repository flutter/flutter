// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_MANAGER_H_

#include <glib-object.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_vulkan_snapshot.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlVulkanManager,
                     fl_vulkan_manager,
                     FL,
                     VULKAN_MANAGER,
                     GObject)

// Vulkan is loaded on demand; constructing a manager does not load a driver.
FlVulkanManager* fl_vulkan_manager_new();
gboolean fl_vulkan_manager_initialize(FlVulkanManager* self,
                                      FlutterVulkanRendererConfig* config,
                                      GError** error);
gboolean fl_vulkan_manager_create_backing_store(
    FlVulkanManager* self,
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store);
void fl_vulkan_manager_collect_backing_store(
    const FlutterBackingStore* backing_store);

// Called on the raster thread after rendering. Returns an immutable, tightly
// packed RGBA8 premultiplied snapshot, independent of the Vulkan allocation.
// This correctness path deliberately uses readback, not DMA-BUF export.
GBytes* fl_vulkan_backing_store_read_pixels(
    const FlutterBackingStore* backing_store,
    size_t* width,
    size_t* height,
    GError** error);

G_END_DECLS

// Internal device lease, empty before initialization.
flutter::FlVulkanDeviceContext fl_vulkan_manager_get_device_context(
    FlVulkanManager* self);

// Raster thread: returns a completed immutable GPU snapshot when the device
// supports DMA-BUF export, or nullptr to select the readback fallback.
std::shared_ptr<flutter::FlVulkanSnapshot> fl_vulkan_backing_store_snapshot(
    const FlutterBackingStore* backing_store,
    GError** error);

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_MANAGER_H_
