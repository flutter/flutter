// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_windowing.h"
#include "flutter/shell/platform/common/isolate_scope.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"

typedef struct {
  GWeakRef engine;
  GHashTable* windows_by_view_id;
} FlWindowingControllerPrivate;

struct FlutterWindowCreationRequest {
  double width;
  double height;
  double min_width;
  double min_height;
  double max_width;
  double max_height;
  void (*on_close)();
  void (*on_size_change)();
};

G_DEFINE_TYPE_WITH_PRIVATE(FlWindowingController,
                           fl_windowing_controller,
                           G_TYPE_OBJECT)

typedef struct {
  GtkWindow* window;
  FlView* view;
  guint delete_id;
  guint size_allocate_id;
  void (*on_close)();
  void (*on_size_change)();
  flutter::Isolate* isolate;
} WindowData;

static WindowData* window_data_new(GtkWindow* window, FlView* view) {
  WindowData* data = g_new0(WindowData, 1);
  data->window = GTK_WINDOW(g_object_ref(window));
  data->view = FL_VIEW(g_object_ref(view));
  data->isolate = new flutter::Isolate();
  return data;
}

static void window_data_free(WindowData* data) {
  g_signal_handler_disconnect(data->window, data->delete_id);
  g_signal_handler_disconnect(data->window, data->size_allocate_id);
  g_object_unref(data->window);
  g_object_unref(data->view);
  delete data->isolate;
  g_free(data);
}

static void fl_windowing_controller_dispose(GObject* object) {
  G_OBJECT_CLASS(fl_windowing_controller_parent_class)->dispose(object);

  FlWindowingController* self = FL_WINDOWING_CONTROLLER(object);
  FlWindowingControllerPrivate* priv =
      reinterpret_cast<FlWindowingControllerPrivate*>(
          fl_windowing_controller_get_instance_private(self));

  g_weak_ref_clear(&priv->engine);
  g_clear_pointer(&priv->windows_by_view_id, g_hash_table_unref);
}

static void fl_windowing_controller_class_init(
    FlWindowingControllerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_windowing_controller_dispose;
}

static void fl_windowing_controller_init(FlWindowingController* self) {
  FlWindowingControllerPrivate* priv =
      reinterpret_cast<FlWindowingControllerPrivate*>(
          fl_windowing_controller_get_instance_private(self));
  priv->windows_by_view_id =
      g_hash_table_new_full(g_direct_hash, g_direct_equal, nullptr,
                            reinterpret_cast<GDestroyNotify>(window_data_free));
}

FlWindowingController* fl_windowing_controller_new(FlEngine* engine) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);

  FlWindowingController* self = FL_WINDOWING_CONTROLLER(
      g_object_new(fl_windowing_controller_get_type(), nullptr));
  FlWindowingControllerPrivate* priv =
      reinterpret_cast<FlWindowingControllerPrivate*>(
          fl_windowing_controller_get_instance_private(self));

  g_weak_ref_init(&priv->engine, engine);

  return self;
}

static gboolean on_window_delete(GtkWidget* widget,
                                 GdkEvent* event,
                                 gpointer user_data) {
  WindowData* data = static_cast<WindowData*>(user_data);
  if (data->on_close) {
    flutter::IsolateScope isolate_scope(*data->isolate);
    data->on_close();
  }
  return TRUE;
}

static gboolean on_size_allocate(GtkWidget* widget,
                                 GdkRectangle* allocation,
                                 gpointer user_data) {
  WindowData* data = static_cast<WindowData*>(user_data);
  if (data->on_size_change) {
    flutter::IsolateScope isolate_scope(*data->isolate);
    data->on_size_change();
  }
  return FALSE;
}

static int64_t fl_windowing_controller_create_regular_window(
    FlWindowingController* self,
    const FlutterWindowCreationRequest* request) {
  FlWindowingControllerPrivate* priv =
      reinterpret_cast<FlWindowingControllerPrivate*>(
          fl_windowing_controller_get_instance_private(self));
  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&priv->engine));
  g_return_val_if_fail(engine != nullptr, 0);

  FlView* view = fl_view_new_for_engine(engine);
  gtk_widget_show(GTK_WIDGET(view));

  GtkWidget* window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  gtk_window_set_default_size(GTK_WINDOW(window), request->width,
                              request->height);

  WindowData* data = window_data_new(GTK_WINDOW(window), view);

  data->delete_id = g_signal_connect(window, "delete-event",
                                     G_CALLBACK(on_window_delete), data);
  data->size_allocate_id = g_signal_connect(window, "size-allocate",
                                            G_CALLBACK(on_size_allocate), data);
  data->on_close = request->on_close;
  data->on_size_change = request->on_size_change;

  GdkGeometry geometry;

  GdkWindowHints geometry_mask = static_cast<GdkWindowHints>(0);
  if (request->min_width != 0 && request->min_height != 0) {
    geometry.min_width = request->min_width;
    geometry.min_height = request->min_height;
    geometry_mask =
        static_cast<GdkWindowHints>(geometry_mask | GDK_HINT_MIN_SIZE);
  }
  if (request->max_width != 0 && request->max_height != 0) {
    geometry.max_width = request->max_width;
    geometry.max_height = request->max_height;
    geometry_mask =
        static_cast<GdkWindowHints>(geometry_mask | GDK_HINT_MAX_SIZE);
  }
  if (geometry_mask != 0) {
    gtk_window_set_geometry_hints(GTK_WINDOW(window), nullptr, &geometry,
                                  geometry_mask);
  }

  // Make the resources for the view so rendering can start.
  // We'll show the view when we have the first frame.
  gtk_widget_realize(GTK_WIDGET(view));

  // TODO(knopp): Do this when we have content rendered.
  gtk_widget_show(window);

  g_hash_table_insert(priv->windows_by_view_id,
                      GINT_TO_POINTER(fl_view_get_id(view)), data);

  return fl_view_get_id(view);
}

