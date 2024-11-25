// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_platform_channel.h"
#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_channel.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_method_codec.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "gtest/gtest.h"

static void exit_method_response_cb(GObject* object,
                                    GAsyncResult* result,
                                    gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  FlPlatformChannelExitResponse response;
  gboolean success = fl_platform_channel_system_request_app_exit_finish(
      object, result, &response, &error);

  EXPECT_TRUE(success);
  EXPECT_EQ(response, FL_PLATFORM_CHANNEL_EXIT_RESPONSE_EXIT);

  g_main_loop_quit(static_cast<GMainLoop*>(user_data));
}

TEST(FlPlatformChannelTest, ExitResponse) {
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);

  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "test/standard-method", FL_METHOD_CODEC(codec));

  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "response", fl_value_new_string("exit"));

  fl_method_channel_invoke_method(channel, "Echo", args, nullptr,
                                  exit_method_response_cb, loop);

  // Blocks here until method_response_cb is called.
  g_main_loop_run(loop);
}
