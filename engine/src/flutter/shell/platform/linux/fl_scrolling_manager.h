// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_SCROLLING_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_SCROLLING_MANAGER_H_

#include <gdk/gdk.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlScrollingManager,
                     fl_scrolling_manager,
                     FL,
                     SCROLLING_MANAGER,
                     GObject);

/**
 * fl_scrolling_manager_new:
 * @engine: an #FlEngine.
 * @view_id: the view being managed.
 *
 * Create a new #FlScrollingManager.
 *
 * Returns: a new #FlScrollingManager.
 */
FlScrollingManager* fl_scrolling_manager_new(FlEngine* engine,
                                             FlutterViewId view_id);

/**
 * fl_scrolling_manager_set_last_mouse_position:
 * @manager: an #FlScrollingManager.
 * @x: the mouse x-position, in window coordinates.
 * @y: the mouse y-position, in window coordinates.
 *
 * Inform the scrolling manager of the mouse position.
 *
 * This position is only a fallback: pan/zoom gestures pass the position of the
 * gesture itself to fl_scrolling_manager_handle_*_begin/update/end, and this
 * stored value is used only when a gesture cannot supply one.
 */
void fl_scrolling_manager_set_last_mouse_position(FlScrollingManager* manager,
                                                  gdouble x,
                                                  gdouble y);

/**
 * fl_scrolling_manager_handle_scroll_event:
 * @manager: an #FlScrollingManager.
 * @event: the scroll event.
 * @scale_factor: the GTK scaling factor of the window.
 *
 * Inform the scrolling manager of a scroll event.
 */
void fl_scrolling_manager_handle_scroll_event(FlScrollingManager* manager,
                                              GdkEventScroll* event,
                                              gint scale_factor);

/**
 * fl_scrolling_manager_handle_rotation_begin:
 * @manager: an #FlScrollingManager.
 * @has_position: whether @x and @y hold the gesture position.
 * @x: the gesture x-position, in window coordinates.
 * @y: the gesture y-position, in window coordinates.
 *
 * Inform the scrolling manager that a rotation gesture has begun.
 *
 * When @has_position is false the last position reported with
 * fl_scrolling_manager_set_last_mouse_position() is used instead. Callers
 * should pass the position of the gesture they are handling so that a gesture
 * is not reported at a stale position (or at the origin) when it is the first
 * interaction with the window.
 */
void fl_scrolling_manager_handle_rotation_begin(FlScrollingManager* manager,
                                                gboolean has_position,
                                                gdouble x,
                                                gdouble y);

/**
 * fl_scrolling_manager_handle_rotation_update:
 * @manager: an #FlScrollingManager.
 * @has_position: whether @x and @y hold the gesture position.
 * @x: the gesture x-position, in window coordinates.
 * @y: the gesture y-position, in window coordinates.
 * @rotation: the rotation angle, in radians.
 *
 * Inform the scrolling manager that a rotation gesture has updated.
 */
void fl_scrolling_manager_handle_rotation_update(FlScrollingManager* manager,
                                                 gboolean has_position,
                                                 gdouble x,
                                                 gdouble y,
                                                 gdouble rotation);

/**
 * fl_scrolling_manager_handle_rotation_end:
 * @manager: an #FlScrollingManager.
 * @has_position: whether @x and @y hold the gesture position.
 * @x: the gesture x-position, in window coordinates.
 * @y: the gesture y-position, in window coordinates.
 *
 * Inform the scrolling manager that a rotation gesture has ended.
 */
void fl_scrolling_manager_handle_rotation_end(FlScrollingManager* manager,
                                              gboolean has_position,
                                              gdouble x,
                                              gdouble y);

/**
 * fl_scrolling_manager_handle_zoom_begin:
 * @manager: an #FlScrollingManager.
 * @has_position: whether @x and @y hold the gesture position.
 * @x: the gesture x-position, in window coordinates.
 * @y: the gesture y-position, in window coordinates.
 *
 * Inform the scrolling manager that a zoom gesture has begun.
 */
void fl_scrolling_manager_handle_zoom_begin(FlScrollingManager* manager,
                                            gboolean has_position,
                                            gdouble x,
                                            gdouble y);

/**
 * fl_scrolling_manager_handle_zoom_update:
 * @manager: an #FlScrollingManager.
 * @has_position: whether @x and @y hold the gesture position.
 * @x: the gesture x-position, in window coordinates.
 * @y: the gesture y-position, in window coordinates.
 * @scale: the zoom scale.
 *
 * Inform the scrolling manager that a zoom gesture has updated.
 */
void fl_scrolling_manager_handle_zoom_update(FlScrollingManager* manager,
                                             gboolean has_position,
                                             gdouble x,
                                             gdouble y,
                                             gdouble scale);

/**
 * fl_scrolling_manager_handle_zoom_end:
 * @manager: an #FlScrollingManager.
 * @has_position: whether @x and @y hold the gesture position.
 * @x: the gesture x-position, in window coordinates.
 * @y: the gesture y-position, in window coordinates.
 *
 * Inform the scrolling manager that a zoom gesture has ended.
 */
void fl_scrolling_manager_handle_zoom_end(FlScrollingManager* manager,
                                          gboolean has_position,
                                          gdouble x,
                                          gdouble y);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_SCROLLING_MANAGER_H_
