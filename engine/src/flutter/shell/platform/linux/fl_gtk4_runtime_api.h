// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_

#include <gtk/gtk.h>

#if FLUTTER_LINUX_GTK4

struct FlGtkRuntimeApi {
  gboolean gtk_at_least_4_10;
  gboolean gtk_at_least_4_14;

  void (*gtk_accessible_set_accessible_parent)(GtkAccessible* self,
                                               GtkAccessible* parent,
                                               GtkAccessible* next_sibling);
  void (*gtk_accessible_announce)(GtkAccessible* self,
                                  const char* message,
                                  gint priority);
};

const FlGtkRuntimeApi* fl_gtk_runtime_api_get();
void fl_gtk_runtime_accessible_set_accessible_parent(
    GtkAccessible* self,
    GtkAccessible* parent,
    GtkAccessible* next_sibling);
void fl_gtk_runtime_accessible_announce(GtkAccessible* self,
                                        const char* message,
                                        gint priority);

#endif  // FLUTTER_LINUX_GTK4

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_RUNTIME_API_H_
