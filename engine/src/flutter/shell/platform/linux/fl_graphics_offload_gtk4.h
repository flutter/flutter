// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GRAPHICS_OFFLOAD_GTK4_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GRAPHICS_OFFLOAD_GTK4_H_

#include <gtk/gtk.h>

struct FlGtkRuntimeApi;

// An explicit request that also enables OpenGL DMA-BUF export.
gboolean fl_graphics_offload_gtk4_is_requested();

// Returns a floating GtkGraphicsOffload containing child, or child unchanged
// when disabled/unavailable. The caller parents the returned widget. The
// optional API table permits testing older runtimes and missing symbols.
GtkWidget* fl_graphics_offload_gtk4_wrap(GtkWidget* child,
                                         const FlGtkRuntimeApi* api = nullptr,
                                         gboolean enable_by_default = FALSE);

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GRAPHICS_OFFLOAD_GTK4_H_
