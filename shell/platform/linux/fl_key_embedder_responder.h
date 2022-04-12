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

typedef std::function<void(const FlutterKeyEvent* event,
                           FlutterKeyEventCallback callback,
                           void* user_data)>
    EmbedderSendKeyEvent;

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
 *
 * Returns: a new #FlKeyEmbedderResponder.
 */
FlKeyEmbedderResponder* fl_key_embedder_responder_new(
    EmbedderSendKeyEvent send_key_event);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_EMBEDDER_RESPONDER_H_
