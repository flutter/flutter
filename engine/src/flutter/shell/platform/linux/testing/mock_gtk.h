// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_GTK_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_GTK_H_

#include "gmock/gmock.h"

#include <gtk/gtk.h>

namespace flutter {
namespace testing {

class MockGtk {
 public:
  MockGtk();
  ~MockGtk();

  MOCK_METHOD(GdkKeymap*, gdk_keymap_get_for_display, (GdkDisplay * display));
  MOCK_METHOD(guint,
              gdk_keymap_lookup_key,
              (GdkKeymap * keymap, const GdkKeymapKey* key));
  MOCK_METHOD(GdkWindowState, gdk_window_get_state, (GdkWindow * window));
  MOCK_METHOD(void, gtk_window_new, (GtkWindow * window, GtkWindowType type));
  MOCK_METHOD(void,
              gtk_window_set_default_size,
              (GtkWindow * window, gint width, gint height));
  MOCK_METHOD(void,
              gtk_window_set_title,
              (GtkWindow * window, const gchar* title));
  MOCK_METHOD(void,
              gtk_window_set_geometry_hints,
              (GtkWindow * window,
               GtkWidget* widget,
               GdkGeometry* geometry,
               GdkWindowHints geometry_mask));
  MOCK_METHOD(void,
              gtk_window_resize,
              (GtkWindow * window, gint width, gint height));
  MOCK_METHOD(void, gtk_window_maximize, (GtkWindow * window));
  MOCK_METHOD(void, gtk_window_unmaximize, (GtkWindow * window));
  MOCK_METHOD(gboolean, gtk_window_is_maximized, (GtkWindow * window));
  MOCK_METHOD(void, gtk_window_iconify, (GtkWindow * window));
  MOCK_METHOD(void, gtk_window_deiconify, (GtkWindow * window));
  MOCK_METHOD(void, gtk_widget_destroy, (GtkWidget * widget));
  MOCK_METHOD(gboolean,
              gtk_widget_translate_coordinates,
              (GtkWidget * src_widget,
               GtkWidget* dest_widget,
               gint src_x,
               gint src_y,
               gint* dest_x,
               gint* dest_y));
  MOCK_METHOD(GtkWidget*, gtk_widget_get_toplevel, (GtkWidget * widget));
  MOCK_METHOD(void,
              gtk_im_context_set_client_window,
              (GtkIMContext * context, GdkWindow* window));
  MOCK_METHOD(void,
              gtk_im_context_get_preedit_string,
              (GtkIMContext * context,
               gchar** str,
               PangoAttrList** attrs,
               gint* cursor_pos));
  MOCK_METHOD(gboolean,
              gtk_im_context_filter_keypress,
              (GtkIMContext * context, GdkEventKey* event));
  MOCK_METHOD(gboolean, gtk_im_context_focus_in, (GtkIMContext * context));
  MOCK_METHOD(void, gtk_im_context_focus_out, (GtkIMContext * context));
  MOCK_METHOD(void,
              gtk_im_context_set_cursor_location,
              (GtkIMContext * context, const GdkRectangle* area));
  MOCK_METHOD(
      void,
      gtk_im_context_set_surrounding,
      (GtkIMContext * context, const gchar* text, gint len, gint cursor_index));
};

}  // namespace testing
}  // namespace flutter

// Calls original gtk_widget_destroy.
void fl_gtk_widget_destroy(GtkWidget* widget);

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_GTK_H_
