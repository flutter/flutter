// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_WAYLAND_DISPLAY_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_WAYLAND_DISPLAY_H_

#include <gtk/gtk.h>

#include "flutter/shell/platform/linux/fl_subsurface.h"

struct wl_display;

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlWaylandDisplay,
                     fl_wayland_display,
                     FL,
                     WAYLAND_DISPLAY,
                     GObject)

/**
 * FlWaylandDisplay:
 *
 * #FlWaylandDisplay provides access to the Wayland globals used by Flutter,
 * binding them from the Wayland registry a single time per display.
 */

/**
 * fl_wayland_display_open:
 * @wl_display: the Wayland display to use.
 *
 * Binds the Wayland globals used by Flutter on @wl_display. This is not a
 * plain constructor - it fails if the compositor doesn't provide the globals
 * that are required.
 *
 * Returns: (transfer full): an #FlWaylandDisplay, or %NULL if the required
 * Wayland globals are not available.
 */
FlWaylandDisplay* fl_wayland_display_open(struct wl_display* wl_display);

/**
 * fl_wayland_display_get_for_display:
 * @display: a Wayland #GdkDisplay.
 *
 * Gets the #FlWaylandDisplay for @display, creating it if required. The
 * Wayland registry is only queried the first time this is called for a given
 * display. @display must be a Wayland display, it is a programmer error to
 * call this otherwise.
 *
 * Returns: (transfer none): an #FlWaylandDisplay, or %NULL if the required
 * Wayland globals are not available.
 */
FlWaylandDisplay* fl_wayland_display_get_for_display(GdkDisplay* display);

/**
 * fl_wayland_display_create_subsurface:
 * @display: an #FlWaylandDisplay.
 * @parent_surface: the Wayland surface to attach the subsurface to.
 *
 * Creates a new Wayland subsurface on @parent_surface. @parent_surface must be
 * on the display @display was created for, it is a programmer error to call
 * this otherwise.
 *
 * Returns: (transfer full): a new #FlSubsurface.
 */
FlSubsurface* fl_wayland_display_create_subsurface(
    FlWaylandDisplay* display,
    struct wl_surface* parent_surface);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_WAYLAND_DISPLAY_H_
