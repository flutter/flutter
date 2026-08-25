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
 *
 * Layers are composited into a caller-provided Cairo context. The caller is
 * responsible for managing the surface being drawn into.
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
 * @cr: a Cairo rendering context to draw the layers into.
 * @layers: layers to be composited. Each layer must be a backing store layer
 * (%kFlutterLayerContentTypeBackingStore) backed by a software backing store
 * (%kFlutterBackingStoreTypeSoftware).
 * @layers_count: number of layers.
 *
 * Combines and draws the provided layers into @cr. The caller is responsible
 * for managing the surface that @cr writes into.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_compositor_software_composite_layers(
    FlCompositorSoftware* compositor,
    cairo_t* cr,
    const FlutterLayer** layers,
    size_t layers_count);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_
