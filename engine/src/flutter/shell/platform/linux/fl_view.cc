// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

#if !FLUTTER_LINUX_GTK4
#include <atk/atk.h>
#endif
#if FLUTTER_LINUX_GTK4
#include <gdk/wayland/gdkwayland.h>
#else
#include <gdk/gdkwayland.h>
#endif
#if !FLUTTER_LINUX_GTK4
#include <gtk/gtk-a11y.h>
#endif

#include <cstring>

#include "flutter/common/constants.h"
#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_compositor_software.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_gtk.h"
#include "flutter/shell/platform/linux/fl_key_event.h"
#include "flutter/shell/platform/linux/fl_opengl_manager.h"
#include "flutter/shell/platform/linux/fl_plugin_registrar_private.h"
#include "flutter/shell/platform/linux/fl_pointer_manager.h"
#include "flutter/shell/platform/linux/fl_scrolling_manager.h"
#if FLUTTER_LINUX_GTK4
#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_render_texture_gtk4.h"
#include "flutter/shell/platform/linux/fl_view_gtk4_accessibility.h"
#endif
#include "flutter/shell/platform/linux/fl_touch_manager.h"
#if !FLUTTER_LINUX_GTK4
#include "flutter/shell/platform/linux/fl_accessible_node.h"
#include "flutter/shell/platform/linux/fl_socket_accessible.h"
#include "flutter/shell/platform/linux/fl_view_accessible.h"
#endif
#include "flutter/shell/platform/linux/fl_view_private.h"
#include "flutter/shell/platform/linux/fl_window_state_monitor.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_plugin_registry.h"

enum { SIGNAL_FIRST_FRAME, LAST_SIGNAL };

static guint fl_view_signals[LAST_SIGNAL];

static void fl_renderable_iface_init(FlRenderableInterface* iface);

static void fl_view_plugin_registry_iface_init(
    FlPluginRegistryInterface* iface);
static void handle_geometry_changed(FlView* self);
static void handle_geometry_changed_with_size(FlView* self,
                                              int width,
                                              int height);
#if FLUTTER_LINUX_GTK4
static gboolean retry_native_texture_cb(gpointer user_data);
static void fl_view_gtk4_update_accessible_name(FlView* self);
static void fl_view_gtk4_update_accessible_tree(FlView* self);
#endif

G_DEFINE_TYPE_WITH_CODE(
    FlView,
    fl_view,
    GTK_TYPE_BOX,
    G_IMPLEMENT_INTERFACE(fl_renderable_get_type(), fl_renderable_iface_init)
        G_IMPLEMENT_INTERFACE(fl_plugin_registry_get_type(),
                              fl_view_plugin_registry_iface_init))

#if FLUTTER_LINUX_GTK4
static void fl_view_gtk4_update_accessible_name(FlView* self) {
  if (self->accessibility_backend != nullptr) {
    fl_view_gtk4_accessibility_update_accessible_name(
        self->accessibility_backend);
  }
}

static void fl_view_gtk4_update_accessible_tree(FlView* self) {
  if (self->accessibility_backend != nullptr) {
    fl_view_gtk4_accessibility_update_accessible_tree(
        self->accessibility_backend);
  }
}
#endif

