// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_platform_plugin.h"
#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_method_codec_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_method_codec.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_codec.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/mock_binary_messenger.h"
#include "flutter/testing/testing.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

MATCHER_P(SuccessResponse, result, "") {
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(FlMethodResponse) response =
      fl_method_codec_decode_response(FL_METHOD_CODEC(codec), arg, nullptr);
  if (fl_value_equal(fl_method_response_get_result(response, nullptr),
                     result)) {
    return true;
  }
  *result_listener << ::testing::PrintToString(response);
  return false;
}

TEST(FlPlatformPluginTest, PlaySound) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;

  g_autoptr(FlPlatformPlugin) plugin = fl_platform_plugin_new(messenger);
  EXPECT_NE(plugin, nullptr);

  g_autoptr(FlValue) args = fl_value_new_string("SystemSoundType.alert");
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) message = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "SystemSound.play", args, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::_, SuccessResponse(null), ::testing::_))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/platform", message);
}
