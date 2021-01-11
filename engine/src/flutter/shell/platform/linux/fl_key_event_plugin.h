// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_PLUGIN_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_PLUGIN_H_

#include "flutter/shell/platform/linux/fl_text_input_plugin.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_value.h"

#include <gdk/gdk.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlKeyEventPlugin,
                     fl_key_event_plugin,
                     FL,
                     KEY_EVENT_PLUGIN,
                     GObject);

/**
 * FlKeyEventPlugin:
 *
 * #FlKeyEventPlugin is a plugin that implements the shell side
 * of SystemChannels.keyEvent from the Flutter services library.
 */

/**
 * FlKeyEventPluginCallback:
 * @source_object: (nullable): the object the key event was started with.
 * @message: the message returned from the framework.
 * @handled: a boolean indicating whether the key event was handled in the
 *           framework.
 * @user_data: user data passed to the callback.
 *
 * Type definition for a function that will be called when a key event is
 * received from the engine.
 **/
typedef void (*FlKeyEventPluginCallback)(GObject* source_object,
                                         FlValue* message,
                                         gboolean handled,
                                         gpointer user_data);

/**
 * fl_key_event_plugin_new:
 * @messenger: an #FlBinaryMessenger.
 * @response_callback: the callback to call when a response is received.  If not
 *                     given (nullptr), then the default response callback is
 *                     used. Typically used for tests to receive event
 *                     information. If specified, unhandled events will not be
 *                     re-dispatched.
 * @text_input_plugin: The #FlTextInputPlugin to send key events to if the
 *                     framework doesn't handle them.
 * @channel_name: the name of the channel to send key events to the framework
 *                on. If not given (nullptr), then the standard key event
 *                channel name is used. Typically used for tests to send on a
 *                test channel.
 *
 * Creates a new plugin that implements SystemChannels.keyEvent from the
 * Flutter services library.
 *
 * Returns: a new #FlKeyEventPlugin.
 */
FlKeyEventPlugin* fl_key_event_plugin_new(
    FlBinaryMessenger* messenger,
    FlTextInputPlugin* text_input_plugin,
    FlKeyEventPluginCallback response_callback = nullptr,
    const char* channel_name = nullptr);

/**
 * fl_key_event_plugin_send_key_event:
 * @plugin: an #FlKeyEventPlugin.
 * @event: a #GdkEventKey.
 * @user_data: a pointer to user data to send to the response callback via the
 *             messenger.
 *
 * @returns %TRUE if this key event should be considered handled and
 *          event propagation stopped.
 *
 * Sends a key event to Flutter.
 */
bool fl_key_event_plugin_send_key_event(FlKeyEventPlugin* plugin,
                                        GdkEventKey* event,
                                        gpointer user_data = nullptr);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EVENT_PLUGIN_H_