// Redraw the view from the GTK thread.
static gboolean redraw_cb(gpointer user_data) {
  g_autoptr(FlView) self = FL_VIEW(user_data);

  if (!self->have_first_frame) {
    self->have_first_frame = TRUE;
    g_signal_emit(self, fl_view_signals[SIGNAL_FIRST_FRAME], 0);
  }

  // If Flutter is controlling the window size, then resize the view if
  // necessary.
  gint scale_factor =
      gtk_widget_get_scale_factor(GTK_WIDGET(self->render_area));
  size_t width;
  size_t height;
#if FLUTTER_LINUX_GTK4
  width =
      static_cast<size_t>(gtk_widget_get_width(GTK_WIDGET(self->render_area))) *
      scale_factor;
  height = static_cast<size_t>(
               gtk_widget_get_height(GTK_WIDGET(self->render_area))) *
           scale_factor;
#else
  GtkAllocation allocation;
  gtk_widget_get_allocation(GTK_WIDGET(self->render_area), &allocation);
  width = allocation.width * scale_factor;
  height = allocation.height * scale_factor;
#endif
  size_t frame_width, frame_height;
  fl_compositor_get_frame_size(self->compositor, &frame_width, &frame_height);
  gboolean frame_size_matches = width == frame_width && height == frame_height;
  if (self->sized_to_content && !frame_size_matches) {
    gtk_widget_set_size_request(
        GTK_WIDGET(self->render_area),
        MAX(static_cast<gint>(frame_width / scale_factor), 1),
        MAX(static_cast<gint>(frame_height / scale_factor), 1));
#if FLUTTER_LINUX_GTK4
    GtkWidget* toplevel_window = fl_view_gtk4_get_toplevel_window(self);
    if (toplevel_window != nullptr) {
      gtk_window_set_default_size(
          GTK_WINDOW(toplevel_window),
          MAX(static_cast<gint>(frame_width / scale_factor), 1),
          MAX(static_cast<gint>(frame_height / scale_factor), 1));
    }
#else
    GtkWidget* toplevel =
        gtk_widget_get_toplevel(GTK_WIDGET(self->render_area));
    if (GTK_IS_WINDOW(toplevel)) {
      // Resize to smallest size, so that the window will shrink to fit the new
      // size of the render area.
      gtk_window_resize(GTK_WINDOW(toplevel), 1, 1);
    }
#endif
    return G_SOURCE_REMOVE;
  }

#if FLUTTER_LINUX_GTK4
  if (!self->sized_to_content && !frame_size_matches && width > 1 &&
      height > 1) {
    handle_geometry_changed(self);
    return G_SOURCE_REMOVE;
  }
#endif

#if FLUTTER_LINUX_GTK4
  if (width == 0 || height == 0) {
    if (self->native_texture_retry_source_id == 0) {
      self->native_texture_retry_source_id =
          g_timeout_add_full(G_PRIORITY_DEFAULT, 16, retry_native_texture_cb,
                             g_object_ref(self), g_object_unref);
    }
    return G_SOURCE_REMOVE;
  }

  g_autoptr(GdkTexture) texture = nullptr;
  FlGdkSurface* surface =
      fl_gtk_widget_get_surface(GTK_WIDGET(self->render_area));
  if (surface != nullptr) {
    GdkGLContext* old_gl_context = gdk_gl_context_get_current();
    if (self->render_context != nullptr) {
      gdk_gl_context_make_current(self->render_context);
    }

    texture = fl_compositor_acquire_texture(
        self->compositor, surface, self->render_context, width, height,
        !self->sized_to_content || !self->native_texture_ready);

    if (gdk_gl_context_get_current() != old_gl_context) {
      gdk_gl_context_clear_current();
    }

    if (texture != nullptr && FL_IS_RENDER_TEXTURE_GTK4(self->render_area)) {
      fl_render_texture_gtk4_set_flip_y(
          FL_RENDER_TEXTURE_GTK4(self->render_area),
          self->render_context != nullptr);
      fl_render_texture_gtk4_set_texture(
          FL_RENDER_TEXTURE_GTK4(self->render_area), texture);
      self->native_texture_ready = TRUE;
      if (self->native_texture_retry_source_id != 0) {
        g_source_remove(self->native_texture_retry_source_id);
        self->native_texture_retry_source_id = 0;
      }
    } else if (!self->native_texture_ready &&
               self->native_texture_retry_source_id == 0) {
      self->native_texture_retry_source_id =
          g_timeout_add_full(G_PRIORITY_DEFAULT, 16, retry_native_texture_cb,
                             g_object_ref(self), g_object_unref);
    }
  }
#else
  gtk_widget_queue_draw(GTK_WIDGET(self->render_area));
#endif

  return G_SOURCE_REMOVE;
}

