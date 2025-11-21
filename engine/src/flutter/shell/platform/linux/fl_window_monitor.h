// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_WINDOW_MONITOR_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_WINDOW_MONITOR_H_

#include <gtk/gtk.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlWindowMonitor,
                     fl_window_monitor,
                     FL,
                     WINDOW_MONITOR,
                     GObject);

/**
 * fl_window_monitor_new:
 * @window: the window being monitored.
 * @on_configure: the function to call when the window changes size, position or
 * stacking.
 * @on_state_changed: the function to call when the window state changes.
 * @on_is_active_notify: the function to call when the is-active property
 * changes.
 * @on_close: the function to call when the user requests the window to be
 * closed.
 * @on_destroy: the function to call when the window is destroyed.
 *
 * Helper class to allow the Flutter engine to monitor a GtkWindow using FFI.
 * Callbacks are called in the isolate this class was created with.
 *
 * Returns: a new #FlWindowMonitor.
 */
FlWindowMonitor* fl_window_monitor_new(GtkWindow* window,
                                       void (*on_configure)(void),
                                       void (*on_state_changed)(void),
                                       void (*on_is_active_notify)(void),
                                       void (*on_title_notify)(void),
                                       void (*on_close)(void),
                                       void (*on_destroy)(void));

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_WINDOW_MONITOR_H_