static void fl_windowing_controller_destroy_window(FlWindowingController* self,
                                                   int64_t view_id) {
  FlWindowingControllerPrivate* priv =
      reinterpret_cast<FlWindowingControllerPrivate*>(
          fl_windowing_controller_get_instance_private(self));
  WindowData* data = static_cast<WindowData*>(
      g_hash_table_lookup(priv->windows_by_view_id, GINT_TO_POINTER(view_id)));
  if (data == nullptr) {
    return;
  }
  gtk_widget_destroy(GTK_WIDGET(data->window));
  g_hash_table_remove(priv->windows_by_view_id, GINT_TO_POINTER(view_id));
}

static WindowData* get_window_data(FlWindowingController* self,
                                   int64_t view_id) {
  FlWindowingControllerPrivate* priv =
      reinterpret_cast<FlWindowingControllerPrivate*>(
          fl_windowing_controller_get_instance_private(self));
  return static_cast<WindowData*>(
      g_hash_table_lookup(priv->windows_by_view_id, GINT_TO_POINTER(view_id)));
}

extern "C" {
// NOLINTBEGIN(google-objc-function-naming)

G_MODULE_EXPORT
int64_t flutter_create_regular_window(
    int64_t engine_id,
    const FlutterWindowCreationRequest* request) {
  FlEngine* engine = fl_engine_for_id(engine_id);
  FlWindowingController* controller =
      fl_engine_get_windowing_controller(engine);
  return fl_windowing_controller_create_regular_window(controller, request);
}

G_MODULE_EXPORT
void* flutter_get_window_handle(int64_t engine_id, int64_t view_id) {
  FlEngine* engine = fl_engine_for_id(engine_id);
  FlWindowingController* controller =
      fl_engine_get_windowing_controller(engine);
  WindowData* data = get_window_data(controller, view_id);
  if (data == nullptr) {
    return 0;
  }
  return data->window;
}

struct FlutterWindowSize {
  double width;
  double height;
};

G_MODULE_EXPORT
void flutter_get_window_size(void* window, FlutterWindowSize* size) {
  GtkWindow* gtk_window = GTK_WINDOW(window);
  gint width, height;
  gtk_window_get_size(gtk_window, &width, &height);
  size->width = width;
  size->height = height;
}

G_MODULE_EXPORT
int64_t flutter_get_window_state(void* window) {
  GtkWindow* gtk_window = GTK_WINDOW(window);
  GdkWindowState window_state =
      gdk_window_get_state(gtk_widget_get_window(GTK_WIDGET(gtk_window)));
  if (window_state & GDK_WINDOW_STATE_ICONIFIED) {
    return 2;
  }
  if (gtk_window_is_maximized(gtk_window)) {
    return 1;
  }
  return 0;
}

G_MODULE_EXPORT
void flutter_set_window_state(void* window, int64_t state) {
  GtkWindow* gtk_window = GTK_WINDOW(window);
  GdkWindowState window_state;
  switch (state) {
    case 0:
      if (gtk_window_is_maximized(gtk_window)) {
        gtk_window_unmaximize(gtk_window);
      }
      window_state =
          gdk_window_get_state(gtk_widget_get_window(GTK_WIDGET(window)));
      if (window_state & GDK_WINDOW_STATE_ICONIFIED) {
        gtk_window_deiconify(gtk_window);
      }
      break;
    case 1:
      gtk_window_maximize(gtk_window);
      break;
    case 2:
      gtk_window_iconify(gtk_window);
      break;
  }
}

G_MODULE_EXPORT
void flutter_destroy_window(int64_t engine_id, int64_t view_id) {
  FlEngine* engine = fl_engine_for_id(engine_id);
  FlWindowingController* controller =
      fl_engine_get_windowing_controller(engine);
  fl_windowing_controller_destroy_window(controller, view_id);
}

// NOLINTEND(google-objc-function-naming)
}
