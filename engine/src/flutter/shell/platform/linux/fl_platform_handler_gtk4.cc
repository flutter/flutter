// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_platform_handler_gtk4.h"

#include <gtk/gtk.h>
#include <cstring>

#include "flutter/shell/platform/linux/fl_platform_channel.h"

static constexpr char kUnknownClipboardFormatError[] =
    "Unknown Clipboard Format";

static constexpr char kTextPlainFormat[] = "text/plain";

// Called when clipboard text received.
static void clipboard_text_cb(GObject* object,
                              GAsyncResult* result,
                              gpointer user_data) {
  g_autoptr(FlMethodCall) method_call = FL_METHOD_CALL(user_data);
  g_autofree gchar* text =
      gdk_clipboard_read_text_finish(GDK_CLIPBOARD(object), result, nullptr);
  fl_platform_channel_respond_clipboard_get_data(method_call, text);
}

// Called when clipboard text received during has_strings.
static void clipboard_text_has_strings_cb(GObject* object,
                                          GAsyncResult* result,
                                          gpointer user_data) {
  g_autoptr(FlMethodCall) method_call = FL_METHOD_CALL(user_data);
  g_autofree gchar* text =
      gdk_clipboard_read_text_finish(GDK_CLIPBOARD(object), result, nullptr);
  fl_platform_channel_respond_clipboard_has_strings(
      method_call, text != nullptr && strlen(text) > 0);
}

FlMethodResponse* fl_platform_handler_gtk4_clipboard_set_data(
    FlMethodCall* method_call,
    const gchar* text) {
  GdkClipboard* clipboard =
      gdk_display_get_clipboard(gdk_display_get_default());
  gdk_clipboard_set_text(clipboard, text);

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

FlMethodResponse* fl_platform_handler_gtk4_clipboard_get_data(
    FlMethodCall* method_call,
    const gchar* format) {
  if (strcmp(format, kTextPlainFormat) != 0) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kUnknownClipboardFormatError, "GTK clipboard API only supports text",
        nullptr));
  }

  GdkClipboard* clipboard =
      gdk_display_get_clipboard(gdk_display_get_default());
  gdk_clipboard_read_text_async(clipboard, nullptr, clipboard_text_cb,
                                g_object_ref(method_call));

  // Will respond later.
  return nullptr;
}

FlMethodResponse* fl_platform_handler_gtk4_clipboard_has_strings(
    FlMethodCall* method_call) {
  GdkClipboard* clipboard =
      gdk_display_get_clipboard(gdk_display_get_default());
  gdk_clipboard_read_text_async(clipboard, nullptr,
                                clipboard_text_has_strings_cb,
                                g_object_ref(method_call));

  // Will respond later.
  return nullptr;
}
