// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_SUBSURFACE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_SUBSURFACE_H_

#include <gtk/gtk.h>

struct wl_surface;

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlSubsurface, fl_subsurface, FL, SUBSURFACE, GObject)

/**
 * FlSubsurface:
 *
 * #FlSubsurface manages a Wayland subsurface attached to the surface of the
 * toplevel window containing a widget. It is used to render Flutter content
 * directly to a Wayland surface, independently of the GTK widget hierarchy.
 */

/**
 * fl_subsurface_new:
 * @widget: the #GtkWidget the subsurface is created for.
 *
 * Creates a new Wayland subsurface on the surface of the toplevel window
 * containing @widget. @widget must be realized and on a Wayland display.
 *
 * Returns: a new #FlSubsurface, or %NULL if it could not be created.
 */
FlSubsurface* fl_subsurface_new(GtkWidget* widget);

/**
 * fl_subsurface_get_surface:
 * @subsurface: an #FlSubsurface.
 *
 * Gets the Wayland surface backing this subsurface.
 *
 * Returns: a `struct wl_surface`.
 */
struct wl_surface* fl_subsurface_get_surface(FlSubsurface* subsurface);

/**
 * fl_subsurface_set_position:
 * @subsurface: an #FlSubsurface.
 * @x: x coordinate in the parent surface.
 * @y: y coordinate in the parent surface.
 *
 * Moves the subsurface to the given position relative to the parent surface.
 */
void fl_subsurface_set_position(FlSubsurface* subsurface, gint x, gint y);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_SUBSURFACE_H_
