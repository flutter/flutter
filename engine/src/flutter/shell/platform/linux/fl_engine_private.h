// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ENGINE_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ENGINE_PRIVATE_H_

#include <glib-object.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_renderer.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

G_BEGIN_DECLS

/**
 * FlEngineError:
 * Errors for #FlEngine objects to set on failures.
 */

typedef enum {
  FL_ENGINE_ERROR_FAILED,
} FlEngineError;

GQuark fl_engine_error_quark(void) G_GNUC_CONST;

/**
 * FlEnginePlatformMessageCallback:
 * @engine: a #FlEngine
 * @channel: channel message received on.
 * @message: message content received from Dart
 * @response_handle: a handle to respond to the message with
 * @user_data: (closure): data provided when registering this callback
 *
 * Function called when platform messages are received.
 *
 * Returns: %TRUE if message has been accepted.
 */
typedef gboolean (*FlEnginePlatformMessageCallback)(
    FlEngine* engine,
    const gchar* channel,
    GBytes* message,
    const FlutterPlatformMessageResponseHandle* response_handle,
    gpointer user_data);

/**
 * fl_engine_new:
 * @project: a #FlDartProject
 * @renderer: a #FlRenderer
 *
 * Creates a new Flutter engine.
 *
 * Returns: a #FlEngine
 */
FlEngine* fl_engine_new(FlDartProject* project, FlRenderer* renderer);

/**
 * fl_engine_set_platform_message_handler:
 * @engine: a #FlEngine
 * @callback: function to call when a platform message is received
 * @user_data: (closure): user data to pass to @callback
 *
 * Register a callback to handle platform messages. Call
 * fl_engine_send_platform_message_response() when this message should be
 * responded to. Ownership of #FlutterPlatformMessageResponseHandle is
 * transferred to the caller, and the call must be responded to to avoid
 * memory leaks.
 */
void fl_engine_set_platform_message_handler(
    FlEngine* engine,
    FlEnginePlatformMessageCallback callback,
    gpointer user_data);

/**
 * fl_engine_start:
 * @engine: a #FlEngine
 * @error: (allow-none): #GError location to store the error occurring, or %NULL
 * to ignore.
 *
 * Starts the Flutter engine.
 *
 * Returns: %TRUE on success
 */
gboolean fl_engine_start(FlEngine* engine, GError** error);

/**
 * fl_engine_send_window_metrics_event:
 * @engine: a #FlEngine
 * @width: width of the window in pixels.
 * @height: height of the window in pixels.
 * @pixel_ratio: scale factor for window.
 *
 * Sends a window metrics event to the engine.
 */
void fl_engine_send_window_metrics_event(FlEngine* engine,
                                         size_t width,
                                         size_t height,
                                         double pixel_ratio);

/**
 * fl_engine_send_mouse_pointer_event:
 * @engine: a #FlEngine
 * @phase: mouse phase.
 * @timestamp: time when event occurred in microseconds.
 * @x: x location of mouse cursor.
 * @y: y location of mouse cursor.
 * @buttons: buttons that are pressed.
 *
 * Sends a mouse pointer event to the engine.
 */
void fl_engine_send_mouse_pointer_event(FlEngine* engine,
                                        FlutterPointerPhase phase,
                                        size_t timestamp,
                                        double x,
                                        double y,
                                        int64_t buttons);

/**
 * fl_engine_send_platform_message_response:
 * @engine: a #FlEngine
 * @response_handle: handle that was provided in the callback.
 * @response: (allow-none): response to send or %NULL for an empty response.
 * @error: (allow-none): #GError location to store the error occurring, or %NULL
 * to ignore.
 *
 * Respond to a platform message.
 *
 * Returns: %TRUE on success.
 */
gboolean fl_engine_send_platform_message_response(
    FlEngine* engine,
    const FlutterPlatformMessageResponseHandle* handle,
    GBytes* response,
    GError** error);

/**
 * fl_engine_send_platform_message:
 * @engine: a #FlEngine
 * @channel: channel to send to
 * @message: (allow-none): message buffer to send or %NULL for an empty message
 * @cancellable: (allow-none): a #GCancellable or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request is
 * satisfied
 * @user_data: (closure): user data to pass to @callback
 *
 * Asynchronously send a platform message.
 */
void fl_engine_send_platform_message(FlEngine* engine,
                                     const gchar* channel,
                                     GBytes* message,
                                     GCancellable* cancellable,
                                     GAsyncReadyCallback callback,
                                     gpointer user_data);

/**
 * fl_engine_send_platform_message_finish:
 * @engine: a #FlEngine
 * @result: a #GAsyncResult
 * @error: (allow-none): #GError location to store the error occurring, or %NULL
 * to ignore.
 *
 * Complete request started with fl_engine_send_platform_message().
 *
 * Returns: message response on success or %NULL on error.
 */
GBytes* fl_engine_send_platform_message_finish(FlEngine* engine,
                                               GAsyncResult* result,
                                               GError** error);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ENGINE_PRIVATE_H_
