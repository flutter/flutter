// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_

#include <cairo/cairo.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_compositor.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlCompositorSoftware,
                     fl_compositor_software,
                     FL,
                     COMPOSITOR_SOFTWARE,
                     FlCompositor)

/**
 * FlCompositorSoftware:
 *
 * #FlCompositorSoftware is a class that implements compositing using software
 * rendering.
 */

/**
 * fl_compositor_software_new:
 * @engine: an #FlEngine.
 *
 * Creates a new software rendering compositor.
 *
 * Returns: a new #FlCompositorSoftware.
 */
FlCompositorSoftware* fl_compositor_software_new(FlEngine* engine);

/**
 * fl_compositor_software_render:
 * @compositor: an #FlCompositorSoftware.
 * @view_id: the view to render.
 * @cr: the cairo context to draw to.
 * @scale_factor: pixel scale factor.
 *
 * Render the current frame.
 *
 * Returns: TRUE if rendered.
 */
gboolean fl_compositor_software_render(FlCompositorSoftware* compositor,
                                       FlutterViewId view_id,
                                       cairo_t* cr,
                                       gint scale_factor);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_
