// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_

#include <cairo/cairo.h>
#include <glib-object.h>

#include "flutter/shell/platform/embedder/embedder.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlCompositorSoftware,
                     fl_compositor_software,
                     FL,
                     COMPOSITOR_SOFTWARE,
                     GObject)

/**
 * FlCompositorSoftware:
 *
 * #FlCompositorSoftware is a class that implements compositing using software
 * rendering.
 */

/**
 * fl_compositor_software_new:
 *
 * Creates a new software rendering compositor.
 *
 * Returns: a new #FlCompositorSoftware.
 */
FlCompositorSoftware* fl_compositor_software_new();

/**
 * fl_compositor_software_composite_layers:
 * @compositor: an #FlCompositorSoftware.
 * @layers: layers to be composited. Each layer must be a backing store layer
 * (%kFlutterLayerContentTypeBackingStore) backed by a software backing store
 * (%kFlutterBackingStoreTypeSoftware).
 * @layers_count: number of layers.
 *
 * Combines and stores the provided layers as the current frame.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_compositor_software_composite_layers(FlCompositorSoftware* compositor,
                                               const FlutterLayer** layers,
                                               size_t layers_count);

/**
 * fl_compositor_software_get_frame_size:
 * @compositor: an #FlCompositorSoftware.
 * @width: location to write frame width in pixels.
 * @height: location to write frame height in pixels.
 *
 * Get the size of the stored frame. The size is zero if there is no frame yet.
 */
void fl_compositor_software_get_frame_size(FlCompositorSoftware* compositor,
                                           size_t* width,
                                           size_t* height);

/**
 * fl_compositor_software_render:
 * @compositor: an #FlCompositorSoftware.
 * @cr: a Cairo rendering context.
 * @scale_factor: the device scale factor to render at.
 *
 * Renders the stored frame.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_compositor_software_render(FlCompositorSoftware* compositor,
                                       cairo_t* cr,
                                       gint scale_factor);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_
