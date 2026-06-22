// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_RUNTIME_API_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_RUNTIME_API_H_

#include <gtk/gtk.h>

#if FLUTTER_LINUX_GTK4

struct FlGtkRuntimeApi {
  gboolean checked;

  gboolean gtk_at_least_4_10;

  void (*gtk_accessible_set_accessible_parent)(
      GtkAccessible* self,
      GtkAccessible* parent,
      GtkAccessible* next_sibling);
};

const FlGtkRuntimeApi* fl_gtk_runtime_api_get();

#endif  // FLUTTER_LINUX_GTK4

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_RUNTIME_API_H_
