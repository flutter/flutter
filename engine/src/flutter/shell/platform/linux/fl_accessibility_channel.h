// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_CHANNEL_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_CHANNEL_H_

#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlAccessibilityChannel,
                     fl_accessibility_channel,
                     FL,
                     ACCESSIBILITY_CHANNEL,
                     GObject);

// A direction in which text flows.
typedef enum {
  FL_TEXT_DIRECTION_RTL,
  FL_TEXT_DIRECTION_LTR,
} FlTextDirection;

// Assertiveness level of an accessibility announcement.
typedef enum {
  FL_ASSERTIVENESS_POLITE,
  FL_ASSERTIVENESS_ASSERTIVE,
} FlAssertiveness;

/**
 * FlAccessibilityChannel:
 *
 * #FlAccessibilityChannel is a channel that implements the shell side
 * of SystemChannels.accessibility from the Flutter services library.
 */

typedef struct {
  void (*send_announcement)(int64_t view_id,
                            const char* message,
                            FlTextDirection text_direction,
                            FlAssertiveness assertiveness,
                            gpointer user_data);
} FlAccessibilityChannelVTable;

/**
 * fl_accessibility_channel_new:
 * @messenger: an #FlBinaryMessenger
 * @vtable: callbacks for incoming method calls.
 * @user_data: data to pass in callbacks.
 *
 * Creates a new channel that handles accessibility requests from Dart.
 *
 * Returns: a new #FlAccessibilityChannel
 */
FlAccessibilityChannel* fl_accessibility_channel_new(
    FlBinaryMessenger* messenger,
    FlAccessibilityChannelVTable* vtable,
    gpointer user_data);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_CHANNEL_H_
