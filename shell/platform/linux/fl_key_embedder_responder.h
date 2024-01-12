// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EMBEDDER_RESPONDER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EMBEDDER_RESPONDER_H_

#include <gdk/gdk.h>
#include <functional>

#include "flutter/shell/platform/linux/fl_key_responder.h"
#include "flutter/shell/platform/linux/fl_keyboard_manager.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_value.h"

constexpr int kMaxConvertedKeyData = 3;

// The signature of a function that FlKeyEmbedderResponder calls on every key
// event.
//
// The `user_data` is opaque data managed by the object that creates
// FlKeyEmbedderResponder, and is registered along with this callback
// via `fl_key_embedder_responder_new`.
//
// The `callback_user_data` is opaque data managed by FlKeyEmbedderResponder.
// Instances of the EmbedderSendKeyEvent callback are required to invoke
// `callback` with the `callback_user_data` parameter after the `event` has been
// processed.
typedef void (*EmbedderSendKeyEvent)(const FlutterKeyEvent* event,
                                     FlutterKeyEventCallback callback,
                                     void* callback_user_data,
                                     void* send_key_event_user_data);

G_BEGIN_DECLS

#define FL_TYPE_KEY_EMBEDDER_RESPONDER fl_key_embedder_responder_get_type()
G_DECLARE_FINAL_TYPE(FlKeyEmbedderResponder,
                     fl_key_embedder_responder,
                     FL,
                     KEY_EMBEDDER_RESPONDER,
                     GObject);

/**
 * FlKeyEmbedderResponder:
 *
 * A #FlKeyResponder that handles events by sending the converted events
 * through the embedder API.
 *
 * This class communicates with the HardwareKeyboard API in the framework.
 */

/**
 * fl_key_embedder_responder_new:
 * @engine: The #FlEngine, whose the embedder API will be used to send
 * the event.
 *
 * Creates a new #FlKeyEmbedderResponder.
 * @send_key_event: a function that is called on every key event.
 * @send_key_event_user_data: an opaque pointer that will be sent back as the
 * last argument of send_key_event, created and managed by the object that holds
 * FlKeyEmbedderResponder.
 *
 * Returns: a new #FlKeyEmbedderResponder.
 */
FlKeyEmbedderResponder* fl_key_embedder_responder_new(
    EmbedderSendKeyEvent send_key_event,
    void* send_key_event_user_data);

/**
 * fl_key_embedder_responder_sync_modifiers_if_needed:
 * @responder: the #FlKeyEmbedderResponder self.
 * @state: the state of the modifiers mask.
 * @event_time: the time attribute of the incoming GDK event.
 *
 * If needed, synthesize modifier keys up and down event by comparing their
 * current pressing states with the given modifiers mask.
 */
void fl_key_embedder_responder_sync_modifiers_if_needed(
    FlKeyEmbedderResponder* responder,
    guint state,
    double event_time);

/**
 * fl_key_embedder_responder_get_pressed_state:
 * @responder: the #FlKeyEmbedderResponder self.
 *
 * Returns the keyboard pressed state. The hash table contains one entry per
 * pressed keys, mapping from the logical key to the physical key.
 */
GHashTable* fl_key_embedder_responder_get_pressed_state(
    FlKeyEmbedderResponder* responder);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EMBEDDER_RESPONDER_H_
