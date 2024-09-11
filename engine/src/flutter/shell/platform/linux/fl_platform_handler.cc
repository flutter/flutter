// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_platform_handler.h"

#include <gtk/gtk.h>
#include <cstring>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_method_codec.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_channel.h"

static constexpr char kChannelName[] = "flutter/platform";
static constexpr char kBadArgumentsError[] = "Bad Arguments";
static constexpr char kUnknownClipboardFormatError[] =
    "Unknown Clipboard Format";
static constexpr char kInProgressError[] = "In Progress";
static constexpr char kGetClipboardDataMethod[] = "Clipboard.getData";
static constexpr char kSetClipboardDataMethod[] = "Clipboard.setData";
static constexpr char kClipboardHasStringsMethod[] = "Clipboard.hasStrings";
static constexpr char kExitApplicationMethod[] = "System.exitApplication";
static constexpr char kRequestAppExitMethod[] = "System.requestAppExit";
static constexpr char kInitializationCompleteMethod[] =
    "System.initializationComplete";
static constexpr char kPlaySoundMethod[] = "SystemSound.play";
static constexpr char kSystemNavigatorPopMethod[] = "SystemNavigator.pop";
static constexpr char kTextKey[] = "text";
static constexpr char kValueKey[] = "value";

static constexpr char kExitTypeKey[] = "type";
static constexpr char kExitTypeCancelable[] = "cancelable";
static constexpr char kExitTypeRequired[] = "required";

static constexpr char kExitResponseKey[] = "response";
static constexpr char kExitResponseCancel[] = "cancel";
static constexpr char kExitResponseExit[] = "exit";

static constexpr char kTextPlainFormat[] = "text/plain";

static constexpr char kSoundTypeAlert[] = "SystemSoundType.alert";
static constexpr char kSoundTypeClick[] = "SystemSoundType.click";

struct _FlPlatformHandler {
  GObject parent_instance;

  FlMethodChannel* channel;
  FlMethodCall* exit_application_method_call;
  GCancellable* cancellable;
  bool app_initialization_complete;
};

G_DEFINE_TYPE(FlPlatformHandler, fl_platform_handler, G_TYPE_OBJECT)

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
static FlMethodResponse* clipboard_set_data(FlPlatformHandler* self,
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
static FlMethodResponse* clipboard_get_data_async(FlPlatformHandler* self,
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
    FlPlatformHandler* self,
    FlMethodCall* method_call) {
  GtkClipboard* clipboard =
      gtk_clipboard_get_default(gdk_display_get_default());
  gtk_clipboard_request_text(clipboard, clipboard_text_has_strings_cb,
                             g_object_ref(method_call));

  // Will respond later.
  return nullptr;
}

// Get the exit response from a System.requestAppExit method call.
static gchar* get_exit_response(FlMethodResponse* response) {
  if (response == nullptr) {
    return nullptr;
  }

  g_autoptr(GError) error = nullptr;
  FlValue* result = fl_method_response_get_result(response, &error);
  if (result == nullptr) {
    g_warning("Error returned from System.requestAppExit: %s", error->message);
    return nullptr;
  }
  if (fl_value_get_type(result) != FL_VALUE_TYPE_MAP) {
    g_warning("System.requestAppExit result argument map missing or malformed");
    return nullptr;
  }

  FlValue* response_value = fl_value_lookup_string(result, kExitResponseKey);
  if (fl_value_get_type(response_value) != FL_VALUE_TYPE_STRING) {
    g_warning("Invalid response from System.requestAppExit");
    return nullptr;
  }
  return g_strdup(fl_value_get_string(response_value));
}

// Quit this application
static void quit_application() {
  GApplication* app = g_application_get_default();
  if (app == nullptr) {
    // Unable to gracefully quit, so just exit the process.
    exit(0);
  }

  // GtkApplication windows contain a reference back to the application.
  // Break them so the application object can cleanup.
  // See https://gitlab.gnome.org/GNOME/gtk/-/issues/6190
  if (GTK_IS_APPLICATION(app)) {
    // List is copied as it will be modified as windows are disconnected from
    // the application.
    g_autoptr(GList) windows =
        g_list_copy(gtk_application_get_windows(GTK_APPLICATION(app)));
    for (GList* link = windows; link != NULL; link = link->next) {
      GtkWidget* window = GTK_WIDGET(link->data);
      gtk_window_set_application(GTK_WINDOW(window), NULL);
    }
  }

  g_application_quit(app);
}

// Handle response of System.requestAppExit.
static void request_app_exit_response_cb(GObject* object,
                                         GAsyncResult* result,
                                         gpointer user_data) {
  FlPlatformHandler* self = FL_PLATFORM_HANDLER(user_data);

  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) method_response =
      fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(object), result,
                                             &error);
  g_autofree gchar* exit_response = nullptr;
  if (method_response == nullptr) {
    if (g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
      return;
    }
    g_warning("Failed to complete System.requestAppExit: %s", error->message);
  } else {
    exit_response = get_exit_response(method_response);
  }
  // If something went wrong, then just exit.
  if (exit_response == nullptr) {
    exit_response = g_strdup(kExitResponseExit);
  }

  if (g_str_equal(exit_response, kExitResponseExit)) {
    quit_application();
  } else if (g_str_equal(exit_response, kExitResponseCancel)) {
    // Canceled - no action to take.
  }

  // If request was due to a request from Flutter, pass result back.
  if (self->exit_application_method_call != nullptr) {
    g_autoptr(FlValue) exit_result = fl_value_new_map();
    fl_value_set_string_take(exit_result, kExitResponseKey,
                             fl_value_new_string(exit_response));
    g_autoptr(FlMethodResponse) exit_response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(exit_result));
    if (!fl_method_call_respond(self->exit_application_method_call,
                                exit_response, &error)) {
      g_warning("Failed to send response to System.exitApplication: %s",
                error->message);
    }
    g_clear_object(&self->exit_application_method_call);
  }
}