#if FLUTTER_LINUX_GTK4
static gboolean retry_native_texture_cb(gpointer user_data) {
  FlView* self = FL_VIEW(user_data);
  self->native_texture_retry_source_id = 0;
  redraw_cb(g_object_ref(self));
  return G_SOURCE_REMOVE;
}
#endif

// Signal handler for GtkWidget::delete-event / GtkWindow::close-request.
static gboolean window_delete_event_cb(FlView* self) {
  fl_engine_request_app_exit(self->engine);
  // Stop the event from propagating.
  return TRUE;
}

static void init_scrolling(FlView* self) {
  g_clear_object(&self->scrolling_manager);
  self->scrolling_manager =
      fl_scrolling_manager_new(self->engine, self->view_id);
}

static void init_touch(FlView* self) {
  g_clear_object(&self->touch_manager);
  self->touch_manager = fl_touch_manager_new(self->engine, self->view_id);
}

// Called when the mouse cursor changes.
static void cursor_changed_cb(FlView* self) {
  FlMouseCursorHandler* handler =
      fl_engine_get_mouse_cursor_handler(self->engine);
  const gchar* cursor_name = fl_mouse_cursor_handler_get_cursor_name(handler);
#if FLUTTER_LINUX_GTK4
  fl_view_gtk4_set_cursor(self, cursor_name);
#else
  GdkWindow* window =
      gtk_widget_get_window(gtk_widget_get_toplevel(GTK_WIDGET(self)));
  g_autoptr(GdkCursor) cursor =
      gdk_cursor_new_from_name(gdk_window_get_display(window), cursor_name);
  gdk_window_set_cursor(window, cursor);
#endif
}

// Set the mouse cursor.
static void setup_cursor(FlView* self) {
  FlMouseCursorHandler* handler =
      fl_engine_get_mouse_cursor_handler(self->engine);

  self->cursor_changed_cb_id = g_signal_connect_object(
      handler, "cursor-changed", G_CALLBACK(cursor_changed_cb), self,
      G_CONNECT_SWAPPED);
  cursor_changed_cb(self);
}

// Updates the engine with the current window metrics.
static void handle_geometry_changed_with_size(FlView* self,
                                              int width,
                                              int height) {
  // No updates required when size controlled by Flutter.
  if (self->sized_to_content) {
    return;
  }

  double scale = fl_gtk_widget_get_scale(GTK_WIDGET(self));
  bool size_is_in_pixels = false;
  if (width == 0 || height == 0) {
    // Try to fall back to the toplevel surface size if available.
    FlGdkSurface* surface = fl_gtk_widget_get_surface(GTK_WIDGET(self));
    if (surface != nullptr) {
      width = fl_gtk_surface_get_width(surface);
      height = fl_gtk_surface_get_height(surface);
      scale = fl_gtk_surface_get_scale(surface);
      size_is_in_pixels = true;
    }
    if (width == 0 || height == 0) {
      return;
    }
  }

  // Note we can't detect if a window is moved between monitors - this
  // information is provided by Wayland but GTK only notifies us if the scale
  // has changed, so moving between two monitors of the same scale doesn't
  // provide any information.

  FlGdkSurface* surface = fl_gtk_widget_get_surface(GTK_WIDGET(self));
  // NOTE(robert-ancell) If we haven't got a window we default to display 0.
  // This is probably indicating a problem with this code in that we
  // shouldn't be generating anything until the window is created.
  // Another event with the correct display ID is generated soon after.
  // I haven't changed this code in case there are side-effects but we
  // probably shouldn't call handle_geometry_changed after the view is
  // added but only when the window is realized.
  FlutterEngineDisplayId display_id = 0;
  if (surface != nullptr) {
    GdkDisplay* display = fl_gtk_surface_get_display(surface);
    GdkMonitor* monitor =
        fl_gtk_display_get_monitor_at_surface(display, surface);
    display_id = fl_display_monitor_get_display_id(
        fl_engine_get_display_monitor(self->engine), monitor);
  }
  size_t min_width =
      size_is_in_pixels ? width : fl_gtk_size_to_pixels(width, scale);
  size_t min_height =
      size_is_in_pixels ? height : fl_gtk_size_to_pixels(height, scale);
  size_t max_width = min_width;
  size_t max_height = min_height;
  fl_engine_send_window_metrics_event(self->engine, display_id, self->view_id,
                                      min_width, min_height, max_width,
                                      max_height, scale);
}

