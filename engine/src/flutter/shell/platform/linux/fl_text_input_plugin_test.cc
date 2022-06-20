// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_text_input_plugin.h"
#include "flutter/shell/platform/linux/fl_method_codec_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_method_codec.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_value.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/mock_binary_messenger.h"
#include "flutter/shell/platform/linux/testing/mock_binary_messenger_response_handle.h"
#include "flutter/testing/testing.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

void printTo(FlMethodResponse* response, ::std::ostream* os) {
  *os << ::testing::PrintToString(
      fl_method_response_get_result(response, nullptr));
}

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

static FlValue* build_map(std::map<const gchar*, FlValue*> args) {
  FlValue* value = fl_value_new_map();
  for (auto it = args.begin(); it != args.end(); ++it) {
    fl_value_set_string_take(value, it->first, it->second);
  }
  return value;
}

static FlValue* build_list(std::vector<FlValue*> args) {
  FlValue* value = fl_value_new_list();
  for (auto it = args.begin(); it != args.end(); ++it) {
    fl_value_append_take(value, *it);
  }
  return value;
}

TEST(FlTextInputPluginTest, SetClient) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  auto filter =
      +[](GtkIMContext* im_context, gpointer gdk_event) { return false; };

  fl_text_input_plugin_new(messenger, nullptr,
                           FlTextInputPluginImFilter(filter));

  EXPECT_TRUE(messenger.HasMessageHandler("flutter/textinput"));

  g_autoptr(FlValue) args = build_list({
      fl_value_new_int(1),  // client id
      build_map({
          {"inputAction", fl_value_new_string("")},
          {"inputType", build_map({
                            {"name", fl_value_new_string("TextInputType.text")},
                        })},
          {"enableDeltaModel", fl_value_new_bool(false)},
      }),
  });

  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) message = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "TextInput.setClient", args, nullptr);

  g_autoptr(FlValue) null = fl_value_new_null();
  EXPECT_CALL(messenger, fl_binary_messenger_send_response(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::A<FlBinaryMessengerResponseHandle*>(),
                             SuccessResponse(null), ::testing::A<GError**>()))
      .WillOnce(::testing::Return(true));

  messenger.ReceiveMessage("flutter/textinput", message);
}
