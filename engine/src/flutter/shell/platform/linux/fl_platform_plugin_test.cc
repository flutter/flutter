// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gtk/gtk.h>

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_method_codec_private.h"
#include "flutter/shell/platform/linux/fl_platform_plugin.h"
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

G_DECLARE_FINAL_TYPE(FlTestApplication,
                     fl_test_application,
                     FL,
                     TEST_APPLICATION,
                     GtkApplication)

struct _FlTestApplication {
  GtkApplication parent_instance;
  gboolean* dispose_called;
};

G_DEFINE_TYPE(FlTestApplication,
              fl_test_application,
              gtk_application_get_type())

static void fl_test_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(fl_test_application_parent_class)->startup(application);

  // Add a window to this application, which will hold a reference to the
  // application and stop it disposing. See
  // https://gitlab.gnome.org/GNOME/gtk/-/issues/6190
  gtk_application_window_new(GTK_APPLICATION(application));
}

static void fl_test_application_activate(GApplication* application) {
  G_APPLICATION_CLASS(fl_test_application_parent_class)->activate(application);

  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  g_autoptr(FlPlatformPlugin) plugin = fl_platform_plugin_new(messenger);
  EXPECT_NE(plugin, nullptr);
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();

  g_autoptr(FlValue) exit_result = fl_value_new_map();
  fl_value_set_string_take(exit_result, "response",
                           fl_value_new_string("exit"));
  EXPECT_CALL(messenger,
              fl_binary_messenger_send_response(
                  ::testing::Eq<FlBinaryMessenger*>(messenger), ::testing::_,
                  SuccessResponse(exit_result), ::testing::_))
      .WillOnce(::testing::Return(true));

  // Request app exit.
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "type", fl_value_new_string("required"));
  g_autoptr(GBytes) message = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "System.exitApplication", args, nullptr);
  messenger.ReceiveMessage("flutter/platform", message);
}

static void fl_test_application_dispose(GObject* object) {
  FlTestApplication* self = FL_TEST_APPLICATION(object);

  *self->dispose_called = true;

  G_OBJECT_CLASS(fl_test_application_parent_class)->dispose(object);
}

static void fl_test_application_class_init(FlTestApplicationClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_test_application_dispose;
  G_APPLICATION_CLASS(klass)->startup = fl_test_application_startup;
  G_APPLICATION_CLASS(klass)->activate = fl_test_application_activate;
}

static void fl_test_application_init(FlTestApplication* self) {}

FlTestApplication* fl_test_application_new(gboolean* dispose_called) {
  FlTestApplication* self = FL_TEST_APPLICATION(
      g_object_new(fl_test_application_get_type(), nullptr));

  // Don't try and register on D-Bus.
  g_application_set_application_id(G_APPLICATION(self), "dev.flutter.GtkTest");
  g_application_set_flags(G_APPLICATION(self), G_APPLICATION_NON_UNIQUE);

  // Added to stop compiler complaining about an unused function.
  FL_IS_TEST_APPLICATION(self);

  self->dispose_called = dispose_called;

  return self;
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
  g_autoptr(FlJsonMethodCodec) codec = fl_json_method_codec_new();

  g_autoptr(FlValue) null = fl_value_new_null();
  ON_CALL(messenger, fl_binary_messenger_send_response(
                         ::testing::Eq<FlBinaryMessenger*>(messenger),
                         ::testing::_, SuccessResponse(null), ::testing::_))
      .WillByDefault(testing::Return(TRUE));

  // Indicate that the binding is initialized.
  g_autoptr(GError) error = nullptr;
  g_autoptr(GBytes) init_message = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "System.initializationComplete", nullptr, &error);
  messenger.ReceiveMessage("flutter/platform", init_message);

  g_autoptr(FlValue) request_args = fl_value_new_map();
  fl_value_set_string_take(request_args, "type",
                           fl_value_new_string("cancelable"));
  EXPECT_CALL(messenger,
              fl_binary_messenger_send_on_channel(
                  ::testing::Eq<FlBinaryMessenger*>(messenger),
                  ::testing::StrEq("flutter/platform"),
                  MethodCall("System.requestAppExit", FlValueEq(request_args)),
                  ::testing::_, ::testing::_, ::testing::_));

  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "type", fl_value_new_string("cancelable"));
  g_autoptr(GBytes) message = fl_method_codec_encode_method_call(
      FL_METHOD_CODEC(codec), "System.exitApplication", args, nullptr);
  messenger.ReceiveMessage("flutter/platform", message);
}

TEST(FlPlatformPluginTest, ExitApplicationDispose) {
  gtk_init(0, nullptr);

  gboolean dispose_called = false;
  FlTestApplication* application = fl_test_application_new(&dispose_called);

  // Run the application, it will quit after startup.
  g_application_run(G_APPLICATION(application), 0, nullptr);

  EXPECT_FALSE(dispose_called);
  g_object_unref(application);
  EXPECT_TRUE(dispose_called);
}
