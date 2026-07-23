// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_RENDERER_VULKAN_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_RENDERER_VULKAN_H_

#include "flutter/shell/platform/linux/fl_view_renderer.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlViewRendererVulkan,
                     fl_view_renderer_vulkan,
                     FL,
                     VIEW_RENDERER_VULKAN,
                     FlViewRenderer)

/**
 * FlViewRendererVulkan:
 *
 * #FlViewRendererVulkan is an #FlViewRenderer that renders Flutter frames using
 * Impeller's Vulkan backend. Impeller owns a KHR swapchain that presents into a
 * synchronized wl_subsurface (Wayland) or the toplevel window (X11), so this
 * renderer does not composite layers itself; its job is to create the Vulkan
 * manager, keep the subsurface positioned, and drive parent-surface commits so
 * the presented frames become visible.
 */

/**
 * fl_view_renderer_vulkan_new:
 * @engine: the #FlEngine to render.
 * @sized_to_content: %TRUE if the view size is controlled by Flutter.
 *
 * Creates a new widget that renders Flutter frames using Vulkan.
 *
 * Returns: a new #FlViewRendererVulkan.
 */
FlViewRendererVulkan* fl_view_renderer_vulkan_new(FlEngine* engine,
                                                  gboolean sized_to_content);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_RENDERER_VULKAN_H_