static void handle_geometry_changed(FlView* self) {
#if FLUTTER_LINUX_GTK4
  int width = gtk_widget_get_width(GTK_WIDGET(self->render_area));
  int height = gtk_widget_get_height(GTK_WIDGET(self->render_area));
  handle_geometry_changed_with_size(self, width, height);
#else
  GtkAllocation allocation;
  gtk_widget_get_allocation(GTK_WIDGET(self), &allocation);
  handle_geometry_changed_with_size(self, allocation.width, allocation.height);
#endif
}

static void view_added_cb(GObject* object,
                          GAsyncResult* result,
                          gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  if (!fl_engine_add_view_finish(FL_ENGINE(object), result, &error)) {
    if (g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
      return;
    }

    g_warning("Failed to add view: %s", error->message);
    // FIXME: Show on the GLArea
    return;
  }
}

// Called when the engine updates accessibility.
static void update_semantics_cb(FlView* self,
                                const FlutterSemanticsUpdate2* update) {
  // A semantics update is routed to a particular view.
  if (update->view_id != self->view_id) {
    return;
  }

#if !FLUTTER_LINUX_GTK4
  fl_view_accessible_handle_update_semantics(self->view_accessible, update);
#else
  if (self->accessibility_backend != nullptr) {
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
    fl_view_gtk4_accessibility_handle_native_update(self->accessibility_backend,
                                                    update);
#else
    fl_view_gtk4_accessibility_handle_update(self->accessibility_backend,
                                             update);
#endif
  }
#endif
}

// Invoked by the engine right before the engine is restarted.
//
// This method should reset states to be as if the engine had just been started,
// which usually indicates the user has requested a hot restart (Shift-R in the
// Flutter CLI.)
static void on_pre_engine_restart_cb(FlView* self) {
  init_scrolling(self);
  init_touch(self);
}

// Implements FlRenderable::present_layers
static void fl_view_present_layers(FlRenderable* renderable,
                                   const FlutterLayer** layers,
                                   size_t layers_count) {
  FlView* self = FL_VIEW(renderable);

  fl_compositor_present_layers(self->compositor, layers, layers_count);

  // Perform the redraw in the GTK thead.
  g_idle_add(redraw_cb, g_object_ref(self));
}

// Implements FlPluginRegistry::get_registrar_for_plugin.
static FlPluginRegistrar* fl_view_get_registrar_for_plugin(
    FlPluginRegistry* registry,
    const gchar* name) {
  FlView* self = FL_VIEW(registry);

  return fl_plugin_registrar_new(self,
                                 fl_engine_get_binary_messenger(self->engine),
                                 fl_engine_get_texture_registrar(self->engine));
}

static void fl_renderable_iface_init(FlRenderableInterface* iface) {
  iface->present_layers = fl_view_present_layers;
}

static void fl_view_plugin_registry_iface_init(
    FlPluginRegistryInterface* iface) {
  iface->get_registrar_for_plugin = fl_view_get_registrar_for_plugin;
}

