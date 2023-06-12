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
#include <string>

#include "url_launcher_plugin.h"

namespace url_launcher_plugin {
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

class MockMethodResult : public flutter::MethodResult<> {
 public:
  MOCK_METHOD(void, SuccessInternal, (const EncodableValue* result),
              (override));
  MOCK_METHOD(void, ErrorInternal,
              (const std::string& error_code, const std::string& error_message,
               const EncodableValue* details),
              (override));
  MOCK_METHOD(void, NotImplementedInternal, (), (override));
};

std::unique_ptr<EncodableValue> CreateArgumentsWithUrl(const std::string& url) {
  EncodableMap args = {
      {EncodableValue("url"), EncodableValue(url)},
  };
  return std::make_unique<EncodableValue>(args);
}

}  // namespace

TEST(UrlLauncherPlugin, CanLaunchSuccessTrue) {
  std::unique_ptr<MockSystemApis> system = std::make_unique<MockSystemApis>();
  std::unique_ptr<MockMethodResult> result =
      std::make_unique<MockMethodResult>();

  // Return success values from the registery commands.
  HKEY fake_key = reinterpret_cast<HKEY>(1);
  EXPECT_CALL(*system, RegOpenKeyExW)
      .WillOnce(DoAll(SetArgPointee<4>(fake_key), Return(ERROR_SUCCESS)));
  EXPECT_CALL(*system, RegQueryValueExW).WillOnce(Return(ERROR_SUCCESS));
  EXPECT_CALL(*system, RegCloseKey(fake_key)).WillOnce(Return(ERROR_SUCCESS));
  // Expect a success response.
  EXPECT_CALL(*result, SuccessInternal(Pointee(EncodableValue(true))));

  UrlLauncherPlugin plugin(std::move(system));
  plugin.HandleMethodCall(
      flutter::MethodCall("canLaunch",
                          CreateArgumentsWithUrl("https://some.url.com")),
      std::move(result));
}

TEST(UrlLauncherPlugin, CanLaunchQueryFailure) {
  std::unique_ptr<MockSystemApis> system = std::make_unique<MockSystemApis>();
  std::unique_ptr<MockMethodResult> result =
      std::make_unique<MockMethodResult>();

  // Return success values from the registery commands, except for the query,
  // to simulate a scheme that is in the registry, but has no URL handler.
  HKEY fake_key = reinterpret_cast<HKEY>(1);
  EXPECT_CALL(*system, RegOpenKeyExW)
      .WillOnce(DoAll(SetArgPointee<4>(fake_key), Return(ERROR_SUCCESS)));
  EXPECT_CALL(*system, RegQueryValueExW).WillOnce(Return(ERROR_FILE_NOT_FOUND));
  EXPECT_CALL(*system, RegCloseKey(fake_key)).WillOnce(Return(ERROR_SUCCESS));
  // Expect a success response.
  EXPECT_CALL(*result, SuccessInternal(Pointee(EncodableValue(false))));

  UrlLauncherPlugin plugin(std::move(system));
  plugin.HandleMethodCall(
      flutter::MethodCall("canLaunch",
                          CreateArgumentsWithUrl("https://some.url.com")),
      std::move(result));
}

TEST(UrlLauncherPlugin, CanLaunchHandlesOpenFailure) {
  std::unique_ptr<MockSystemApis> system = std::make_unique<MockSystemApis>();
  std::unique_ptr<MockMethodResult> result =
      std::make_unique<MockMethodResult>();

  // Return failure for opening.
  EXPECT_CALL(*system, RegOpenKeyExW).WillOnce(Return(ERROR_BAD_PATHNAME));
  // Expect a success response.
  EXPECT_CALL(*result, SuccessInternal(Pointee(EncodableValue(false))));

  UrlLauncherPlugin plugin(std::move(system));
  plugin.HandleMethodCall(
      flutter::MethodCall("canLaunch",
                          CreateArgumentsWithUrl("https://some.url.com")),
      std::move(result));
}

TEST(UrlLauncherPlugin, LaunchSuccess) {
  std::unique_ptr<MockSystemApis> system = std::make_unique<MockSystemApis>();
  std::unique_ptr<MockMethodResult> result =
      std::make_unique<MockMethodResult>();

  // Return a success value (>32) from launching.
  EXPECT_CALL(*system, ShellExecuteW)
      .WillOnce(Return(reinterpret_cast<HINSTANCE>(33)));
  // Expect a success response.
  EXPECT_CALL(*result, SuccessInternal(Pointee(EncodableValue(true))));

  UrlLauncherPlugin plugin(std::move(system));
  plugin.HandleMethodCall(
      flutter::MethodCall("launch",
                          CreateArgumentsWithUrl("https://some.url.com")),
      std::move(result));
}

TEST(UrlLauncherPlugin, LaunchReportsFailure) {
  std::unique_ptr<MockSystemApis> system = std::make_unique<MockSystemApis>();
  std::unique_ptr<MockMethodResult> result =
      std::make_unique<MockMethodResult>();

  // Return a faile value (<=32) from launching.
  EXPECT_CALL(*system, ShellExecuteW)
      .WillOnce(Return(reinterpret_cast<HINSTANCE>(32)));
  // Expect an error response.
  EXPECT_CALL(*result, ErrorInternal);

  UrlLauncherPlugin plugin(std::move(system));
  plugin.HandleMethodCall(
      flutter::MethodCall("launch",
                          CreateArgumentsWithUrl("https://some.url.com")),
      std::move(result));
}

}  // namespace test
}  // namespace url_launcher_plugin
