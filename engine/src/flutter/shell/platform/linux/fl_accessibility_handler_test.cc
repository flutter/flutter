// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Workaround missing C code compatibility in ATK header.
// Fixed in https://gitlab.gnome.org/GNOME/at-spi2-core/-/merge_requests/219
extern "C" {
#include <atk/atk.h>
}

#include "flutter/shell/platform/linux/fl_accessibility_handler.h"
#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_view_private.h"
#include "flutter/shell/platform/linux/testing/fl_mock_binary_messenger.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"
#include "flutter/testing/testing.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

static constexpr int64_t kTextDirectionLtr = 0;
static constexpr int64_t kAssertivenessAssertive = 1;

// Enum copied from ATK 2.50, as the version we are building against doesn't
// have this.
typedef enum {
  FL_ATK_LIVE_NONE,
  FL_ATK_LIVE_POLITE,
  FL_ATK_LIVE_ASSERTIVE
} FlAtkLive;

static void announcement_cb(FlViewAccessible* accessible,
                            const gchar* message,
                            gpointer user_data) {
  EXPECT_STREQ(message, "MESSAGE");
  gboolean* signalled = static_cast<gboolean*>(user_data);
  *signalled = TRUE;
}

static void notification_polite_cb(FlViewAccessible* accessible,
                                   const gchar* message,
                                   FlAtkLive politeness,
                                   gpointer user_data) {
  EXPECT_STREQ(message, "MESSAGE");
  EXPECT_EQ(politeness, FL_ATK_LIVE_POLITE);
  gboolean* signalled = static_cast<gboolean*>(user_data);
  *signalled = TRUE;
}

static void notification_assertive_cb(FlViewAccessible* accessible,
                                      const gchar* message,
                                      FlAtkLive politeness,
                                      gpointer user_data) {
  EXPECT_STREQ(message, "MESSAGE");
  EXPECT_EQ(politeness, FL_ATK_LIVE_ASSERTIVE);
  gboolean* signalled = static_cast<gboolean*>(user_data);
  *signalled = TRUE;
}

static gboolean atk_supports_announce() {
  return atk_get_major_version() == 2 && atk_get_minor_version() >= 46;
}

static void subscribe_signal(FlViewAccessible* accessible,
                             gboolean* signalled,
                             gboolean assertive) {
  if (!atk_supports_announce()) {
    return;
  }

  if (atk_get_major_version() == 2 && atk_get_minor_version() < 50) {
    g_signal_connect(accessible, "announcement", G_CALLBACK(announcement_cb),
                     signalled);
  } else {
    g_signal_connect(accessible, "notification",
                     G_CALLBACK(assertive ? notification_assertive_cb
                                          : notification_polite_cb),
                     signalled);
  }
}

TEST(FlAccessibilityHandlerTest, Announce) {
  flutter::testing::fl_ensure_gtk_init();

  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlEngine) engine =
      fl_engine_new_with_binary_messenger(FL_BINARY_MESSENGER(messenger));
  FlView* view = fl_view_new_for_engine(engine);

  gboolean signalled = FALSE;
  subscribe_signal(fl_view_get_accessible(view), &signalled, FALSE);

  g_autoptr(FlValue) message = fl_value_new_map();
  fl_value_set_string_take(message, "type", fl_value_new_string("announce"));
  g_autoptr(FlValue) data = fl_value_new_map();
  fl_value_set_string(message, "data", data);
  fl_value_set_string_take(data, "viewId",
                           fl_value_new_int(fl_view_get_id(view)));
  fl_value_set_string_take(data, "message", fl_value_new_string("MESSAGE"));
  fl_value_set_string_take(data, "textDirection",
                           fl_value_new_int(kTextDirectionLtr));

  gboolean called = FALSE;
  fl_mock_binary_messenger_send_standard_message(
      messenger, "flutter/accessibility", message,
      [](FlMockBinaryMessenger* messenger, FlValue* response,
         gpointer user_data) {
        EXPECT_EQ(fl_value_get_type(response), FL_VALUE_TYPE_NULL);
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
      },
      &called);
  EXPECT_TRUE(called);
  if (atk_supports_announce()) {
    EXPECT_TRUE(signalled);
  }

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}

