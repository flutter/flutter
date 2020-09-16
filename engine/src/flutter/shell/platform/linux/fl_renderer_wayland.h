// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_WAYLAND_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_WAYLAND_H_

#include "flutter/shell/platform/linux/fl_renderer.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlRendererWayland,
                     fl_renderer_wayland,
                     FL,
                     RENDERER_WAYLAND,
                     FlRenderer)

/**
 * FlRendererWayland:
 *
 * #FlRendererWayland is an implementation of a #FlRenderer that renders to
 * Wayland surfaces.
 */

/**
 * fl_renderer_wayland_new:
 *
 * Create an object that allows Flutter to render to Wayland surfaces.
 *
 * Returns: a #FlRendererWayland.
 */
FlRendererWayland* fl_renderer_wayland_new();

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERER_WAYLAND_H_
