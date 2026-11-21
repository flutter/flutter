// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_DISPLAY_MONITOR_BACKEND_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_DISPLAY_MONITOR_BACKEND_H_

#include <gdk/gdk.h>

typedef struct _FlDisplayMonitorBackend FlDisplayMonitorBackend;

// A removed monitor invalidates its display ID; nullptr requests a refresh.
typedef void (*FlDisplayMonitorBackendChanged)(GdkMonitor* removed_monitor,
                                               gpointer user_data);

// The backend owns discovery subscriptions until free. user_data must outlive
// it.
FlDisplayMonitorBackend* fl_display_monitor_backend_new(
    GdkDisplay* display,
    FlDisplayMonitorBackendChanged changed,
    gpointer user_data);
void fl_display_monitor_backend_start(FlDisplayMonitorBackend* self);
void fl_display_monitor_backend_free(FlDisplayMonitorBackend* self);
// Returns an owned snapshot containing referenced GdkMonitor objects.
GPtrArray* fl_display_monitor_backend_get_monitors(
    FlDisplayMonitorBackend* self);
double fl_display_monitor_backend_get_scale(GdkMonitor* monitor);

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_DISPLAY_MONITOR_BACKEND_H_
