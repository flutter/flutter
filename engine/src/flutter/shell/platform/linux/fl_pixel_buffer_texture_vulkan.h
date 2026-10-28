// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_PIXEL_BUFFER_TEXTURE_VULKAN_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_PIXEL_BUFFER_TEXTURE_VULKAN_H_
#include "flutter/shell/platform/linux/fl_vulkan_manager.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_pixel_buffer_texture.h"

// Raster-thread upload using the existing plugin RGBA callback contract.
// The returned image owns a device lease until the engine releases it.
gboolean fl_pixel_buffer_texture_populate_vulkan(
    FlPixelBufferTexture* texture,
    FlVulkanManager* manager,
    uint32_t width,
    uint32_t height,
    FlutterVulkanExternalTexture* output,
    GError** error);
#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_PIXEL_BUFFER_TEXTURE_VULKAN_H_
