// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include <flutter_linux/flutter_linux.h>
#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <memory>
#include <string>

#include "include/url_launcher_linux/url_launcher_plugin.h"
#include "url_launcher_plugin_private.h"

namespace url_launcher_plugin {
namespace test {

TEST(UrlLauncherPlugin, CanLaunchSuccess) {
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "url",
                           fl_value_new_string("https://flutter.dev"));
  g_autoptr(FlMethodResponse) response = can_launch(nullptr, args);
  ASSERT_NE(response, nullptr);
  ASSERT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  g_autoptr(FlValue) expected = fl_value_new_bool(true);
  EXPECT_TRUE(fl_value_equal(fl_method_success_response_get_result(
                                 FL_METHOD_SUCCESS_RESPONSE(response)),
                             expected));
}

TEST(UrlLauncherPlugin, CanLaunchFailureUnhandled) {
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "url", fl_value_new_string("madeup:scheme"));
  g_autoptr(FlMethodResponse) response = can_launch(nullptr, args);
  ASSERT_NE(response, nullptr);
  ASSERT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  g_autoptr(FlValue) expected = fl_value_new_bool(false);
  EXPECT_TRUE(fl_value_equal(fl_method_success_response_get_result(
                                 FL_METHOD_SUCCESS_RESPONSE(response)),
                             expected));
}

TEST(UrlLauncherPlugin, CanLaunchFileSuccess) {
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "url", fl_value_new_string("file:///"));
  g_autoptr(FlMethodResponse) response = can_launch(nullptr, args);
  ASSERT_NE(response, nullptr);
  ASSERT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  g_autoptr(FlValue) expected = fl_value_new_bool(true);
  EXPECT_TRUE(fl_value_equal(fl_method_success_response_get_result(
                                 FL_METHOD_SUCCESS_RESPONSE(response)),
                             expected));
}

TEST(UrlLauncherPlugin, CanLaunchFailureInvalidFileExtension) {
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(
      args, "url", fl_value_new_string("file:///madeup.madeupextension"));
  g_autoptr(FlMethodResponse) response = can_launch(nullptr, args);
  ASSERT_NE(response, nullptr);
  ASSERT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  g_autoptr(FlValue) expected = fl_value_new_bool(false);
  EXPECT_TRUE(fl_value_equal(fl_method_success_response_get_result(
                                 FL_METHOD_SUCCESS_RESPONSE(response)),
                             expected));
}

// For consistency with the established mobile implementations,
// an invalid URL should return false, not an error.
TEST(UrlLauncherPlugin, CanLaunchFailureInvalidUrl) {
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "url", fl_value_new_string(""));
  g_autoptr(FlMethodResponse) response = can_launch(nullptr, args);
  ASSERT_NE(response, nullptr);
  ASSERT_TRUE(FL_IS_METHOD_SUCCESS_RESPONSE(response));
  g_autoptr(FlValue) expected = fl_value_new_bool(false);
  EXPECT_TRUE(fl_value_equal(fl_method_success_response_get_result(
                                 FL_METHOD_SUCCESS_RESPONSE(response)),
                             expected));
}

}  // namespace test
}  // namespace url_launcher_plugin