static void setup_opengl(FlView* self) {
  g_autoptr(GError) error = nullptr;

  FlGdkSurface* surface =
      fl_gtk_widget_get_surface(GTK_WIDGET(self->render_area));
  if (surface == nullptr) {
    return;
  }
  self->render_context = fl_gtk_surface_create_gl_context(surface, &error);
  if (self->render_context == nullptr) {
    g_warning("Failed to create OpenGL context: %s", error->message);
    return;
  }

  if (!gdk_gl_context_realize(self->render_context, &error)) {
    g_warning("Failed to realize OpenGL context: %s", error->message);
    return;
  }

  // If using Wayland, then EGL is in use and we can access the frame
  // from the Flutter context using EGLImage. If not (i.e. X11 using GLX)
  // then we have to copy the texture via the CPU.
  gboolean shareable =
      GDK_IS_WAYLAND_DISPLAY(fl_gtk_surface_get_display(surface));
  self->compositor = FL_COMPOSITOR(fl_compositor_opengl_new(
      fl_engine_get_task_runner(self->engine),
      fl_engine_get_opengl_manager(self->engine), shareable));
}

static void setup_software(FlView* self) {
  self->compositor = FL_COMPOSITOR(
      fl_compositor_software_new(fl_engine_get_task_runner(self->engine)));
}

static void realize_cb(FlView* self) {
  switch (fl_engine_get_renderer_type(self->engine)) {
    case kOpenGL:
      setup_opengl(self);
      break;
    case kSoftware:
      setup_software(self);
      break;
    default:
      break;
  }

  if (self->view_id != flutter::kFlutterImplicitViewId) {
    setup_cursor(self);
    return;
  }

#if FLUTTER_LINUX_GTK4
  GtkWidget* toplevel_window = fl_view_gtk4_get_toplevel_window(self);
#else
  GtkWidget* toplevel_window = gtk_widget_get_toplevel(GTK_WIDGET(self));
#endif

  self->window_state_monitor =
      fl_window_state_monitor_new(fl_engine_get_binary_messenger(self->engine),
                                  GTK_WINDOW(toplevel_window));

#if FLUTTER_LINUX_GTK4
  // Handle requests by the user to close the application.
  g_signal_connect_swapped(toplevel_window, "close-request",
                           G_CALLBACK(window_delete_event_cb), self);
#else
  // Handle requests by the user to close the application.
  g_signal_connect_swapped(toplevel_window, "delete-event",
                           G_CALLBACK(window_delete_event_cb), self);
#endif

  // Flutter engine will need to make the context current from raster thread
  // during initialization.
  fl_opengl_manager_clear_current(fl_engine_get_opengl_manager(self->engine));

  g_autoptr(GError) error = nullptr;
  if (!fl_engine_start(self->engine, &error)) {
    g_warning("Failed to start Flutter engine: %s", error->message);
    return;
  }

  setup_cursor(self);

  handle_geometry_changed(self);
}

#if !FLUTTER_LINUX_GTK4
static void size_allocate_cb(FlView* self) {
  handle_geometry_changed(self);
}
#endif

#if FLUTTER_LINUX_GTK4
static void resize_cb(FlView* self, int width, int height) {
  handle_geometry_changed_with_size(self, width, height);
}
#endif

#if !FLUTTER_LINUX_GTK4
static void paint_background(FlView* self, cairo_t* cr) {
  // Don't bother drawing if fully transparent - the widget above this will
  // already be drawn by GTK.
  if (self->background_color->red == 0 && self->background_color->green == 0 &&
      self->background_color->blue == 0 && self->background_color->alpha == 0) {
    return;
  }

  gdk_cairo_set_source_rgba(cr, self->background_color);
  cairo_paint(cr);
}

static gboolean draw_cb(FlView* self, cairo_t* cr) {
  paint_background(self, cr);

  if (self->render_context) {
    gdk_gl_context_make_current(self->render_context);
  }

  gboolean wait_for_frame = !self->sized_to_content;
  FlGdkSurface* render_surface =
      fl_gtk_widget_get_surface(GTK_WIDGET(self->render_area));
  gboolean result = fl_compositor_render(self->compositor, cr, render_surface,
                                         wait_for_frame);

  if (self->render_context) {
    gdk_gl_context_clear_current();
  }

  return result;
}
#endif

