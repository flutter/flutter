// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <dlfcn.h>

#include "flutter/shell/platform/linux/testing/mock_gtk.h"

using namespace flutter::testing;

G_DECLARE_FINAL_TYPE(FlMockKeymap, fl_mock_keymap, FL, MOCK_KEYMAP, GObject)

struct _FlMockKeymap {
  GObject parent_instance;
};

G_DEFINE_TYPE(FlMockKeymap, fl_mock_keymap, G_TYPE_OBJECT)

static void fl_mock_keymap_class_init(FlMockKeymapClass* klass) {
  g_signal_new("keys-changed", fl_mock_keymap_get_type(), G_SIGNAL_RUN_LAST, 0,
               nullptr, nullptr, nullptr, G_TYPE_NONE, 0);
}

static void fl_mock_keymap_init(FlMockKeymap* self) {}

static MockGtk* mock = nullptr;

MockGtk::MockGtk() {
  mock = this;
}

MockGtk::~MockGtk() {
  if (mock == this) {
    mock = nullptr;
  }
}

GdkKeymap* gdk_keymap_get_for_display(GdkDisplay* display) {
  FlMockKeymap* keymap =
      FL_MOCK_KEYMAP(g_object_new(fl_mock_keymap_get_type(), nullptr));
  (void)FL_IS_MOCK_KEYMAP(keymap);
  return reinterpret_cast<GdkKeymap*>(keymap);
}

guint gdk_keymap_lookup_key(GdkKeymap* keymap, const GdkKeymapKey* key) {
  return mock->gdk_keymap_lookup_key(keymap, key);
}

GdkDisplay* gdk_display_get_default() {
  return GDK_DISPLAY(g_object_new(gdk_display_get_type(), nullptr));
}

void gdk_display_beep(GdkDisplay* display) {}

GdkWindowState gdk_window_get_state(GdkWindow* window) {
  return mock->gdk_window_get_state(window);
}

GdkDisplay* gdk_window_get_display(GdkWindow* window) {
  return GDK_DISPLAY(g_object_new(gdk_display_get_type(), nullptr));
}

int gdk_display_get_n_monitors(GdkDisplay* display) {
  return 1;
}

GdkMonitor* gdk_display_get_monitor(GdkDisplay* display, int n) {
  return GDK_MONITOR(g_object_new(gdk_monitor_get_type(), nullptr));
}

GdkMonitor* gdk_display_get_monitor_at_window(GdkDisplay* display,
                                              GdkWindow* window) {
  return nullptr;
}

GdkCursor* gdk_cursor_new_from_name(GdkDisplay* display, const gchar* name) {
  return nullptr;
}

void gdk_window_set_cursor(GdkWindow* window, GdkCursor* cursor) {}

void gdk_gl_context_make_current(GdkGLContext* context) {}

void gdk_gl_context_clear_current() {}

GtkWidget* gtk_window_new(GtkWindowType type) {
  GtkWindow* window = GTK_WINDOW(g_object_new(gtk_window_get_type(), nullptr));
  mock->gtk_window_new(window, type);
  return GTK_WIDGET(window);
}

void gtk_window_set_default_size(GtkWindow* window, gint width, gint height) {
  mock->gtk_window_set_default_size(window, width, height);
}

void gtk_window_set_title(GtkWindow* window, const gchar* title) {
  mock->gtk_window_set_title(window, title);
}

void gtk_window_set_geometry_hints(GtkWindow* window,
                                   GtkWidget* widget,
                                   GdkGeometry* geometry,
                                   GdkWindowHints geometry_mask) {
  mock->gtk_window_set_geometry_hints(window, widget, geometry, geometry_mask);
}

void gtk_window_resize(GtkWindow* window, gint width, gint height) {
  mock->gtk_window_resize(window, width, height);
}

void gtk_window_maximize(GtkWindow* window) {
  mock->gtk_window_maximize(window);
}

void gtk_window_unmaximize(GtkWindow* window) {
  mock->gtk_window_unmaximize(window);
}

gboolean gtk_window_is_maximized(GtkWindow* window) {
  return mock->gtk_window_is_maximized(window);
}

void gtk_window_iconify(GtkWindow* window) {
  mock->gtk_window_iconify(window);
}

void gtk_window_deiconify(GtkWindow* window) {
  mock->gtk_window_deiconify(window);
}

void gtk_widget_show(GtkWidget* widget) {}

void gtk_widget_destroy(GtkWidget* widget) {
  mock->gtk_widget_destroy(widget);
}

void fl_gtk_widget_destroy(GtkWidget* widget) {
  void (*destroy)(GtkWidget*) = reinterpret_cast<void (*)(GtkWidget*)>(
      dlsym(RTLD_NEXT, "gtk_widget_destroy"));
  destroy(widget);
}

gboolean gtk_widget_translate_coordinates(GtkWidget* src_widget,
                                          GtkWidget* dest_widget,
                                          gint src_x,
                                          gint src_y,
                                          gint* dest_x,
                                          gint* dest_y) {
  if (mock == nullptr) {
    *dest_x = src_x;
    *dest_y = src_y;
    return TRUE;
  }

  return mock->gtk_widget_translate_coordinates(src_widget, dest_widget, src_x,
                                                src_y, dest_x, dest_y);
}

GtkWidget* gtk_widget_get_toplevel(GtkWidget* widget) {
  return widget;
}

void gtk_im_context_set_client_window(GtkIMContext* context,
                                      GdkWindow* window) {
  if (mock != nullptr) {
    mock->gtk_im_context_set_client_window(context, window);
  }
}

void gtk_im_context_get_preedit_string(GtkIMContext* context,
                                       gchar** str,
                                       PangoAttrList** attrs,
                                       gint* cursor_pos) {
  if (mock != nullptr) {
    mock->gtk_im_context_get_preedit_string(context, str, attrs, cursor_pos);
  }
}

gboolean gtk_im_context_filter_keypress(GtkIMContext* context,
                                        GdkEventKey* event) {
  if (mock == nullptr) {
    return TRUE;
  }

  return mock->gtk_im_context_filter_keypress(context, event);
}

void gtk_im_context_focus_in(GtkIMContext* context) {
  if (mock != nullptr) {
    mock->gtk_im_context_focus_in(context);
  }
}

void gtk_im_context_focus_out(GtkIMContext* context) {
  if (mock != nullptr) {
    mock->gtk_im_context_focus_out(context);
  }
}

void gtk_im_context_set_cursor_location(GtkIMContext* context,
                                        const GdkRectangle* area) {
  if (mock != nullptr) {
    mock->gtk_im_context_set_cursor_location(context, area);
  }
}

void gtk_im_context_set_surrounding(GtkIMContext* context,
                                    const gchar* text,
                                    gint len,
                                    gint cursor_index) {
  if (mock != nullptr) {
    mock->gtk_im_context_set_surrounding(context, text, len, cursor_index);
  }
}
