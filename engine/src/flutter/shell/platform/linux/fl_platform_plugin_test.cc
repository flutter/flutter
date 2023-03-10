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

class MethodCallMatcher {
 public:
  using is_gtest_matcher = void;

  explicit MethodCallMatcher(::testing::Matcher<std::string> name,
                             ::testing::Matcher<FlValue*> args)
      : name_(std::move(name)), args_(std::move(args)) {}

  bool MatchAndExplain(GBytes* method_call,
                       ::testing::MatchResultListener* result_listener) const {
    g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
    g_autoptr(GError) error = nullptr;
    g_autofree gchar* name = nullptr;
    g_autoptr(FlValue) args = nullptr;
    gboolean result = fl_method_codec_decode_method_call(
        FL_METHOD_CODEC(codec), method_call, &name, &args, &error);
    if (!result) {
      *result_listener << ::testing::PrintToString(error->message);
      return false;
    }
    if (!name_.MatchAndExplain(name, result_listener)) {
      *result_listener << " where the name doesn't match: \"" << name << "\"";
      return false;
    }
    if (!args_.MatchAndExplain(args, result_listener)) {
      *result_listener << " where the args don't match: "
                       << ::testing::PrintToString(args);
      return false;
    }
    return true;
  }

  void DescribeTo(std::ostream* os) const {
    *os << "method name ";
    name_.DescribeTo(os);
    *os << " and args ";
    args_.DescribeTo(os);
  }

  void DescribeNegationTo(std::ostream* os) const {
    *os << "method name ";
    name_.DescribeNegationTo(os);
    *os << " or args ";
    args_.DescribeNegationTo(os);
  }

 private:
  ::testing::Matcher<std::string> name_;
  ::testing::Matcher<FlValue*> args_;
};

static ::testing::Matcher<GBytes*> MethodCall(
    const std::string& name,
    ::testing::Matcher<FlValue*> args) {
  return MethodCallMatcher(::testing::StrEq(name), std::move(args));
}

MATCHER_P(FlValueEq, value, "equal to " + ::testing::PrintToString(value)) {
  return fl_value_equal(arg, value);
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

TEST(FlPlatformPluginTest, ExitApplication) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;

  g_autoptr(FlPlatformPlugin) plugin = fl_platform_plugin_new(messenger);
  EXPECT_NE(plugin, nullptr);

  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "type", fl_value_new_string("cancelable"));
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();
  g_autoptr(GBytes) message = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "System.exitApplication", args, nullptr);

  g_autoptr(FlValue) requestArgs = fl_value_new_map();
  fl_value_set_string_take(requestArgs, "type",
                           fl_value_new_string("cancelable"));
  EXPECT_CALL(messenger,
              fl_binary_messenger_send_on_channel(
                  ::testing::Eq<FlBinaryMessenger*>(messenger),
                  ::testing::StrEq("flutter/platform"),
                  MethodCall("System.requestAppExit", FlValueEq(requestArgs)),
                  ::testing::_, ::testing::_, ::testing::_));

  messenger.ReceiveMessage("flutter/platform", message);
}
