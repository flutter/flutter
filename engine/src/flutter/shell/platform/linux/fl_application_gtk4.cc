// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_application.h"

#include <gtk/gtk.h>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

void fl_application_gtk4_first_frame_cb(FlApplication* self, FlView* view) {
  GtkRoot* root = gtk_widget_get_root(GTK_WIDGET(view));
  GtkWidget* window = root != nullptr ? GTK_WIDGET(root) : nullptr;

  // Show the main window.
  if (window != nullptr && GTK_IS_WINDOW(window)) {
    gtk_window_present(GTK_WINDOW(window));
  }
}

GtkWindow* fl_application_gtk4_create_window(FlApplication* self,
                                             FlView* view) {
  GtkApplicationWindow* window =
      GTK_APPLICATION_WINDOW(gtk_application_window_new(GTK_APPLICATION(self)));

  GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
  gtk_widget_set_visible(GTK_WIDGET(header_bar), TRUE);
  gtk_header_bar_set_show_title_buttons(header_bar, TRUE);
  gtk_window_set_titlebar(GTK_WINDOW(window), GTK_WIDGET(header_bar));

  gtk_window_set_child(GTK_WINDOW(window), GTK_WIDGET(view));

  return GTK_WINDOW(window);
}