// Send a request to Flutter to exit the application, but only if it's ready for
// a request.
static void request_app_exit(FlPlatformHandler* self, const char* type) {
  g_autoptr(FlValue) args = fl_value_new_map();
  if (!self->app_initialization_complete ||
      g_str_equal(type, kExitTypeRequired)) {
    quit_application();
    return;
  }

  fl_value_set_string_take(args, kExitTypeKey, fl_value_new_string(type));
  fl_method_channel_invoke_method(self->channel, kRequestAppExitMethod, args,
                                  self->cancellable,
                                  request_app_exit_response_cb, self);
}

// Called when the Dart app has finished initialization and is ready to handle
// requests. For the Flutter framework, this means after the ServicesBinding has
// been initialized and it sends a System.initializationComplete message.
static FlMethodResponse* system_intitialization_complete(
    FlPlatformHandler* self,
    FlMethodCall* method_call) {
  self->app_initialization_complete = TRUE;
  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when Flutter wants to exit the application.
static FlMethodResponse* system_exit_application(FlPlatformHandler* self,
                                                 FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Argument map missing or malformed", nullptr));
  }

  FlValue* type_value = fl_value_lookup_string(args, kExitTypeKey);
  if (type_value == nullptr ||
      fl_value_get_type(type_value) != FL_VALUE_TYPE_STRING) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Missing type argument", nullptr));
  }
  const char* type = fl_value_get_string(type_value);

  // Save method call to respond to when our request to Flutter completes.
  if (self->exit_application_method_call != nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kInProgressError, "Request already in progress", nullptr));
  }
  self->exit_application_method_call =
      FL_METHOD_CALL(g_object_ref(method_call));

  // Requested to immediately quit if the app hasn't yet signaled that it is
  // ready to handle requests, or if the type of exit requested is "required".
  if (!self->app_initialization_complete ||
      g_str_equal(type, kExitTypeRequired)) {
    quit_application();
    g_autoptr(FlValue) exit_result = fl_value_new_map();
    fl_value_set_string_take(exit_result, kExitResponseKey,
                             fl_value_new_string(kExitResponseExit));
    return FL_METHOD_RESPONSE(fl_method_success_response_new(exit_result));
  }

  // Send the request back to Flutter to follow the standard process.
  request_app_exit(self, type);

  // Will respond later.
  return nullptr;
}

// Called when Flutter wants to play a sound.
static FlMethodResponse* system_sound_play(FlPlatformHandler* self,
                                           FlValue* args) {
  if (fl_value_get_type(args) != FL_VALUE_TYPE_STRING) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Expected string", nullptr));
  }

  const gchar* type = fl_value_get_string(args);
  if (strcmp(type, kSoundTypeAlert) == 0) {
    GdkDisplay* display = gdk_display_get_default();
    if (display != nullptr) {
      gdk_display_beep(display);
    }
  } else if (strcmp(type, kSoundTypeClick) == 0) {
    // We don't make sounds for keyboard on desktops.
  } else {
    g_warning("Ignoring unknown sound type %s in SystemSound.play.\n", type);
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when Flutter wants to quit the application.
static FlMethodResponse* system_navigator_pop(FlPlatformHandler* self) {
  quit_application();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when a method call is received from Flutter.
static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  FlPlatformHandler* self = FL_PLATFORM_HANDLER(user_data);

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, kSetClipboardDataMethod) == 0) {
    response = clipboard_set_data(self, args);
  } else if (strcmp(method, kGetClipboardDataMethod) == 0) {
    response = clipboard_get_data_async(self, method_call);
  } else if (strcmp(method, kClipboardHasStringsMethod) == 0) {
    response = clipboard_has_strings_async(self, method_call);
  } else if (strcmp(method, kExitApplicationMethod) == 0) {
    response = system_exit_application(self, method_call);
  } else if (strcmp(method, kInitializationCompleteMethod) == 0) {
    response = system_intitialization_complete(self, method_call);
  } else if (strcmp(method, kPlaySoundMethod) == 0) {
    response = system_sound_play(self, args);
  } else if (strcmp(method, kSystemNavigatorPopMethod) == 0) {
    response = system_navigator_pop(self);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  if (response != nullptr) {
    send_response(method_call, response);
  }
}

static void fl_platform_handler_dispose(GObject* object) {
  FlPlatformHandler* self = FL_PLATFORM_HANDLER(object);

  g_cancellable_cancel(self->cancellable);

  g_clear_object(&self->channel);
  g_clear_object(&self->exit_application_method_call);
  g_clear_object(&self->cancellable);

  G_OBJECT_CLASS(fl_platform_handler_parent_class)->dispose(object);
}

static void fl_platform_handler_class_init(FlPlatformHandlerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_platform_handler_dispose;
}

static void fl_platform_handler_init(FlPlatformHandler* self) {
  self->cancellable = g_cancellable_new();
}

FlPlatformHandler* fl_platform_handler_new(FlBinaryMessenger* messenger) {
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);

  FlPlatformHandler* self = FL_PLATFORM_HANDLER(
      g_object_new(fl_platform_handler_get_type(), nullptr));

  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  self->channel =
      fl_method_channel_new(messenger, kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb, self,
                                            nullptr);
  self->app_initialization_complete = FALSE;

  return self;
}

void fl_platform_handler_request_app_exit(FlPlatformHandler* self) {
  g_return_if_fail(FL_IS_PLATFORM_HANDLER(self));
  // Request a cancellable exit.
  request_app_exit(self, kExitTypeCancelable);
}
