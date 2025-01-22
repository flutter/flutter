// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_keyboard_handler.h"

#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_method_codec_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_method_codec.h"
#include "flutter/shell/platform/linux/testing/fl_mock_binary_messenger.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

static constexpr char kKeyboardChannelName[] = "flutter/keyboard";
static constexpr char kGetKeyboardStateMethod[] = "getKeyboardState";
static constexpr uint64_t kMockPhysicalKey = 42;
static constexpr uint64_t kMockLogicalKey = 42;

TEST(FlKeyboardHandlerTest, KeyboardChannelGetPressedState) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  g_autoptr(FlEngine) engine =
      fl_engine_new_with_binary_messenger(FL_BINARY_MESSENGER(messenger));
  g_autoptr(FlKeyboardManager) manager = fl_keyboard_manager_new(engine);
  fl_keyboard_manager_set_get_pressed_state_handler(
      manager,
      [](gpointer user_data) {
        GHashTable* result = g_hash_table_new(g_direct_hash, g_direct_equal);
        g_hash_table_insert(result,
                            reinterpret_cast<gpointer>(kMockPhysicalKey),
                            reinterpret_cast<gpointer>(kMockLogicalKey));

        return result;
      },
      nullptr);
  g_autoptr(FlKeyboardHandler) handler =
      fl_keyboard_handler_new(FL_BINARY_MESSENGER(messenger), manager);
  EXPECT_NE(handler, nullptr);

  gboolean called = FALSE;
  fl_mock_binary_messenger_invoke_standard_method(
      messenger, kKeyboardChannelName, kGetKeyboardStateMethod, nullptr,
      [](FlMockBinaryMessenger* messenger, FlMethodResponse* response,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;

        EXPECT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));

        g_autoptr(FlValue) expected_result = fl_value_new_map();
        fl_value_set_take(expected_result, fl_value_new_int(kMockPhysicalKey),
                          fl_value_new_int(kMockLogicalKey));
        EXPECT_TRUE(fl_value_equal(fl_method_success_response_get_result(
                                       FL_METHOD_SUCCESS_RESPONSE(response)),
                                   expected_result));
      },
      &called);
  EXPECT_TRUE(called);
}
