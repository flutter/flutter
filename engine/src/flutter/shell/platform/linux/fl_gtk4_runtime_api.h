// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_

#include <gtk/gtk.h>

#if FLUTTER_LINUX_GTK4

#if GTK_CHECK_VERSION(4, 14, 0)
using FlGtkAccessibleAnnouncementPriority = GtkAccessibleAnnouncementPriority;
#else
using FlGtkAccessibleAnnouncementPriority = gint;
#endif

#if GTK_CHECK_VERSION(4, 10, 0)
using FlGtkAccessiblePlatformState = GtkAccessiblePlatformState;
#else
enum FlGtkAccessiblePlatformState {
  FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSABLE = 0,
  FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED = 1,
  FL_GTK_ACCESSIBLE_PLATFORM_STATE_ACTIVE = 2,
};
#endif

// GTK 4.10 appended these virtual methods to GtkAccessibleInterface. This
// mirror lets a GTK 4.8-header build install them on a newer runtime.
struct FlGtkAccessibleInterface4_10 {
  GTypeInterface g_iface;
  GtkATContext* (*get_at_context)(GtkAccessible* self);
  gboolean (*get_platform_state)(GtkAccessible* self,
                                 FlGtkAccessiblePlatformState state);
  GtkAccessible* (*get_accessible_parent)(GtkAccessible* self);
  GtkAccessible* (*get_first_accessible_child)(GtkAccessible* self);
  GtkAccessible* (*get_next_accessible_sibling)(GtkAccessible* self);
  gboolean (*get_bounds)(GtkAccessible* self,
                         int* x,
                         int* y,
                         int* width,
                         int* height);
};

struct FlGtkRuntimeApi {
  gboolean gtk_at_least_4_10;
  gboolean gtk_at_least_4_14;

  void (*gtk_accessible_set_accessible_parent)(GtkAccessible* self,
                                               GtkAccessible* parent,
                                               GtkAccessible* next_sibling);
  GtkAccessible* (*gtk_accessible_get_first_accessible_child)(
      GtkAccessible* self);
  void (*gtk_accessible_announce)(GtkAccessible* self,
                                  const char* message,
                                  FlGtkAccessibleAnnouncementPriority priority);
};

const FlGtkRuntimeApi* fl_gtk_runtime_api_get();
gboolean fl_gtk_runtime_supports_native_accessibility_tree();
void fl_gtk_runtime_accessible_set_accessible_parent(
    GtkAccessible* self,
    GtkAccessible* parent,
    GtkAccessible* next_sibling);
GtkAccessible* fl_gtk_runtime_accessible_get_first_accessible_child(
    GtkAccessible* self);
void fl_gtk_runtime_accessible_announce(GtkAccessible* self,
                                        const char* message,
                                        gint priority);

#endif  // FLUTTER_LINUX_GTK4

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_
