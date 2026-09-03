// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_MONITOR_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_MONITOR_H_

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlViewMonitor, fl_view_monitor, FL, VIEW_MONITOR, GObject);

/**
 * fl_view_monitor_new:
 * @view: the view being monitored.
 * @on_first_frame: the function to call when the first frame is rendered.
 *
 * Helper class to allow the Flutter engine to monitor a FlView using FFI.
 * Callbacks are called in the isolate this class was created with.
 *
 * Returns: a new #FlViewMonitor.
 */
FlViewMonitor* fl_view_monitor_new(FlView* view, void (*on_first_frame)(void));

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_MONITOR_H_
