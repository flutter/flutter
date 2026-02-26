// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <dlfcn.h>
#include <gdk/gdkwayland.h>
#include <stdarg.h>

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

#if FLUTTER_LINUX_GTK4
G_DECLARE_FINAL_TYPE(FlMockGtk4Surface,
                     fl_mock_gtk4_surface,
                     FL,
                     MOCK_GTK4_SURFACE,
                     GObject)

struct _FlMockGtk4Surface {
  GObject parent_instance;
  GdkToplevelState state;
  gboolean mapped;
};

G_DEFINE_TYPE_WITH_CODE(FlMockGtk4Surface,
                        fl_mock_gtk4_surface,
                        G_TYPE_OBJECT,
                        G_IMPLEMENT_INTERFACE(GDK_TYPE_TOPLEVEL, nullptr))

enum {
  kPropState = 1,
  kPropMapped,
  kPropLast,
};

static GParamSpec* g_properties[kPropLast];

static void fl_mock_gtk4_surface_set_property(GObject* object,
                                              guint prop_id,
                                              const GValue* value,
                                              GParamSpec* pspec) {
  FlMockGtk4Surface* self = FL_MOCK_GTK4_SURFACE(object);
  switch (prop_id) {
    case kPropState:
      self->state = static_cast<GdkToplevelState>(g_value_get_flags(value));
      break;
    case kPropMapped:
      self->mapped = g_value_get_boolean(value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void fl_mock_gtk4_surface_get_property(GObject* object,
                                              guint prop_id,
                                              GValue* value,
                                              GParamSpec* pspec) {
  FlMockGtk4Surface* self = FL_MOCK_GTK4_SURFACE(object);
  switch (prop_id) {
    case kPropState:
      g_value_set_flags(value, self->state);
      break;
    case kPropMapped:
      g_value_set_boolean(value, self->mapped);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void fl_mock_gtk4_surface_class_init(FlMockGtk4SurfaceClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->set_property = fl_mock_gtk4_surface_set_property;
  object_class->get_property = fl_mock_gtk4_surface_get_property;

  g_properties[kPropState] =
      g_param_spec_flags("state", "state", "state", GDK_TYPE_TOPLEVEL_STATE,
                         static_cast<GdkToplevelState>(0),
                         static_cast<GParamFlags>(G_PARAM_READWRITE));
  g_properties[kPropMapped] =
      g_param_spec_boolean("mapped", "mapped", "mapped", FALSE,
                           static_cast<GParamFlags>(G_PARAM_READWRITE));
  g_object_class_install_properties(object_class, kPropLast, g_properties);
}

static void fl_mock_gtk4_surface_init(FlMockGtk4Surface* self) {
  self->state = static_cast<GdkToplevelState>(0);
  self->mapped = FALSE;
}
#endif  // FLUTTER_LINUX_GTK4

// Override GdkKeymap
GType gdk_keymap_get_type() {
  return fl_mock_keymap_get_type();
}

static MockGtk* mock = nullptr;

MockGtk::MockGtk() {
  thread = g_thread_self();
  mock = this;
}

MockGtk::~MockGtk() {
  if (mock == this) {
    mock = nullptr;
  }
}

// Check we are running on the GTK thread.
static void check_thread() {
  if (mock != nullptr) {
    EXPECT_EQ(mock->thread, g_thread_self());
  }
}

GdkKeymap* gdk_keymap_get_for_display(GdkDisplay* display) {
  check_thread();
  FlMockKeymap* keymap =
      FL_MOCK_KEYMAP(g_object_new(fl_mock_keymap_get_type(), nullptr));
  (void)FL_IS_MOCK_KEYMAP(keymap);
  return reinterpret_cast<GdkKeymap*>(keymap);
}

guint gdk_keymap_lookup_key(GdkKeymap* keymap, const GdkKeymapKey* key) {
  check_thread();
  return mock->gdk_keymap_lookup_key(keymap, key);
}

GdkDisplay* gdk_display_get_default() {
  check_thread();
  return GDK_DISPLAY(g_object_new(gdk_wayland_display_get_type(), nullptr));
}

void gdk_display_beep(GdkDisplay* display) {
  check_thread();
}

int gdk_window_get_width(GdkWindow* window) {
  check_thread();
  return 100;
}

int gdk_window_get_height(GdkWindow* window) {
  check_thread();
  return 100;
}

gint gdk_window_get_scale_factor(GdkWindow* window) {
  check_thread();
  return 1;
}

GdkWindowState gdk_window_get_state(GdkWindow* window) {
  check_thread();
  return mock->gdk_window_get_state(window);
}

#if FLUTTER_LINUX_GTK4
GdkToplevelState gdk_toplevel_get_state(GdkToplevel* toplevel) {
  check_thread();
  if (mock != nullptr) {
    return mock->gdk_toplevel_get_state(toplevel);
  }
  FlMockGtk4Surface* surface = FL_MOCK_GTK4_SURFACE(toplevel);
  return surface->state;
}
#endif

GdkDisplay* gdk_window_get_display(GdkWindow* window) {
  check_thread();
  return GDK_DISPLAY(g_object_new(gdk_wayland_display_get_type(), nullptr));
}

int gdk_display_get_n_monitors(GdkDisplay* display) {
  check_thread();
  return 1;
}

GdkMonitor* gdk_display_get_monitor(GdkDisplay* display, int n) {
  check_thread();
  return GDK_MONITOR(g_object_new(gdk_monitor_get_type(), nullptr));
}

GdkMonitor* gdk_display_get_monitor_at_window(GdkDisplay* display,
                                              GdkWindow* window) {
  check_thread();
  return nullptr;
}

void gdk_monitor_get_geometry(GdkMonitor* monitor, GdkRectangle* geometry) {
  check_thread();
}

int gdk_monitor_get_refresh_rate(GdkMonitor* monitor) {
  check_thread();
  return 60000;
}

int gdk_monitor_get_scale_factor(GdkMonitor* monitor) {
  check_thread();
  return 1;
}

GdkCursor* gdk_cursor_new_from_name(GdkDisplay* display, const gchar* name) {
  check_thread();
  return nullptr;
}

void gdk_window_set_cursor(GdkWindow* window, GdkCursor* cursor) {
  check_thread();
}

GdkGLContext* gdk_window_create_gl_context(GdkWindow* window, GError** error) {
  check_thread();
  return nullptr;
}

#if FLUTTER_LINUX_GTK4
gboolean gdk_surface_get_mapped(GdkSurface* surface) {
  check_thread();
  if (mock != nullptr) {
    return mock->gdk_surface_get_mapped(surface);
  }
  FlMockGtk4Surface* gtk4_surface = FL_MOCK_GTK4_SURFACE(surface);
  return gtk4_surface->mapped;
}
#endif

void gdk_cairo_set_source_rgba(cairo_t* cr, const GdkRGBA* rgba) {
  check_thread();
}

void gdk_gl_context_realize(GdkGLContext* context) {
  check_thread();
}

void gdk_gl_context_clear_current(GdkGLContext* context) {
  check_thread();
}

void gdk_gl_context_make_current(GdkGLContext* context) {
  check_thread();
}

void gdk_cairo_draw_from_gl(cairo_t* cr,
                            GdkWindow* window,
                            int source,
                            int source_type,
                            int buffer_scale,
                            int x,
                            int y,
                            int width,
                            int height) {
  check_thread();
}

GtkWidget* gtk_window_new(GtkWindowType type) {
  check_thread();
  GtkWindow* window = GTK_WINDOW(g_object_new(gtk_window_get_type(), nullptr));
  mock->gtk_window_new(window, type);
  return GTK_WIDGET(window);
}

void gtk_window_set_default_size(GtkWindow* window, gint width, gint height) {
  check_thread();
  mock->gtk_window_set_default_size(window, width, height);
}

void gtk_window_set_title(GtkWindow* window, const gchar* title) {
  check_thread();
  mock->gtk_window_set_title(window, title);
}

void gtk_window_set_geometry_hints(GtkWindow* window,
                                   GtkWidget* widget,
                                   GdkGeometry* geometry,
                                   GdkWindowHints geometry_mask) {
  check_thread();
  mock->gtk_window_set_geometry_hints(window, widget, geometry, geometry_mask);
}

void gtk_window_resize(GtkWindow* window, gint width, gint height) {
  check_thread();
  mock->gtk_window_resize(window, width, height);
}

void gtk_window_maximize(GtkWindow* window) {
  check_thread();
  mock->gtk_window_maximize(window);
}

void gtk_window_unmaximize(GtkWindow* window) {
  check_thread();
  mock->gtk_window_unmaximize(window);
}

gboolean gtk_window_is_maximized(GtkWindow* window) {
  check_thread();
  return mock->gtk_window_is_maximized(window);
}

void gtk_window_iconify(GtkWindow* window) {
  check_thread();
  mock->gtk_window_iconify(window);
}

void gtk_window_deiconify(GtkWindow* window) {
  check_thread();
  mock->gtk_window_deiconify(window);
}

void gtk_widget_add_events(GtkWidget* widget, gint events) {
  check_thread();
}

void gtk_widget_class_set_accessible_type(GtkWidget* widget, GType type) {
  check_thread();
}

void gtk_widget_get_allocation(GtkWidget* widget, GtkAllocation* allocation) {
  check_thread();
  allocation->x = 0;
  allocation->y = 0;
  allocation->width = 100;
  allocation->height = 100;
}

GdkDisplay* gtk_widget_get_display(GtkWidget* widget) {
  check_thread();
  return nullptr;
}

gint gtk_widget_get_scale_factor(GtkWidget* widget) {
  check_thread();
  return 1;
}

void gtk_widget_realize(GtkWidget* widget) {
  check_thread();
}

void gtk_widget_show(GtkWidget* widget) {
  check_thread();
}

void gtk_widget_queue_draw(GtkWidget* widget) {
  check_thread();
}

void gtk_widget_destroy(GtkWidget* widget) {
  check_thread();
  mock->gtk_widget_destroy(widget);
}

void fl_gtk_widget_destroy(GtkWidget* widget) {
  check_thread();
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
  check_thread();
  if (mock == nullptr) {
    *dest_x = src_x;
    *dest_y = src_y;
    return TRUE;
  }

  return mock->gtk_widget_translate_coordinates(src_widget, dest_widget, src_x,
                                                src_y, dest_x, dest_y);
}

GtkWidget* gtk_widget_get_toplevel(GtkWidget* widget) {
  check_thread();
  return widget;
}

GdkWindow* gtk_widget_get_window(GtkWidget* widget) {
  check_thread();
  return nullptr;
}

#if FLUTTER_LINUX_GTK4
GtkNative* gtk_widget_get_native(GtkWidget* widget) {
  check_thread();
  static GObject* mock_native = nullptr;
  if (mock_native == nullptr) {
    mock_native = G_OBJECT(g_object_new(G_TYPE_OBJECT, nullptr));
  }
  return reinterpret_cast<GtkNative*>(mock_native);
}

GdkSurface* gtk_native_get_surface(GtkNative* native) {
  check_thread();
  static FlMockGtk4Surface* mock_surface = nullptr;
  if (mock_surface == nullptr) {
    mock_surface = FL_MOCK_GTK4_SURFACE(
        g_object_new(fl_mock_gtk4_surface_get_type(), nullptr));
  }
  return reinterpret_cast<GdkSurface*>(mock_surface);
}
#endif  // FLUTTER_LINUX_GTK4

void gtk_im_context_set_client_window(GtkIMContext* context,
                                      GdkWindow* window) {
  check_thread();
  if (mock != nullptr) {
    mock->gtk_im_context_set_client_window(context, window);
  }
}

void gtk_im_context_get_preedit_string(GtkIMContext* context,
                                       gchar** str,
                                       PangoAttrList** attrs,
                                       gint* cursor_pos) {
  check_thread();
  if (mock != nullptr) {
    mock->gtk_im_context_get_preedit_string(context, str, attrs, cursor_pos);
  }
}

gboolean gtk_im_context_filter_keypress(GtkIMContext* context,
                                        GdkEventKey* event) {
  check_thread();
  if (mock == nullptr) {
    return TRUE;
  }

  return mock->gtk_im_context_filter_keypress(context, event);
}

void gtk_im_context_focus_in(GtkIMContext* context) {
  check_thread();
  if (mock != nullptr) {
    mock->gtk_im_context_focus_in(context);
  }
}

void gtk_im_context_focus_out(GtkIMContext* context) {
  check_thread();
  if (mock != nullptr) {
    mock->gtk_im_context_focus_out(context);
  }
}

void gtk_im_context_set_cursor_location(GtkIMContext* context,
                                        const GdkRectangle* area) {
  check_thread();
  if (mock != nullptr) {
    mock->gtk_im_context_set_cursor_location(context, area);
  }
}

void gtk_im_context_set_surrounding(GtkIMContext* context,
                                    const gchar* text,
                                    gint len,
                                    gint cursor_index) {
  check_thread();
  if (mock != nullptr) {
    mock->gtk_im_context_set_surrounding(context, text, len, cursor_index);
  }
}

GtkClipboard* gtk_clipboard_get_default(GdkDisplay* display) {
  check_thread();
  return nullptr;
}

void gtk_clipboard_set_text(GtkClipboard* clipboard,
                            const gchar* text,
                            gint len) {
  check_thread();
}

void gtk_clipboard_request_text(GtkClipboard* clipboard,
                                GtkClipboardTextReceivedFunc callback,
                                gpointer user_data) {
  check_thread();
}

void atk_object_notify_state_change(AtkObject* accessible,
                                    AtkState state,
                                    gboolean value) {
  check_thread();
  if (mock != nullptr) {
    mock->atk_object_notify_state_change(accessible, state, value);
  }
}

void g_object_set(gpointer object, const gchar* first_property_name, ...) {
  check_thread();
  if (first_property_name == nullptr) {
    return;
  }

  va_list args;
  va_start(args, first_property_name);

  const gchar* name = first_property_name;
  while (name != nullptr) {
    // Extract the value (as gint, works for enums like GtkInputPurpose and
    // GtkInputHints)
    gint value = va_arg(args, gint);

    // Check if this is a property we want to mock (input-purpose or
    // input-hints)
    if (mock != nullptr && (g_strcmp0(name, "input-purpose") == 0 ||
                            g_strcmp0(name, "input-hints") == 0)) {
      mock->g_object_set(G_OBJECT(object), name, value);
    }

    // Get next property name (or nullptr to terminate)
    name = va_arg(args, gchar*);
  }

  va_end(args);
}
