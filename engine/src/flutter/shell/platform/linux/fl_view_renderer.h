// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_RENDERER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_RENDERER_H_

#include <gtk/gtk.h>

#include "flutter/shell/platform/embedder/embedder.h"

G_BEGIN_DECLS

G_DECLARE_DERIVABLE_TYPE(FlViewRenderer,
                         fl_view_renderer,
                         FL,
                         VIEW_RENDERER,
                         GtkDrawingArea)

/**
 * FlViewRenderer:
 *
 * #FlViewRenderer is a GTK widget that renders the contents of a Flutter view.
 * Input handling and other view responsibilities are handled by #FlView.
 *
 * Subclasses implement rendering for a particular backend, for example
 * #FlViewRendererOpenGL and #FlViewRendererSoftware. The "first-frame" signal
 * is emitted by subclasses when the first frame has been rendered.
 */

struct _FlViewRendererClass {
  GtkDrawingAreaClass parent_class;

  /**
   * Composites a frame into the renderer. May be called from any thread.
   */
  void (*present_layers)(FlViewRenderer* renderer,
                         const FlutterLayer** layers,
                         size_t layers_count);
};

/**
 * fl_view_renderer_set_background_color:
 * @renderer: an #FlViewRenderer.
 * @color: the background color.
 *
 * Sets the background color drawn behind the Flutter frame.
 */
void fl_view_renderer_set_background_color(FlViewRenderer* renderer,
                                           const GdkRGBA* color);

/**
 * fl_view_renderer_paint_background:
 * @renderer: an #FlViewRenderer.
 * @cr: a #cairo_t to paint to.
 *
 * Paints the background color behind the Flutter frame. Subclasses call this
 * at the start of their draw implementation.
 */
void fl_view_renderer_paint_background(FlViewRenderer* renderer, cairo_t* cr);

/**
 * fl_view_renderer_present_layers:
 * @renderer: an #FlViewRenderer.
 * @layers: layers to draw.
 * @layers_count: number of layers.
 *
 * Composites a frame into the renderer. This method can be called from any
 * thread.
 */
void fl_view_renderer_present_layers(FlViewRenderer* renderer,
                                     const FlutterLayer** layers,
                                     size_t layers_count);

/**
 * fl_view_renderer_emit_first_frame:
 * @renderer: an #FlViewRenderer.
 *
 * Emits the "first-frame" signal. Subclasses call this once the first frame
 * has been rendered.
 */
void fl_view_renderer_emit_first_frame(FlViewRenderer* renderer);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_RENDERER_H_
