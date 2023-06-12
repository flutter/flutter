// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <string>

#include "messages.g.h"
#include "url_launcher_plugin.h"

namespace url_launcher_windows {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using ::testing::DoAll;
using ::testing::Pointee;
using ::testing::Return;
using ::testing::SetArgPointee;

class MockSystemApis : public SystemApis {
 public:
  MOCK_METHOD(LSTATUS, RegCloseKey, (HKEY key), (override));
  MOCK_METHOD(LSTATUS, RegQueryValueExW,
              (HKEY key, LPCWSTR value_name, LPDWORD type, LPBYTE data,
               LPDWORD data_size),
              (override));
  MOCK_METHOD(LSTATUS, RegOpenKeyExW,
              (HKEY key, LPCWSTR sub_key, DWORD options, REGSAM desired,
               PHKEY result),
              (override));
  MOCK_METHOD(HINSTANCE, ShellExecuteW,
              (HWND hwnd, LPCWSTR operation, LPCWSTR file, LPCWSTR parameters,
               LPCWSTR directory, int show_flags),
              (override));
};

}  // namespace

TEST(UrlLauncherPlugin, CanLaunchSuccessTrue) {
  std::unique_ptr<MockSystemApis> system = std::make_unique<MockSystemApis>();

  // Return success values from the registery commands.
  HKEY fake_key = reinterpret_cast<HKEY>(1);
  EXPECT_CALL(*system, RegOpenKeyExW)
      .WillOnce(DoAll(SetArgPointee<4>(fake_key), Return(ERROR_SUCCESS)));
  EXPECT_CALL(*system, RegQueryValueExW).WillOnce(Return(ERROR_SUCCESS));
  EXPECT_CALL(*system, RegCloseKey(fake_key)).WillOnce(Return(ERROR_SUCCESS));

  UrlLauncherPlugin plugin(std::move(system));
  ErrorOr<bool> result = plugin.CanLaunchUrl("https://some.url.com");

  ASSERT_FALSE(result.has_error());
  EXPECT_TRUE(result.value());
}

TEST(UrlLauncherPlugin, CanLaunchQueryFailure) {
  std::unique_ptr<MockSystemApis> system = std::make_unique<MockSystemApis>();

  // Return success values from the registery commands, except for the query,
  // to simulate a scheme that is in the registry, but has no URL handler.
  HKEY fake_key = reinterpret_cast<HKEY>(1);
  EXPECT_CALL(*system, RegOpenKeyExW)
      .WillOnce(DoAll(SetArgPointee<4>(fake_key), Return(ERROR_SUCCESS)));
  EXPECT_CALL(*system, RegQueryValueExW).WillOnce(Return(ERROR_FILE_NOT_FOUND));
  EXPECT_CALL(*system, RegCloseKey(fake_key)).WillOnce(Return(ERROR_SUCCESS));

  UrlLauncherPlugin plugin(std::move(system));
  ErrorOr<bool> result = plugin.CanLaunchUrl("https://some.url.com");

  ASSERT_FALSE(result.has_error());
  EXPECT_FALSE(result.value());
}

TEST(UrlLauncherPlugin, CanLaunchHandlesOpenFailure) {
  std::unique_ptr<MockSystemApis> system = std::make_unique<MockSystemApis>();

  // Return failure for opening.
  EXPECT_CALL(*system, RegOpenKeyExW).WillOnce(Return(ERROR_BAD_PATHNAME));

  UrlLauncherPlugin plugin(std::move(system));
  ErrorOr<bool> result = plugin.CanLaunchUrl("https://some.url.com");

  ASSERT_FALSE(result.has_error());
  EXPECT_FALSE(result.value());
}

TEST(UrlLauncherPlugin, LaunchSuccess) {
  std::unique_ptr<MockSystemApis> system = std::make_unique<MockSystemApis>();

  // Return a success value (>32) from launching.
  EXPECT_CALL(*system, ShellExecuteW)
      .WillOnce(Return(reinterpret_cast<HINSTANCE>(33)));

  UrlLauncherPlugin plugin(std::move(system));
  std::optional<FlutterError> error = plugin.LaunchUrl("https://some.url.com");

  EXPECT_FALSE(error.has_value());
}

TEST(UrlLauncherPlugin, LaunchReportsFailure) {
  std::unique_ptr<MockSystemApis> system = std::make_unique<MockSystemApis>();

  // Return a faile value (<=32) from launching.
  EXPECT_CALL(*system, ShellExecuteW)
      .WillOnce(Return(reinterpret_cast<HINSTANCE>(32)));

  UrlLauncherPlugin plugin(std::move(system));
  std::optional<FlutterError> error = plugin.LaunchUrl("https://some.url.com");

  EXPECT_TRUE(error.has_value());
}

}  // namespace test
}  // namespace url_launcher_windows
