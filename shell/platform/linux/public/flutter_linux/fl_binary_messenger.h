// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_BINARY_MESSENGER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_BINARY_MESSENGER_H_

#if !defined(__FLUTTER_LINUX_INSIDE__) && !defined(FLUTTER_LINUX_COMPILATION)
#error "Only <flutter_linux/flutter_linux.h> can be included directly."
#endif

#include <gio/gio.h>
#include <glib-object.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlBinaryMessenger,
                     fl_binary_messenger,
                     FL,
                     BINARY_MESSENGER,
                     GObject)

/**
 * FlBinaryMessenger:
 *
 * #FlBinaryMessenger is an object that allows sending and receiving of platform
 * messages with a #FlEngine.
 */

/**
 * FlBinaryMessengerResponseHandle:
 *
 * A handle used to respond to platform messages.
 */
typedef struct _FlBinaryMessengerResponseHandle FlBinaryMessengerResponseHandle;

/**
 * FlBinaryMessengerCallback:
 * @messenger: a #FlBinaryMessenger
 * @channel: channel message received on
 * @message: message content received from Dart
 * @response_handle: a handle to respond to the message with
 * @user_data: (closure): data provided when registering this callback
 *
 * Function called when platform messages are received. The receiver must
 * respond to the message to avoid leaking the handle, see the documentation on
 * the code that generated the callback as to which function to call.
 */
typedef void (*FlBinaryMessengerCallback)(
    FlBinaryMessenger* messenger,
    const gchar* channel,
    GBytes* message,
    FlBinaryMessengerResponseHandle* response_handle,
    gpointer user_data);

/**
 * fl_binary_messenger_set_platform_message_handler:
 * @binary_messenger: a #FlBinaryMessenger
 * @channel: channel to listen on
 * @callback: function to call when a message is received on this channel
 * @user_data: (closure): user data to pass to @callback
 *
 * Set the function called when a platform message is received on the given
 * channel. Call fl_binary_messenger_send_response() when the message is
 * handled. Ownership of #FlBinaryMessengerResponseHandle is transferred to the
 * caller, and the call must be responded to to avoid memory leaks.
 */
void fl_binary_messenger_set_message_handler_on_channel(
    FlBinaryMessenger* messenger,
    const gchar* channel,
    FlBinaryMessengerCallback callback,
    gpointer user_data);

/**
 * fl_binary_messenger_send_response:
 * @binary_messenger: a #FlBinaryMessenger
 * @response_handle: handle that was provided in a #FlBinaryMessengerCallback
 * @response: (allow-none): response to send or %NULL for an empty response
 * @error: (allow-none): #GError location to store the error occurring, or %NULL
 * to ignore
 *
 * Respond to a platform message.
 *
 * Returns: %TRUE on success.
 */
gboolean fl_binary_messenger_send_response(
    FlBinaryMessenger* messenger,
    FlBinaryMessengerResponseHandle* response_handle,
    GBytes* response,
    GError** error);

/**
 * fl_binary_messenger_send_on_channel:
 * @binary_messenger: a #FlBinaryMessenger
 * @channel: channel to send to
 * @message: (allow-none): message buffer to send or %NULL for an empty message
 * @cancellable: (allow-none): a #GCancellable or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request is
 * satisfied
 * @user_data: (closure): user data to pass to @callback
 *
 * Asynchronously send a platform message.
 */
void fl_binary_messenger_send_on_channel(FlBinaryMessenger* messenger,
                                         const gchar* channel,
                                         GBytes* message,
                                         GCancellable* cancellable,
                                         GAsyncReadyCallback callback,
                                         gpointer user_data);

/**
 * fl_binary_messenger_send_on_channel_finish:
 * @binary_messenger: a #FlBinaryMessenger
 * @result: a #GAsyncResult
 * @error: (allow-none): #GError location to store the error occurring, or %NULL
 * to ignore.
 *
 * Complete request started with fl_binary_messenger_send_on_channel().
 *
 * Returns: message response on success or %NULL on error.
 */
GBytes* fl_binary_messenger_send_on_channel_finish(FlBinaryMessenger* messenger,
                                                   GAsyncResult* result,
                                                   GError** error);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_BINARY_MESSENGER_H_