static void fl_view_notify(GObject* object, GParamSpec* pspec) {
  FlView* self = FL_VIEW(object);

  if (strcmp(pspec->name, "scale-factor") == 0) {
    handle_geometry_changed(self);
  }

  if (G_OBJECT_CLASS(fl_view_parent_class)->notify != nullptr) {
    G_OBJECT_CLASS(fl_view_parent_class)->notify(object, pspec);
  }
}

static void fl_view_dispose(GObject* object) {
  FlView* self = FL_VIEW(object);

  g_cancellable_cancel(self->cancellable);

#if FLUTTER_LINUX_GTK4
  if (self->render_area != nullptr) {
    if (self->zoom_gesture != nullptr) {
      gtk_widget_remove_controller(GTK_WIDGET(self->render_area),
                                   GTK_EVENT_CONTROLLER(self->zoom_gesture));
    }
    if (self->rotate_gesture != nullptr) {
      gtk_widget_remove_controller(GTK_WIDGET(self->render_area),
                                   GTK_EVENT_CONTROLLER(self->rotate_gesture));
    }
  }
#endif
  g_clear_object(&self->zoom_gesture);
  g_clear_object(&self->rotate_gesture);
  if (self->engine != nullptr &&
      self->view_id != flutter::kFlutterImplicitViewId) {
    FlMouseCursorHandler* handler =
        fl_engine_get_mouse_cursor_handler(self->engine);
    if (self->cursor_changed_cb_id != 0) {
      g_signal_handler_disconnect(handler, self->cursor_changed_cb_id);
      self->cursor_changed_cb_id = 0;
    }

    // The implicit view is owned by the engine and cannot be removed through
    // the embedder RemoveView API. Only views created with AddView need
    // releasing. This matches the embedder API contract and avoids a
    // pre-existing shutdown warning in the Linux shell.
    fl_engine_remove_view(self->engine, self->view_id, nullptr, nullptr,
                          nullptr);
  }

  g_clear_object(&self->render_context);
  g_clear_object(&self->engine);
  g_clear_object(&self->compositor);
  g_clear_pointer(&self->background_color, gdk_rgba_free);
  g_clear_object(&self->window_state_monitor);
  g_clear_object(&self->scrolling_manager);
  g_clear_object(&self->pointer_manager);
  g_clear_object(&self->touch_manager);
#if !FLUTTER_LINUX_GTK4
  g_clear_object(&self->view_accessible);
#else
  fl_view_gtk4_accessibility_dispose(self->accessibility_backend);
  self->accessibility_backend = nullptr;
  if (self->native_texture_retry_source_id != 0) {
    g_source_remove(self->native_texture_retry_source_id);
    self->native_texture_retry_source_id = 0;
  }
#endif
  g_clear_object(&self->cancellable);

  G_OBJECT_CLASS(fl_view_parent_class)->dispose(object);
}

// Implements GtkWidget::realize.
static void fl_view_realize(GtkWidget* widget) {
  GTK_WIDGET_CLASS(fl_view_parent_class)->realize(widget);

  // Realize the child widgets.
  gtk_widget_realize(GTK_WIDGET(FL_VIEW(widget)->render_area));
}

// GTK3 event handling.
#if !FLUTTER_LINUX_GTK4
static gboolean handle_key_event(FlView* self, GdkEventKey* key_event) {
  g_autoptr(FlKeyEvent) event = fl_key_event_new_from_gdk_event(
      gdk_event_copy(reinterpret_cast<GdkEvent*>(key_event)));

  fl_keyboard_manager_handle_event(
      fl_engine_get_keyboard_manager(self->engine), event, self->cancellable,
      [](GObject* object, GAsyncResult* result, gpointer user_data) {
        FlView* self = FL_VIEW(user_data);

        g_autoptr(FlKeyEvent) redispatch_event = nullptr;
        g_autoptr(GError) error = nullptr;
        if (!fl_keyboard_manager_handle_event_finish(
                FL_KEYBOARD_MANAGER(object), result, &redispatch_event,
                &error)) {
          if (g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
            return;
          }

          g_warning("Failed to handle key event: %s", error->message);
        }

        if (redispatch_event != nullptr) {
          if (!fl_text_input_handler_filter_keypress(
                  fl_engine_get_text_input_handler(self->engine),
                  redispatch_event)) {
            fl_keyboard_manager_add_redispatched_event(
                fl_engine_get_keyboard_manager(self->engine), redispatch_event);
            gdk_event_put(fl_key_event_get_origin(redispatch_event));
          }
        }
      },
      self);

  return TRUE;
}

