// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_CHANNEL_RESPONDER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_CHANNEL_RESPONDER_H_

#include "flutter/shell/platform/linux/fl_key_event.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlKeyChannelResponder,
                     fl_key_channel_responder,
                     FL,
                     KEY_CHANNEL_RESPONDER,
                     GObject);

/**
 * FlKeyChannelResponderAsyncCallback:
 * @event: whether the event has been handled.
 * @user_data: the same value as user_data sent by
 * #fl_key_responder_handle_event.
 *
 * The signature for a callback with which a #FlKeyChannelResponder
 *asynchronously reports whether the responder handles the event.
 **/
typedef void (*FlKeyChannelResponderAsyncCallback)(bool handled,
                                                   gpointer user_data);

/**
 * FlKeyChannelResponder:
 *
 * A #FlKeyResponder that handles events by sending the raw event data
 * in JSON through the message channel.
 *
 * This class communicates with the RawKeyboard API in the framework.
 */

/**
 * fl_key_channel_responder_new:
 * @messenger: the messenger that the message channel should be built on.
 *
 * Creates a new #FlKeyChannelResponder.
 *
 * Returns: a new #FlKeyChannelResponder.
 */
FlKeyChannelResponder* fl_key_channel_responder_new(
    FlBinaryMessenger* messenger);

/**
 * fl_key_channel_responder_handle_event:
 * @responder: the #FlKeyChannelResponder self.
 * @event: the event to be handled. Must not be null. The object is managed by
 * callee and must not be assumed available after this function.
 * @specified_logical_key:
 * @callback: the callback to report the result. It should be called exactly
 * once. Must not be null.
 * @user_data: a value that will be sent back in the callback. Can be null.
 *
 * Let the responder handle an event, expecting the responder to report
 *  whether to handle the event. The result will be reported by invoking
 * `callback` exactly once, which might happen after
 * `fl_key_channel_responder_handle_event` or during it.
 */
void fl_key_channel_responder_handle_event(
    FlKeyChannelResponder* responder,
    FlKeyEvent* event,
    uint64_t specified_logical_key,
    FlKeyChannelResponderAsyncCallback callback,
    gpointer user_data);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_CHANNEL_RESPONDER_H_
