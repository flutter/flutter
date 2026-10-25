// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_SUBSURFACE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_SUBSURFACE_H_

#include <gtk/gtk.h>

struct wl_compositor;
struct wl_subcompositor;
struct wl_surface;

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlSubsurface, fl_subsurface, FL, SUBSURFACE, GObject)

/**
 * FlSubsurface:
 *
 * #FlSubsurface manages a Wayland subsurface attached to another Wayland
 * surface. It is used to render Flutter content directly to a Wayland surface,
 * independently of the GTK widget hierarchy.
 *
 * The subsurface is desynchronized from its parent surface, so frames
 * committed to it are shown by the compositor as soon as they are committed
 * and the parent (GTK) surface doesn't have to be redrawn for each one. It can
 * be synchronized with the parent while that is changing size, so a frame of
 * the new size is shown together with the resized parent.
 */

/**
 * fl_subsurface_new:
 * @compositor: the Wayland compositor to create the surface with.
 * @subcompositor: the Wayland subcompositor to create the subsurface with.
 * @parent_surface: the Wayland surface to attach the subsurface to.
 *
 * Creates a new Wayland subsurface on @parent_surface.
 *
 * Returns: a new #FlSubsurface.
 */
FlSubsurface* fl_subsurface_new(struct wl_compositor* compositor,
                                struct wl_subcompositor* subcompositor,
                                struct wl_surface* parent_surface);

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

/**
 * fl_subsurface_set_synchronized:
 * @subsurface: an #FlSubsurface.
 * @synchronized: %TRUE to synchronize the subsurface with its parent surface.
 *
 * Sets whether frames committed to the subsurface are held back until the
 * parent surface is next committed (synchronized) or shown as soon as they are
 * committed (desynchronized). A new #FlSubsurface is desynchronized. A frame
 * that was held back is shown when the subsurface is desynchronized again.
 */
void fl_subsurface_set_synchronized(FlSubsurface* subsurface,
                                    gboolean synchronized);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_SUBSURFACE_H_
