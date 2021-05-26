// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_CHANNEL_RESPONDER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_CHANNEL_RESPONDER_H_

#include <gdk/gdk.h>

#include "flutter/shell/platform/linux/fl_key_responder.h"
#include "flutter/shell/platform/linux/fl_keyboard_manager.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_value.h"

typedef FlValue* (*FlValueConverter)(FlValue*);

/**
 * FlKeyChannelResponderMock:
 *
 * Allows mocking of FlKeyChannelResponder methods and values. Only used in
 * unittests.
 */
typedef struct _FlKeyChannelResponderMock {
  /**
   * FlKeyChannelResponderMock::value_converter:
   * If #value_converter is not nullptr, then this function is applied to the
   * reply of the message, whose return value is taken as the message reply.
   */
  FlValueConverter value_converter;

  /**
   * FlKeyChannelResponderMock::channel_name:
   * Mocks the channel name to send the message.
   */
  const char* channel_name;
} FlKeyChannelResponderMock;

G_BEGIN_DECLS

#define FL_TYPE_KEY_CHANNEL_RESPONDER fl_key_channel_responder_get_type()
G_DECLARE_FINAL_TYPE(FlKeyChannelResponder,
                     fl_key_channel_responder,
                     FL,
                     KEY_CHANNEL_RESPONDER,
                     GObject);

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
 * @mock: options to mock several functionalities. Only used in unittests.
 *
 * Creates a new #FlKeyChannelResponder.
 *
 * Returns: a new #FlKeyChannelResponder.
 */
FlKeyChannelResponder* fl_key_channel_responder_new(
    FlBinaryMessenger* messenger,
    FlKeyChannelResponderMock* mock = nullptr);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_CHANNEL_RESPONDER_H_
