// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_

#include "flutter/shell/platform/linux/fl_pointer_manager.h"
#include "flutter/shell/platform/linux/fl_scrolling_manager.h"
#include "flutter/shell/platform/linux/fl_touch_manager.h"
#include "flutter/shell/platform/linux/fl_view_accessible.h"
#include "flutter/shell/platform/linux/fl_view_renderer.h"
#include "flutter/shell/platform/linux/fl_window_state_monitor.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

G_BEGIN_DECLS

// Shared by the view implementation and its GTK3 input adapters. Ownership
// remains in the existing view lifecycle.
struct _FlView {
  GtkBox parent_instance;

  // Event box the render area goes inside.
  GtkWidget* event_box;

  // Handle zoom gestures.
  GtkGesture* zoom_gesture;

  // Handle rotation gestures.
  GtkGesture* rotate_gesture;

  // The widget rendering the Flutter view.
  FlViewRenderer* renderer;

  // Engine this view is showing.
  FlEngine* engine;

  // ID for this view.
  FlutterViewId view_id;

  // Monitor to track window state.
  FlWindowStateMonitor* window_state_monitor;

  // Manages scrolling events.
  FlScrollingManager* scrolling_manager;

  // Manages pointer events.
  FlPointerManager* pointer_manager;

  // Manages touch events.
  FlTouchManager* touch_manager;

  // Accessible tree from Flutter, exposed as an AtkPlug.
  FlViewAccessible* view_accessible;

  // TRUE if the view size should be controlled by Flutter.
  gboolean sized_to_content;

  GCancellable* cancellable;
};

/**
 * fl_view_get_accessible:
 * @view: an #FlView.
 *
 * Get the accessible object for this view.
 *
 * Returns: an #FlViewAccessible.
 */
FlViewAccessible* fl_view_get_accessible(FlView* view);

// Called once from fl_view_init, before engine and input-manager setup.
// Creates the event-box child and connects GTK3 pointer, touch, and gesture
// handlers. The widget hierarchy owns the event box; fl_view_dispose
// releases the gesture objects.
void fl_view_input_gtk3_setup(FlView* self);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