// Implements GtkWidget::key_press_event.
static gboolean fl_view_focus_in_event(GtkWidget* widget,
                                       GdkEventFocus* event) {
  FlView* self = FL_VIEW(widget);
  fl_text_input_handler_set_widget(
      fl_engine_get_text_input_handler(self->engine), widget);
  return FALSE;
}

// Implements GtkWidget::key_press_event.
static gboolean fl_view_key_press_event(GtkWidget* widget,
                                        GdkEventKey* key_event) {
  FlView* self = FL_VIEW(widget);
  return handle_key_event(self, key_event);
}

// Implements GtkWidget::key_release_event.
static gboolean fl_view_key_release_event(GtkWidget* widget,
                                          GdkEventKey* key_event) {
  FlView* self = FL_VIEW(widget);
  return handle_key_event(self, key_event);
}
#endif

static void fl_view_class_init(FlViewClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->notify = fl_view_notify;
  object_class->dispose = fl_view_dispose;

  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  widget_class->realize = fl_view_realize;
#if !FLUTTER_LINUX_GTK4
  widget_class->focus_in_event = fl_view_focus_in_event;
  widget_class->key_press_event = fl_view_key_press_event;
  widget_class->key_release_event = fl_view_key_release_event;
#else
#if GTK_CHECK_VERSION(4, 0, 0)
  gtk_widget_class_set_accessible_role(widget_class, GTK_ACCESSIBLE_ROLE_GROUP);
#endif
#endif

  fl_view_signals[SIGNAL_FIRST_FRAME] =
      g_signal_new("first-frame", fl_view_get_type(), G_SIGNAL_RUN_LAST, 0,
                   NULL, NULL, NULL, G_TYPE_NONE, 0);

#if !FLUTTER_LINUX_GTK4
  gtk_widget_class_set_accessible_type(GTK_WIDGET_CLASS(klass),
                                       fl_socket_accessible_get_type());
#endif
}

// Engine related construction.
static void setup_engine(FlView* self) {
#if !FLUTTER_LINUX_GTK4
  self->view_accessible = fl_view_accessible_new(self->engine, self->view_id);
  fl_socket_accessible_embed(
      FL_SOCKET_ACCESSIBLE(gtk_widget_get_accessible(GTK_WIDGET(self))),
      atk_plug_get_id(ATK_PLUG(self->view_accessible)));
#else
  self->accessibility_backend =
      fl_view_gtk4_accessibility_new(self, self->view_id);
#endif

  self->pointer_manager = fl_pointer_manager_new(self->view_id, self->engine);

  init_scrolling(self);
  init_touch(self);

  g_signal_connect_object(self->engine, "on-pre-engine-restart",
                          G_CALLBACK(on_pre_engine_restart_cb), self,
                          G_CONNECT_SWAPPED);
  g_signal_connect_object(self->engine, "update-semantics",
                          G_CALLBACK(update_semantics_cb), self,
                          G_CONNECT_SWAPPED);
}

