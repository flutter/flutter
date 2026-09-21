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
 * is emitted when the first frame has been rendered.
 */

struct _FlViewRendererClass {
  GtkDrawingAreaClass parent_class;

  /**
   * Composites a frame into the renderer. May be called from any thread.
   *
   * This method is abstract and must be implemented by subclasses.
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
 * fl_view_renderer_notify_frame:
 * @renderer: an #FlViewRenderer.
 *
 * Notifies that a frame has been rendered. Subclasses call this on each frame.
 * The "first-frame" signal is emitted on the first call.
 */
void fl_view_renderer_notify_frame(FlViewRenderer* renderer);

/**
 * fl_view_renderer_resize_to_frame:
 * @renderer: an #FlViewRenderer.
 * @frame_width: the width of the current frame in pixels.
 * @frame_height: the height of the current frame in pixels.
 *
 * Requests the view (and its toplevel window) to be resized to fit the frame
 * when the widget size does not match it. Called from the GTK thread when
 * Flutter controls the view size.
 *
 * Returns: %TRUE if a resize was requested, %FALSE if the widget already
 * matches the frame size.
 */
gboolean fl_view_renderer_resize_to_frame(FlViewRenderer* renderer,
                                          size_t frame_width,
                                          size_t frame_height);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_RENDERER_H_
