// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_settings_plugin.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_message_codec.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_value.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/mock_binary_messenger.h"
#include "flutter/shell/platform/linux/testing/mock_settings.h"
#include "flutter/testing/testing.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

MATCHER_P2(HasSetting, key, value, "") {
  g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
  g_autoptr(FlValue) message =
      fl_message_codec_decode_message(FL_MESSAGE_CODEC(codec), arg, nullptr);
  if (fl_value_equal(fl_value_lookup_string(message, key), value)) {
    return true;
  }
  *result_listener << ::testing::PrintToString(message);
  return false;
}

#define EXPECT_SETTING(messenger, key, value)                                 \
  EXPECT_CALL(                                                                \
      messenger,                                                              \
      fl_binary_messenger_send_on_channel(                                    \
          ::testing::Eq<FlBinaryMessenger*>(messenger),                       \
          ::testing::StrEq("flutter/settings"), HasSetting(key, value),       \
          ::testing::A<GCancellable*>(), ::testing::A<GAsyncReadyCallback>(), \
          ::testing::A<gpointer>()))

TEST(FlSettingsPluginTest, AlwaysUse24HourFormat) {
  ::testing::NiceMock<flutter::testing::MockSettings> settings;
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;

  g_autoptr(FlEngine) engine =
      FL_ENGINE(g_object_new(fl_engine_get_type(), "binary-messenger",
                             FL_BINARY_MESSENGER(messenger), nullptr));
  g_autoptr(FlSettingsPlugin) plugin = fl_settings_plugin_new(engine);

  g_autoptr(FlValue) use_12h = fl_value_new_bool(false);
  g_autoptr(FlValue) use_24h = fl_value_new_bool(true);

  EXPECT_CALL(settings, fl_settings_get_clock_format(
                            ::testing::Eq<FlSettings*>(settings)))
      .WillOnce(::testing::Return(FL_CLOCK_FORMAT_12H))
      .WillOnce(::testing::Return(FL_CLOCK_FORMAT_24H));

  EXPECT_SETTING(messenger, "alwaysUse24HourFormat", use_12h);

  fl_settings_plugin_start(plugin, settings);

  EXPECT_SETTING(messenger, "alwaysUse24HourFormat", use_24h);

  fl_settings_emit_changed(settings);
}

TEST(FlSettingsPluginTest, PlatformBrightness) {
  ::testing::NiceMock<flutter::testing::MockSettings> settings;
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;

  g_autoptr(FlEngine) engine =
      FL_ENGINE(g_object_new(fl_engine_get_type(), "binary-messenger",
                             FL_BINARY_MESSENGER(messenger), nullptr));
  g_autoptr(FlSettingsPlugin) plugin = fl_settings_plugin_new(engine);

  g_autoptr(FlValue) light = fl_value_new_string("light");
  g_autoptr(FlValue) dark = fl_value_new_string("dark");

  EXPECT_CALL(settings, fl_settings_get_color_scheme(
                            ::testing::Eq<FlSettings*>(settings)))
      .WillOnce(::testing::Return(FL_COLOR_SCHEME_LIGHT))
      .WillOnce(::testing::Return(FL_COLOR_SCHEME_DARK));

  EXPECT_SETTING(messenger, "platformBrightness", light);

  fl_settings_plugin_start(plugin, settings);

  EXPECT_SETTING(messenger, "platformBrightness", dark);

  fl_settings_emit_changed(settings);
}

TEST(FlSettingsPluginTest, TextScaleFactor) {
  ::testing::NiceMock<flutter::testing::MockSettings> settings;
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;

  g_autoptr(FlEngine) engine =
      FL_ENGINE(g_object_new(fl_engine_get_type(), "binary-messenger",
                             FL_BINARY_MESSENGER(messenger), nullptr));
  g_autoptr(FlSettingsPlugin) plugin = fl_settings_plugin_new(engine);

  g_autoptr(FlValue) one = fl_value_new_float(1.0);
  g_autoptr(FlValue) two = fl_value_new_float(2.0);

  EXPECT_CALL(settings, fl_settings_get_text_scaling_factor(
                            ::testing::Eq<FlSettings*>(settings)))
      .WillOnce(::testing::Return(1.0))
      .WillOnce(::testing::Return(2.0));

  EXPECT_SETTING(messenger, "textScaleFactor", one);

  fl_settings_plugin_start(plugin, settings);

  EXPECT_SETTING(messenger, "textScaleFactor", two);

  fl_settings_emit_changed(settings);
}

// MOCK_ENGINE_PROC is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)
TEST(FlSettingsPluginTest, AccessibilityFeatures) {
  g_autoptr(FlEngine) engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);

  std::vector<FlutterAccessibilityFeature> calls;
  embedder_api->UpdateAccessibilityFeatures = MOCK_ENGINE_PROC(
      UpdateAccessibilityFeatures,
      ([&calls](auto engine, FlutterAccessibilityFeature features) {
        calls.push_back(features);
        return kSuccess;
      }));

  g_autoptr(FlSettingsPlugin) plugin = fl_settings_plugin_new(engine);

  ::testing::NiceMock<flutter::testing::MockSettings> settings;

  EXPECT_CALL(settings, fl_settings_get_enable_animations(
                            ::testing::Eq<FlSettings*>(settings)))
      .WillOnce(::testing::Return(false))
      .WillOnce(::testing::Return(true))
      .WillOnce(::testing::Return(false))
      .WillOnce(::testing::Return(true));

  EXPECT_CALL(settings, fl_settings_get_high_contrast(
                            ::testing::Eq<FlSettings*>(settings)))
      .WillOnce(::testing::Return(true))
      .WillOnce(::testing::Return(false))
      .WillOnce(::testing::Return(false))
      .WillOnce(::testing::Return(true));

  fl_settings_plugin_start(plugin, settings);
  EXPECT_THAT(calls, ::testing::SizeIs(1));
  EXPECT_EQ(calls.back(), static_cast<FlutterAccessibilityFeature>(
                              kFlutterAccessibilityFeatureDisableAnimations |
                              kFlutterAccessibilityFeatureHighContrast));

  fl_settings_emit_changed(settings);
  EXPECT_THAT(calls, ::testing::SizeIs(2));
  EXPECT_EQ(calls.back(), static_cast<FlutterAccessibilityFeature>(0));

  fl_settings_emit_changed(settings);
  EXPECT_THAT(calls, ::testing::SizeIs(3));
  EXPECT_EQ(calls.back(), static_cast<FlutterAccessibilityFeature>(
                              kFlutterAccessibilityFeatureDisableAnimations));

  fl_settings_emit_changed(settings);
  EXPECT_THAT(calls, ::testing::SizeIs(4));
  EXPECT_EQ(calls.back(), static_cast<FlutterAccessibilityFeature>(
                              kFlutterAccessibilityFeatureHighContrast));
}
// NOLINTEND(clang-analyzer-core.StackAddressEscape)
