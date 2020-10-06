// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_platform_plugin.h"

#include <gtk/gtk.h>
#include <cstring>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_method_codec.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_channel.h"

static constexpr char kChannelName[] = "flutter/platform";
static constexpr char kBadArgumentsError[] = "Bad Arguments";
static constexpr char kUnknownClipboardFormatError[] =
    "Unknown Clipboard Format";
static constexpr char kFailedError[] = "Failed";
static constexpr char kGetClipboardDataMethod[] = "Clipboard.getData";
static constexpr char kSetClipboardDataMethod[] = "Clipboard.setData";
static constexpr char kClipboardHasStringsMethod[] = "Clipboard.hasStrings";
static constexpr char kSystemNavigatorPopMethod[] = "SystemNavigator.pop";
static constexpr char kTextKey[] = "text";
static constexpr char kValueKey[] = "value";

static constexpr char kTextPlainFormat[] = "text/plain";

struct _FlPlatformPlugin {
  GObject parent_instance;

  FlMethodChannel* channel;
};

G_DEFINE_TYPE(FlPlatformPlugin, fl_platform_plugin, G_TYPE_OBJECT)

// Sends the method call response to Flutter.
static void send_response(FlMethodCall* method_call,
                          FlMethodResponse* response) {
  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send method call response: %s", error->message);
  }
}

// Called when clipboard text received.
static void clipboard_text_cb(GtkClipboard* clipboard,
                              const gchar* text,
                              gpointer user_data) {
  g_autoptr(FlMethodCall) method_call = FL_METHOD_CALL(user_data);

  g_autoptr(FlValue) result = nullptr;
  if (text != nullptr) {
    result = fl_value_new_map();
    fl_value_set_string_take(result, kTextKey, fl_value_new_string(text));
  }

  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  send_response(method_call, response);
}

// Called when clipboard text received during has_strings.
static void clipboard_text_has_strings_cb(GtkClipboard* clipboard,
                                          const gchar* text,
                                          gpointer user_data) {
  g_autoptr(FlMethodCall) method_call = FL_METHOD_CALL(user_data);

  g_autoptr(FlValue) result = fl_value_new_map();
  fl_value_set_string_take(
      result, kValueKey,
      fl_value_new_bool(text != nullptr && strlen(text) > 0));

  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  send_response(method_call, response);
}

// Called when Flutter wants to copy to the clipboard.
static FlMethodResponse* clipboard_set_data(FlPlatformPlugin* self,
                                            FlValue* args) {
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Argument map missing or malformed", nullptr));
  }

  FlValue* text_value = fl_value_lookup_string(args, kTextKey);
  if (text_value == nullptr ||
      fl_value_get_type(text_value) != FL_VALUE_TYPE_STRING) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Missing clipboard text", nullptr));
  }

  GtkClipboard* clipboard =
      gtk_clipboard_get_default(gdk_display_get_default());
  gtk_clipboard_set_text(clipboard, fl_value_get_string(text_value), -1);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when Flutter wants to paste from the clipboard.
static FlMethodResponse* clipboard_get_data_async(FlPlatformPlugin* self,
                                                  FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);

  if (fl_value_get_type(args) != FL_VALUE_TYPE_STRING) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Expected string", nullptr));
  }

  const gchar* format = fl_value_get_string(args);
  if (strcmp(format, kTextPlainFormat) != 0) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kUnknownClipboardFormatError, "GTK clipboard API only supports text",
        nullptr));
  }

  GtkClipboard* clipboard =
      gtk_clipboard_get_default(gdk_display_get_default());
  gtk_clipboard_request_text(clipboard, clipboard_text_cb,
                             g_object_ref(method_call));

  // Will respond later.
  return nullptr;
}

// Called when Flutter wants to know if the content of the clipboard is able to
// be pasted, without actually accessing the clipboard content itself.
static FlMethodResponse* clipboard_has_strings_async(
    FlPlatformPlugin* self,
    FlMethodCall* method_call) {
  GtkClipboard* clipboard =
      gtk_clipboard_get_default(gdk_display_get_default());
  gtk_clipboard_request_text(clipboard, clipboard_text_has_strings_cb,
                             g_object_ref(method_call));

  // Will respond later.
  return nullptr;
}

// Called when Flutter wants to quit the application.
static FlMethodResponse* system_navigator_pop(FlPlatformPlugin* self) {
  GApplication* app = g_application_get_default();
  if (app == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kFailedError, "Unable to get GApplication", nullptr));
  }

  g_application_quit(app);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when a method call is received from Flutter.
static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  FlPlatformPlugin* self = FL_PLATFORM_PLUGIN(user_data);

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, kSetClipboardDataMethod) == 0) {
    response = clipboard_set_data(self, args);
  } else if (strcmp(method, kGetClipboardDataMethod) == 0) {
    response = clipboard_get_data_async(self, method_call);
  } else if (strcmp(method, kClipboardHasStringsMethod) == 0) {
    response = clipboard_has_strings_async(self, method_call);
  } else if (strcmp(method, kSystemNavigatorPopMethod) == 0) {
    response = system_navigator_pop(self);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  if (response != nullptr) {
    send_response(method_call, response);
  }
}

static void fl_platform_plugin_dispose(GObject* object) {
  FlPlatformPlugin* self = FL_PLATFORM_PLUGIN(object);

  g_clear_object(&self->channel);

  G_OBJECT_CLASS(fl_platform_plugin_parent_class)->dispose(object);
}

static void fl_platform_plugin_class_init(FlPlatformPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_platform_plugin_dispose;
}

static void fl_platform_plugin_init(FlPlatformPlugin* self) {}

FlPlatformPlugin* fl_platform_plugin_new(FlBinaryMessenger* messenger) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);

  FlPlatformPlugin* self =
      FL_PLATFORM_PLUGIN(g_object_new(fl_platform_plugin_get_type(), nullptr));

  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  self->channel =
      fl_method_channel_new(messenger, kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb, self,
                                            nullptr);

  return self;
}
