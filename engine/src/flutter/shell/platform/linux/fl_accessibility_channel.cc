// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessibility_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_basic_message_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_message_codec.h"

static constexpr char kChannelName[] = "flutter/accessibility";

static constexpr char kTypeKey[] = "type";
static constexpr char kDataKey[] = "data";

static constexpr char kAnnounceType[] = "announce";
static constexpr char kTooltipType[] = "tooltip";
static constexpr char kLongPressType[] = "longPress";
static constexpr char kTapType[] = "tap";
static constexpr char kFocusType[] = "focus";

static constexpr char kViewIdKey[] = "viewId";
static constexpr char kMessageKey[] = "message";
static constexpr char kTextDirectionKey[] = "textDirection";
static constexpr char kAssertivenessKey[] = "assertiveness";

struct _FlAccessibilityChannel {
  GObject parent_instance;

  FlBasicMessageChannel* channel;

  // Handlers for incoming method calls.
  FlAccessibilityChannelVTable* vtable;

  // User data to pass to method call handlers.
  gpointer user_data;
};

G_DEFINE_TYPE(FlAccessibilityChannel, fl_accessibility_channel, G_TYPE_OBJECT)

static FlTextDirection parse_text_direction(int64_t value) {
  switch (value) {
    case 0:
      return FL_TEXT_DIRECTION_RTL;
    case 1:
      return FL_TEXT_DIRECTION_LTR;
    default:
      g_warning("Unknown text direction value %" G_GINT64_FORMAT, value);
      return FL_TEXT_DIRECTION_LTR;
  }
}

static FlAssertiveness parse_assertiveness(int64_t value) {
  switch (value) {
    case 0:
      return FL_ASSERTIVENESS_POLITE;
    case 1:
      return FL_ASSERTIVENESS_ASSERTIVE;
    default:
      g_warning("Unknown assertiveness value %" G_GINT64_FORMAT, value);
      return FL_ASSERTIVENESS_POLITE;
  }
}

static void process_announce(FlAccessibilityChannel* self, FlValue* data) {
  FlValue* view_id_value = fl_value_lookup_string(data, kViewIdKey);
  if (view_id_value == nullptr ||
      fl_value_get_type(view_id_value) != FL_VALUE_TYPE_INT) {
    g_warning("Missing/invalid view ID in accessibility announce event");
    return;
  }
  int64_t view_id = fl_value_get_int(view_id_value);

  FlValue* message_value = fl_value_lookup_string(data, kMessageKey);
  if (message_value == nullptr ||
      fl_value_get_type(message_value) != FL_VALUE_TYPE_STRING) {
    g_warning("Missing/invalid message in accessibility announce event");
    return;
  }
  const char* message = fl_value_get_string(message_value);

  FlValue* text_direction_value =
      fl_value_lookup_string(data, kTextDirectionKey);
  if (text_direction_value == nullptr ||
      fl_value_get_type(text_direction_value) != FL_VALUE_TYPE_INT) {
    g_warning("Missing/invalid text direction in accessibility announce event");
    return;
  }
  FlTextDirection text_direction =
      parse_text_direction(fl_value_get_int(text_direction_value));

  FlValue* assertiveness_value =
      fl_value_lookup_string(data, kAssertivenessKey);
  FlAssertiveness assertiveness = FL_ASSERTIVENESS_POLITE;
  if (assertiveness_value != nullptr) {
    if (fl_value_get_type(assertiveness_value) != FL_VALUE_TYPE_INT) {
      g_warning("Invalid assertiveness in accessibility announce event");
      return;
    }
    assertiveness = parse_assertiveness(fl_value_get_int(assertiveness_value));
  }

  self->vtable->send_announcement(view_id, message, text_direction,
                                  assertiveness, self->user_data);
}

// Process an accessibility event received from Flutter.
static void process_message(FlAccessibilityChannel* self, FlValue* message) {
  if (fl_value_get_type(message) != FL_VALUE_TYPE_MAP) {
    g_warning("Got invalid accessibility event message type");
    return;
  }

  FlValue* type_value = fl_value_lookup_string(message, kTypeKey);
  if (type_value == nullptr) {
    g_warning("Accessibility event missing type");
    return;
  }
  if (fl_value_get_type(type_value) != FL_VALUE_TYPE_STRING) {
    g_warning("Got invalid accessibility event type");
    return;
  }
  const char* type = fl_value_get_string(type_value);

  FlValue* data = fl_value_lookup_string(message, kDataKey);
  if (data == nullptr) {
    g_warning("Accessibility event missing data");
    return;
  }
  if (fl_value_get_type(data) != FL_VALUE_TYPE_MAP) {
    g_warning("Got invalid accessibility data type");
    return;
  }

  if (strcmp(type, kAnnounceType) == 0) {
    process_announce(self, data);
  } else if (strcmp(type, kTooltipType) == 0) {
  } else if (strcmp(type, kLongPressType) == 0) {
  } else if (strcmp(type, kTapType) == 0) {
    // Only used by Android
  } else if (strcmp(type, kFocusType) == 0) {
    // Only used by Android and iOS.
  } else {
    // Silently ignore unknown types.
  }
}

// Called when a message is received from Flutter.
static void message_cb(FlBasicMessageChannel* channel,
                       FlValue* message,
                       FlBasicMessageChannelResponseHandle* response_handle,
                       gpointer user_data) {
  FlAccessibilityChannel* self = FL_ACCESSIBILITY_CHANNEL(user_data);

  process_message(self, message);

  g_autoptr(GError) error = nullptr;
  if (!fl_basic_message_channel_respond(channel, response_handle, nullptr,
                                        &error)) {
    g_warning("Failed to send message response: %s", error->message);
  }
}

static void fl_accessibility_channel_dispose(GObject* object) {
  FlAccessibilityChannel* self = FL_ACCESSIBILITY_CHANNEL(object);

  g_clear_object(&self->channel);

  G_OBJECT_CLASS(fl_accessibility_channel_parent_class)->dispose(object);
}

static void fl_accessibility_channel_class_init(
    FlAccessibilityChannelClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_accessibility_channel_dispose;
}

static void fl_accessibility_channel_init(FlAccessibilityChannel* self) {}

FlAccessibilityChannel* fl_accessibility_channel_new(
    FlBinaryMessenger* messenger,
    FlAccessibilityChannelVTable* vtable,
    gpointer user_data) {
  FlAccessibilityChannel* self = FL_ACCESSIBILITY_CHANNEL(
      g_object_new(fl_accessibility_channel_get_type(), nullptr));

  self->vtable = vtable;
  self->user_data = user_data;

  g_autoptr(FlStandardMessageCodec) codec = fl_standard_message_codec_new();
  self->channel = fl_basic_message_channel_new(messenger, kChannelName,
                                               FL_MESSAGE_CODEC(codec));
  fl_basic_message_channel_set_message_handler(self->channel, message_cb, self,
                                               nullptr);

  return self;
}
