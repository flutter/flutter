// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERABLE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERABLE_H_

#include <gdk/gdk.h>

#include "flutter/shell/platform/embedder/embedder.h"

G_BEGIN_DECLS

G_DECLARE_INTERFACE(FlRenderable, fl_renderable, FL, RENDERABLE, GObject);

/**
 * FlRenderable:
 *
 * An interface for a class that can render views from #FlRenderer.
 *
 * This interface is typically implemented by #FlView and is provided to make
 * #FlRenderer easier to test.
 */

struct _FlRenderableInterface {
  GTypeInterface g_iface;

  void (*present_layers)(FlRenderable* renderable,
                         const FlutterLayer** layers,
                         size_t layers_count);
};

/**
 * fl_renderable_present_layers:
 * @renderable: an #FlRenderable
 * @layers: layers to draw.
 * @layers_count: number of layers.
 *
 * present_layers a frame. This method can be called from any thread.
 */
void fl_renderable_present_layers(FlRenderable* renderable,
                                  const FlutterLayer** layers,
                                  size_t layers_count);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_RENDERABLE_H_
