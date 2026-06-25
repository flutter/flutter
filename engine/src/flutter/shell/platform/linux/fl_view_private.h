// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_

#include "flutter/shell/platform/linux/fl_compositor.h"
#include "flutter/shell/platform/linux/fl_pointer_manager.h"
#include "flutter/shell/platform/linux/fl_scrolling_manager.h"
#include "flutter/shell/platform/linux/fl_touch_manager.h"
#include "flutter/shell/platform/linux/fl_window_state_monitor.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"
#if FLUTTER_LINUX_GTK4
#include "flutter/shell/platform/linux/fl_view_gtk4_accessibility.h"
#endif
#if !FLUTTER_LINUX_GTK4
#include "flutter/shell/platform/linux/fl_view_accessible.h"
#endif

G_BEGIN_DECLS

struct _FlView {
  GtkBox parent_instance;

  GtkWidget* event_box;
  GtkGesture* zoom_gesture;
  GtkGesture* rotate_gesture;
  GtkWidget* render_area;
  GdkGLContext* render_context;
  FlEngine* engine;
  FlCompositor* compositor;
  FlutterViewId view_id;
  GdkRGBA* background_color;
  gboolean have_first_frame;
  FlWindowStateMonitor* window_state_monitor;
  FlScrollingManager* scrolling_manager;
  FlPointerManager* pointer_manager;
  FlTouchManager* touch_manager;
#if !FLUTTER_LINUX_GTK4
  FlViewAccessible* view_accessible;
#endif
  guint cursor_changed_cb_id;
  gboolean sized_to_content;
#if FLUTTER_LINUX_GTK4
  gboolean native_texture_ready;
  guint native_texture_retry_source_id;
  FlViewGtk4Accessibility* accessibility_backend;
#endif
  GCancellable* cancellable;
};

#if !FLUTTER_LINUX_GTK4
/**
 * fl_view_get_accessible:
 * @view: an #FlView.
 *
 * Get the accessible object for this view.
 *
 * Returns: an #FlViewAccessible.
 */
FlViewAccessible* fl_view_get_accessible(FlView* view);
void fl_view_gtk3_setup(FlView* view);
#else
GtkWidget* fl_view_gtk4_get_toplevel_window(FlView* view);
void fl_view_gtk4_set_cursor(FlView* view, const gchar* cursor_name);
gboolean fl_view_gtk4_legacy_event_cb(FlView* view, GdkEvent* event);
void fl_view_gtk4_setup(FlView* view);
#endif

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
