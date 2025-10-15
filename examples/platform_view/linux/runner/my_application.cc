// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;

  char** dart_entrypoint_arguments;

  // Channel to receive platform view requests from Flutter.
  FlMethodChannel* platform_view_channel;

  // Main window.
  GtkWindow* window;

  // Current counter.
  int64_t counter;

  // Request in progress.
  FlMethodCall* method_call;

  // Native window requested by Flutter.
  GtkWindow* native_window;

  // Label to show count.
  GtkLabel* counter_label;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void update_counter_label(MyApplication* self) {
  g_autofree gchar* text =
      g_strdup_printf("Button tapped %" G_GINT64_FORMAT " %s.", self->counter,
                      self->counter == 1 ? "time" : "times");
  gtk_label_set_text(self->counter_label, text);
}

static void button_clicked_cb(MyApplication* self) {
  self->counter++;
  update_counter_label(self);
}

static void native_window_delete_event_cb(MyApplication* self,
                                          gint response_id) {
  g_autoptr(FlValue) counter_value = fl_value_new_int(self->counter);
  fl_method_call_respond_success(self->method_call, counter_value, nullptr);
  g_clear_object(&self->method_call);
}

// Handle request to switch the view.
static void handle_switch_view(MyApplication* self, FlMethodCall* method_call) {
  FlValue* counter_value = fl_method_call_get_args(method_call);
  if (fl_value_get_type(counter_value) != FL_VALUE_TYPE_INT) {
    fl_method_call_respond_error(self->method_call, "Invalid args",
                                 "Invalid switchView args", nullptr, nullptr);
    return;
  }

  self->counter = fl_value_get_int(counter_value);
  self->method_call = FL_METHOD_CALL(g_object_ref(method_call));

  // Show the same UI in a native window.
  self->native_window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_window_set_transient_for(self->native_window, self->window);
  gtk_window_set_modal(self->native_window, TRUE);
  gtk_window_set_destroy_with_parent(self->native_window, TRUE);
  g_signal_connect_swapped(self->native_window, "delete-event",
                           G_CALLBACK(native_window_delete_event_cb), self);

  GtkWidget* box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 12);
  gtk_widget_set_margin_start(box, 24);
  gtk_widget_set_margin_end(box, 24);
  gtk_widget_set_margin_top(box, 24);
  gtk_widget_set_margin_bottom(box, 24);
  gtk_widget_show(box);
  gtk_container_add(GTK_CONTAINER(self->native_window), box);

  self->counter_label = GTK_LABEL(gtk_label_new(""));
  gtk_widget_show(GTK_WIDGET(self->counter_label));
  gtk_container_add(GTK_CONTAINER(box), GTK_WIDGET(self->counter_label));

  GtkWidget* button = gtk_button_new_with_label("+");
  gtk_style_context_add_class(gtk_widget_get_style_context(GTK_WIDGET(button)),
                              "circular");
  gtk_widget_set_halign(button, GTK_ALIGN_CENTER);
  gtk_widget_show(button);
  gtk_container_add(GTK_CONTAINER(box), button);
  g_signal_connect_swapped(button, "clicked", G_CALLBACK(button_clicked_cb),
                           self);

  update_counter_label(self);

  gtk_window_present(self->native_window);
}

// Handle platform view requests from Flutter.
static void platform_view_channel_method_cb(FlMethodChannel* channel,
                                            FlMethodCall* method_call,
                                            gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);

  const char* name = fl_method_call_get_name(method_call);
  if (g_str_equal(name, "switchView")) {
    handle_switch_view(self, method_call);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  self->window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(self->window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "platform_view");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(self->window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(self->window, "platform_view");
  }

  gtk_window_set_default_size(self->window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(self->window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  // Create channel to handle platform view requests from Flutter.
  FlEngine* engine = fl_view_get_engine(view);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->platform_view_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(engine),
      "samples.flutter.io/platform_view", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->platform_view_channel,
                                            platform_view_channel_method_cb,
                                            self, nullptr);

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->platform_view_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
