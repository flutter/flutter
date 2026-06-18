// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_linux_windowing.h"

static void set_geometry_hints(GtkWindow* window,
                               gboolean has_preferred_constraints,
                               gint min_width,
                               gint min_height,
                               gint max_width,
                               gint max_height) {
  if (!has_preferred_constraints) {
    return;
  }

#if FLUTTER_LINUX_GTK4
  gtk_window_set_resizable(window, TRUE);
  gtk_widget_set_size_request(GTK_WIDGET(window), min_width, min_height);
#else
  GdkGeometry geometry = {};
  geometry.min_width = min_width;
  geometry.min_height = min_height;
  geometry.max_width = max_width;
  geometry.max_height = max_height;
  gtk_window_set_geometry_hints(
      window, nullptr, &geometry,
      static_cast<GdkWindowHints>(GDK_HINT_MIN_SIZE | GDK_HINT_MAX_SIZE));
#endif
}

static FlLinuxWindowingWindow* windowing_window_new(GtkWindow* window,
                                                    FlView* view) {
  FlLinuxWindowingWindow* result =
      static_cast<FlLinuxWindowingWindow*>(g_malloc0(sizeof(*result)));
  result->window = window;
  result->view = view;
  result->view_id = fl_view_get_id(view);
  return result;
}

static FlLinuxWindowingWindow* create_window(FlEngine* engine,
                                             GtkWindow* parent,
                                             gboolean is_dialog,
                                             gboolean has_preferred_size,
                                             gint preferred_width,
                                             gint preferred_height,
                                             gboolean has_preferred_constraints,
                                             gint min_width,
                                             gint min_height,
                                             gint max_width,
                                             gint max_height,
                                             const gchar* title,
                                             gboolean decorated) {
#if FLUTTER_LINUX_GTK4
  GtkWindow* window = GTK_WINDOW(gtk_window_new());
#else
  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
#endif

  if (has_preferred_size) {
    gtk_window_set_default_size(window, preferred_width, preferred_height);
  }
  set_geometry_hints(window, has_preferred_constraints, min_width, min_height,
                     max_width, max_height);
  if (title != nullptr) {
    gtk_window_set_title(window, title);
  }
  gtk_window_set_decorated(window, decorated);

  if (is_dialog && parent != nullptr) {
#if !FLUTTER_LINUX_GTK4
    gtk_window_set_type_hint(window, GDK_WINDOW_TYPE_HINT_DIALOG);
#endif
    gtk_window_set_transient_for(window, parent);
    gtk_window_set_modal(window, TRUE);
  }

  gtk_widget_realize(GTK_WIDGET(window));

  FlView* view = fl_view_new_for_engine(engine);
#if FLUTTER_LINUX_GTK4
  gtk_widget_set_visible(GTK_WIDGET(view), TRUE);
#else
  gtk_widget_show(GTK_WIDGET(view));
#endif
#if FLUTTER_LINUX_GTK4
  gtk_window_set_child(window, GTK_WIDGET(view));
#else
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));
#endif

  return windowing_window_new(window, view);
}

G_MODULE_EXPORT FlLinuxWindowingWindow*
fl_linux_windowing_create_regular_window(FlEngine* engine,
                                         gboolean has_preferred_size,
                                         gint preferred_width,
                                         gint preferred_height,
                                         gboolean has_preferred_constraints,
                                         gint min_width,
                                         gint min_height,
                                         gint max_width,
                                         gint max_height,
                                         const gchar* title,
                                         gboolean decorated) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);
  return create_window(engine, nullptr, FALSE, has_preferred_size,
                       preferred_width, preferred_height,
                       has_preferred_constraints, min_width, min_height,
                       max_width, max_height, title, decorated);
}

G_MODULE_EXPORT FlLinuxWindowingWindow* fl_linux_windowing_create_dialog_window(
    FlEngine* engine,
    GtkWindow* parent,
    gboolean has_preferred_size,
    gint preferred_width,
    gint preferred_height,
    gboolean has_preferred_constraints,
    gint min_width,
    gint min_height,
    gint max_width,
    gint max_height,
    const gchar* title,
    gboolean decorated) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);
  return create_window(engine, parent, TRUE, has_preferred_size,
                       preferred_width, preferred_height,
                       has_preferred_constraints, min_width, min_height,
                       max_width, max_height, title, decorated);
}
