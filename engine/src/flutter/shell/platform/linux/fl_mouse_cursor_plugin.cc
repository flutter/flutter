// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_mouse_cursor_plugin.h"

#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_method_codec.h"

#include <gtk/gtk.h>

static constexpr char kChannelName[] = "flutter/mousecursor";
static constexpr char kBadArgumentsError[] = "Bad Arguments";
static constexpr char kActivateSystemCursorMethod[] = "activateSystemCursor";
static constexpr char kKindKey[] = "kind";

struct _FlMouseCursorPlugin {
  GObject parent_instance;

  FlMethodChannel* channel;

  FlView* view;
};

G_DEFINE_TYPE(FlMouseCursorPlugin, fl_mouse_cursor_plugin, G_TYPE_OBJECT)

// Sets the mouse cursor.
FlMethodResponse* activate_system_cursor(FlMouseCursorPlugin* self,
                                         FlValue* args) {
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Argument map missing or malformed", nullptr));
  }

  FlValue* kind_value = fl_value_lookup_string(args, kKindKey);
  const gchar* kind = nullptr;
  if (fl_value_get_type(kind_value) == FL_VALUE_TYPE_STRING)
    kind = fl_value_get_string(kind_value);

  const gchar* cursor_name = nullptr;
  if (g_strcmp0(kind, "none") == 0)
    cursor_name = "none";
  else if (g_strcmp0(kind, "basic") == 0)
    cursor_name = "default";
  else if (g_strcmp0(kind, "click") == 0)
    cursor_name = "pointer";
  else if (g_strcmp0(kind, "text") == 0)
    cursor_name = "text";
  else if (g_strcmp0(kind, "forbidden") == 0)
    cursor_name = "not-allowed";
  else if (g_strcmp0(kind, "grab") == 0)
    cursor_name = "grab";
  else if (g_strcmp0(kind, "grabbing") == 0)
    cursor_name = "grabbing";
  else if (g_strcmp0(kind, "resizeLeftRight") == 0)
    cursor_name = "ew-resize";
  else if (g_strcmp0(kind, "resizeUpDown") == 0)
    cursor_name = "ns-resize";
  else
    cursor_name = "default";

  GdkWindow* window =
      gtk_widget_get_window(gtk_widget_get_toplevel(GTK_WIDGET(self->view)));
  g_autoptr(GdkCursor) cursor =
      gdk_cursor_new_from_name(gdk_window_get_display(window), cursor_name);
  gdk_window_set_cursor(window, cursor);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when a method call is received from Flutter.
static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  FlMouseCursorPlugin* self = FL_MOUSE_CURSOR_PLUGIN(user_data);

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, kActivateSystemCursorMethod) == 0)
    response = activate_system_cursor(self, args);
  else
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error))
    g_warning("Failed to send method call response: %s", error->message);
}

static void view_weak_notify_cb(gpointer user_data, GObject* object) {
  FlMouseCursorPlugin* self = FL_MOUSE_CURSOR_PLUGIN(object);
  self->view = nullptr;
}

static void fl_mouse_cursor_plugin_dispose(GObject* object) {
  FlMouseCursorPlugin* self = FL_MOUSE_CURSOR_PLUGIN(object);

  g_clear_object(&self->channel);
  if (self->view != nullptr) {
    g_object_weak_unref(G_OBJECT(self->view), view_weak_notify_cb, self);
    self->view = nullptr;
  }

  G_OBJECT_CLASS(fl_mouse_cursor_plugin_parent_class)->dispose(object);
}

static void fl_mouse_cursor_plugin_class_init(FlMouseCursorPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_mouse_cursor_plugin_dispose;
}

static void fl_mouse_cursor_plugin_init(FlMouseCursorPlugin* self) {}

FlMouseCursorPlugin* fl_mouse_cursor_plugin_new(FlBinaryMessenger* messenger,
                                                FlView* view) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);

  FlMouseCursorPlugin* self = FL_MOUSE_CURSOR_PLUGIN(
      g_object_new(fl_mouse_cursor_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel =
      fl_method_channel_new(messenger, kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb, self,
                                            nullptr);
  self->view = view;
  g_object_weak_ref(G_OBJECT(view), view_weak_notify_cb, self);

  return self;
}
