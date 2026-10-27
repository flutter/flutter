// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_graphics_offload_gtk4.h"

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_linux_gtk4_debug.h"

gboolean fl_graphics_offload_gtk4_is_requested() {
  return g_strcmp0(g_getenv("FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD"), "1") == 0;
}

GtkWidget* fl_graphics_offload_gtk4_wrap(GtkWidget* child,
                                         const FlGtkRuntimeApi* api) {
  g_return_val_if_fail(GTK_IS_WIDGET(child), nullptr);
  g_return_val_if_fail(gtk_widget_get_parent(child) == nullptr, nullptr);

  if (!fl_graphics_offload_gtk4_is_requested()) {
    return child;
  }
  if (api == nullptr) {
    api = fl_gtk_runtime_api_get();
  }
  if (!api->gtk_at_least_4_14 ||
      api->gtk_graphics_offload_get_type == nullptr) {
    flutter_linux_gtk4_dbg("graphics_offload",
                           "unavailable; using texture presentation");
    return child;
  }

  // Keep controllers, sizing and semantics on the render widget. The wrapper
  // supplies only GTK's offload hint, with no additional accessible grouping.
  GtkWidget* wrapper = GTK_WIDGET(g_object_new(
      api->gtk_graphics_offload_get_type(), "child", child, "accessible-role",
      GTK_ACCESSIBLE_ROLE_PRESENTATION, nullptr));
  gtk_widget_set_hexpand(wrapper, TRUE);
  gtk_widget_set_vexpand(wrapper, TRUE);
  // GTK automatically snapshots normally when the texture, platform or scene
  // cannot be offloaded. Construction alone does not establish acceptance.
  flutter_linux_gtk4_dbg("graphics_offload",
                         "configured; acceptance is decided by GTK");
  return wrapper;
}
