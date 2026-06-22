// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_display_monitor.h"

GListModel* fl_display_monitor_gtk4_get_monitors(GdkDisplay* display) {
  g_return_val_if_fail(GDK_IS_DISPLAY(display), nullptr);
  return G_LIST_MODEL(g_object_ref(gdk_display_get_monitors(display)));
}
