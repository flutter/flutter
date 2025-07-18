// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_H_

#include <glib-object.h>

#include "flutter/shell/platform/embedder/embedder.h"

G_BEGIN_DECLS

G_DECLARE_DERIVABLE_TYPE(FlCompositor, fl_compositor, FL, COMPOSITOR, GObject)

struct _FlCompositorClass {
  GObjectClass parent_class;

  gboolean (*present_layers)(FlCompositor* compositor,
                             const FlutterLayer** layers,
                             size_t layers_count);
};

/**
 * FlCompositor:
 *
 * #FlCompositor is an abstract class that implements Flutter compositing.
 */

/**
 * fl_compositor_present_layers:
 * @compositor: an #FlCompositor.
 * @layers: layers to be composited.
 * @layers_count: number of layers.
 *
 * Callback invoked by the engine to composite the contents of each layer
 * onto the screen.
 *
 * Returns %TRUE if successful.
 */
gboolean fl_compositor_present_layers(FlCompositor* compositor,
                                      const FlutterLayer** layers,
                                      size_t layers_count);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_H_