static void fl_view_init(FlView* self) {
  self->cancellable = g_cancellable_new();

  gtk_widget_set_can_focus(GTK_WIDGET(self), TRUE);

  self->view_id = -1;

  GdkRGBA default_background = {
      .red = 0.0, .green = 0.0, .blue = 0.0, .alpha = 1.0};
  self->background_color = gdk_rgba_copy(&default_background);

#if FLUTTER_LINUX_GTK4
  self->render_area = fl_render_texture_gtk4_new();
  fl_view_gtk4_update_accessible_name(self);
#else
  self->render_area = GTK_WIDGET(gtk_drawing_area_new());
#endif
  gtk_widget_set_hexpand(GTK_WIDGET(self->render_area), TRUE);
  gtk_widget_set_vexpand(GTK_WIDGET(self->render_area), TRUE);
#if FLUTTER_LINUX_GTK4
  fl_view_gtk4_setup(self);
  fl_view_gtk4_update_accessible_tree(self);
#else
  fl_view_gtk3_setup(self);
#endif
#if FLUTTER_LINUX_GTK4
  gtk_widget_set_visible(GTK_WIDGET(self->render_area), TRUE);
#else
  gtk_widget_show(GTK_WIDGET(self->render_area));
#endif
  g_signal_connect_swapped(self->render_area, "realize", G_CALLBACK(realize_cb),
                           self);
#if FLUTTER_LINUX_GTK4
  g_signal_connect_swapped(self->render_area, "resize", G_CALLBACK(resize_cb),
                           self);
#else
  g_signal_connect_swapped(self->render_area, "size-allocate",
                           G_CALLBACK(size_allocate_cb), self);
#endif
#if !FLUTTER_LINUX_GTK4
  g_signal_connect_swapped(self->render_area, "draw", G_CALLBACK(draw_cb),
                           self);
#endif
}

G_MODULE_EXPORT FlView* fl_view_new(FlDartProject* project) {
  g_autoptr(FlEngine) engine = fl_engine_new(project);
  FlView* self = FL_VIEW(g_object_new(fl_view_get_type(), nullptr));

  self->view_id = flutter::kFlutterImplicitViewId;
  self->engine = FL_ENGINE(g_object_ref(engine));

  setup_engine(self);

  fl_engine_set_implicit_view(engine, FL_RENDERABLE(self));

  return self;
}

G_MODULE_EXPORT FlView* fl_view_new_for_engine(FlEngine* engine) {
  FlView* self = FL_VIEW(g_object_new(fl_view_get_type(), nullptr));

  self->engine = FL_ENGINE(g_object_ref(engine));

  size_t min_width = 1, min_height = 1, max_width = 1, max_height = 1;
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  self->view_id = fl_engine_add_view(
      engine, FL_RENDERABLE(self), min_width, min_height, max_width, max_height,
      scale_factor, self->cancellable, view_added_cb, self);

  setup_engine(self);

  return self;
}

G_MODULE_EXPORT FlView* fl_view_new_sized_to_content(FlEngine* engine) {
  FlView* self = FL_VIEW(g_object_new(fl_view_get_type(), nullptr));

  self->engine = FL_ENGINE(g_object_ref(engine));

  self->sized_to_content = TRUE;
  size_t min_width = 1, min_height = 1, max_width = G_MAXSIZE,
         max_height = G_MAXSIZE;
  gint scale_factor = gtk_widget_get_scale_factor(GTK_WIDGET(self));
  self->view_id = fl_engine_add_view(
      engine, FL_RENDERABLE(self), min_width, min_height, max_width, max_height,
      scale_factor, self->cancellable, view_added_cb, self);

  setup_engine(self);

  return self;
}

G_MODULE_EXPORT FlEngine* fl_view_get_engine(FlView* self) {
  g_return_val_if_fail(FL_IS_VIEW(self), nullptr);
  return self->engine;
}

G_MODULE_EXPORT
int64_t fl_view_get_id(FlView* self) {
  g_return_val_if_fail(FL_IS_VIEW(self), -1);
  return self->view_id;
}

G_MODULE_EXPORT void fl_view_set_background_color(FlView* self,
                                                  const GdkRGBA* color) {
  g_return_if_fail(FL_IS_VIEW(self));
  gdk_rgba_free(self->background_color);
  self->background_color = gdk_rgba_copy(color);
}

#if !FLUTTER_LINUX_GTK4
FlViewAccessible* fl_view_get_accessible(FlView* self) {
  g_return_val_if_fail(FL_IS_VIEW(self), nullptr);
  return self->view_accessible;
}
#endif