TEST(FlAccessibilityHandlerTest, AnnounceAssertive) {
  flutter::testing::fl_ensure_gtk_init();

  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlEngine) engine =
      fl_engine_new_with_binary_messenger(FL_BINARY_MESSENGER(messenger));
  FlView* view = fl_view_new_for_engine(engine);

  gboolean signalled = FALSE;
  subscribe_signal(fl_view_get_accessible(view), &signalled, TRUE);

  g_autoptr(FlValue) message = fl_value_new_map();
  fl_value_set_string_take(message, "type", fl_value_new_string("announce"));
  g_autoptr(FlValue) data = fl_value_new_map();
  fl_value_set_string(message, "data", data);
  fl_value_set_string_take(data, "viewId",
                           fl_value_new_int(fl_view_get_id(view)));
  fl_value_set_string_take(data, "message", fl_value_new_string("MESSAGE"));
  fl_value_set_string_take(data, "textDirection",
                           fl_value_new_int(kTextDirectionLtr));
  // Add optional assertiveness (not used in ATK)
  fl_value_set_string_take(data, "assertiveness",
                           fl_value_new_int(kAssertivenessAssertive));

  gboolean called = FALSE;
  fl_mock_binary_messenger_send_standard_message(
      messenger, "flutter/accessibility", message,
      [](FlMockBinaryMessenger* messenger, FlValue* response,
         gpointer user_data) {
        EXPECT_EQ(fl_value_get_type(response), FL_VALUE_TYPE_NULL);
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
      },
      &called);
  EXPECT_TRUE(called);
  if (atk_supports_announce()) {
    EXPECT_TRUE(signalled);
  }

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}

TEST(FlAccessibilityHandlerTest, AnnounceUnknownView) {
  flutter::testing::fl_ensure_gtk_init();

  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlEngine) engine =
      fl_engine_new_with_binary_messenger(FL_BINARY_MESSENGER(messenger));
  FlView* view = fl_view_new_for_engine(engine);

  gboolean signalled = FALSE;
  subscribe_signal(fl_view_get_accessible(view), &signalled, FALSE);

  g_autoptr(FlValue) message = fl_value_new_map();
  fl_value_set_string_take(message, "type", fl_value_new_string("announce"));
  g_autoptr(FlValue) data = fl_value_new_map();
  fl_value_set_string(message, "data", data);
  fl_value_set_string_take(data, "viewId", fl_value_new_int(999));
  fl_value_set_string_take(data, "message", fl_value_new_string("MESSAGE"));
  fl_value_set_string_take(data, "textDirection",
                           fl_value_new_int(kTextDirectionLtr));
  // Add optional assertiveness (not used in ATK)
  fl_value_set_string_take(data, "assertiveness",
                           fl_value_new_int(kAssertivenessAssertive));

  gboolean called = FALSE;
  fl_mock_binary_messenger_send_standard_message(
      messenger, "flutter/accessibility", message,
      [](FlMockBinaryMessenger* messenger, FlValue* response,
         gpointer user_data) {
        EXPECT_EQ(fl_value_get_type(response), FL_VALUE_TYPE_NULL);
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
      },
      &called);
  EXPECT_TRUE(called);
  EXPECT_FALSE(signalled);

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}

TEST(FlAccessibilityHandlerTest, UnknownType) {
  flutter::testing::fl_ensure_gtk_init();

  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlEngine) engine =
      fl_engine_new_with_binary_messenger(FL_BINARY_MESSENGER(messenger));
  FlView* view = fl_view_new_for_engine(engine);

  gboolean signalled = FALSE;
  subscribe_signal(fl_view_get_accessible(view), &signalled, FALSE);

  // Unknown type, ignored by embedder.
  g_autoptr(FlValue) message = fl_value_new_map();
  fl_value_set_string_take(message, "type", fl_value_new_string("UNKNOWN"));
  fl_value_set_string_take(message, "data", fl_value_new_map());

  gboolean called = FALSE;
  fl_mock_binary_messenger_send_standard_message(
      messenger, "flutter/accessibility", message,
      [](FlMockBinaryMessenger* messenger, FlValue* response,
         gpointer user_data) {
        EXPECT_EQ(fl_value_get_type(response), FL_VALUE_TYPE_NULL);
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
      },
      &called);
  EXPECT_TRUE(called);
  EXPECT_FALSE(signalled);

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}
