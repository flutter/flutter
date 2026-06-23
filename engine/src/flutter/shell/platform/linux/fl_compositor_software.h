// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_

#include <cairo/cairo.h>
#include <gdk/gdk.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_task_runner.h"

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
 * @task_runner: an #FlTaskRunnner.
 *
 * Creates a new software rendering compositor.
 *
 * Returns: a new #FlCompositorSoftware.
 */
FlCompositorSoftware* fl_compositor_software_new(FlTaskRunner* task_runner);

/**
 * fl_compositor_software_present_layers:
 * @compositor: an #FlCompositorSoftware.
 * @layers: layers to be composited.
 * @layers_count: number of layers.
 *
 * Composite layers. Called from the Flutter rendering thread.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_compositor_software_present_layers(FlCompositorSoftware* compositor,
                                               const FlutterLayer** layers,
                                               size_t layers_count);

/**
 * fl_compositor_software_get_frame_size:
 * @compositor: an #FlCompositorSoftware.
 * @width: location to write frame width in pixels.
 * @height: location to write frame height in pixels.
 *
 * Get the size of the layer ready for rendering.
 */
void fl_compositor_software_get_frame_size(FlCompositorSoftware* compositor,
                                           size_t* width,
                                           size_t* height);

/**
 * fl_compositor_software_render:
 * @compositor: an #FlCompositorSoftware.
 * @cr: a Cairo rendering context.
 * @window: window being rendered into.
 * @wait_for_frame: if the available frame is not the size of the window block
 * until a new frame is received.
 *
 * Renders the current frame. Called from the GTK thread.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_compositor_software_render(FlCompositorSoftware* compositor,
                                       cairo_t* cr,
                                       GdkWindow* window,
                                       gboolean wait_for_frame);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_
