// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/platform_handler.h"

#include <memory>

#include "flutter/shell/platform/common/json_method_codec.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/test_binary_messenger.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "rapidjson/document.h"

namespace flutter {
namespace testing {

namespace {
using ::testing::_;
using ::testing::NiceMock;
using ::testing::Return;

static constexpr char kChannelName[] = "flutter/platform";

static constexpr char kClipboardGetDataMessage[] =
    "{\"method\":\"Clipboard.getData\",\"args\":\"text/plain\"}";
static constexpr char kClipboardGetDataFakeContentTypeMessage[] =
    "{\"method\":\"Clipboard.getData\",\"args\":\"text/madeupcontenttype\"}";
static constexpr char kClipboardHasStringsMessage[] =
    "{\"method\":\"Clipboard.hasStrings\",\"args\":\"text/plain\"}";
static constexpr char kClipboardHasStringsFakeContentTypeMessage[] =
    "{\"method\":\"Clipboard.hasStrings\",\"args\":\"text/madeupcontenttype\"}";
static constexpr char kClipboardSetDataMessage[] =
    "{\"method\":\"Clipboard.setData\",\"args\":{\"text\":\"hello\"}}";
static constexpr char kClipboardSetDataUnknownTypeMessage[] =
    "{\"method\":\"Clipboard.setData\",\"args\":{\"madeuptype\":\"hello\"}}";
static constexpr char kSystemSoundTypeAlertMessage[] =
    "{\"method\":\"SystemSound.play\",\"args\":\"SystemSoundType.alert\"}";

static constexpr int kAccessDeniedErrorCode = 5;
static constexpr int kErrorSuccess = 0;
static constexpr int kArbitraryErrorCode = 1;

// Test implementation of PlatformHandler to allow testing the PlatformHandler
// logic.
class MockPlatformHandler : public PlatformHandler {
 public:
  explicit MockPlatformHandler(
      BinaryMessenger* messenger,
      FlutterWindowsEngine* engine,
      std::optional<std::function<std::unique_ptr<ScopedClipboardInterface>()>>
          scoped_clipboard_provider = std::nullopt)
      : PlatformHandler(messenger, engine, scoped_clipboard_provider) {}

  virtual ~MockPlatformHandler() = default;

  MOCK_METHOD2(GetPlainText,
               void(std::unique_ptr<MethodResult<rapidjson::Document>>,
                    std::string_view key));
  MOCK_METHOD1(GetHasStrings,
               void(std::unique_ptr<MethodResult<rapidjson::Document>>));
  MOCK_METHOD2(SetPlainText,
               void(const std::string&,
                    std::unique_ptr<MethodResult<rapidjson::Document>>));
  MOCK_METHOD2(SystemSoundPlay,
               void(const std::string&,
                    std::unique_ptr<MethodResult<rapidjson::Document>>));
};

// A test version of the private ScopedClipboard.
class MockScopedClipboard : public ScopedClipboardInterface {
 public:
  MOCK_METHOD(int, Open, (HWND window), (override));
  MOCK_METHOD(bool, HasString, (), (override));
  MOCK_METHOD((std::variant<std::wstring, int>), GetString, (), (override));
  MOCK_METHOD(int, SetString, (const std::wstring string), (override));
};

std::string SimulatePlatformMessage(TestBinaryMessenger* messenger,
                                    std::string message) {
  std::string result;
  EXPECT_TRUE(messenger->SimulateEngineMessage(
      kChannelName, reinterpret_cast<const uint8_t*>(message.c_str()),
      message.size(),
      [result = &result](const uint8_t* reply, size_t reply_size) {
        std::string response(reinterpret_cast<const char*>(reply), reply_size);

        *result = response;
      }));

  return result;
}

}  // namespace

class PlatformHandlerTest : public ::testing::Test {
 protected:
  FlutterWindowsEngine* engine() { return engine_.get(); }

  void use_headless_engine() {
    // Set properties required to create the engine.
    FlutterDesktopEngineProperties properties = {};
    properties.assets_path = L"C:\\foo\\flutter_assets";
    properties.icu_data_path = L"C:\\foo\\icudtl.dat";
    properties.aot_library_path = L"C:\\foo\\aot.so";
    FlutterProjectBundle project(properties);

    engine_ = std::make_unique<FlutterWindowsEngine>(project);
  }

  void use_engine_with_view() {
    use_headless_engine();

    auto window = std::make_unique<NiceMock<MockWindowBindingHandler>>();
    view_ = std::make_unique<FlutterWindowsView>(std::move(window));

    engine_->SetView(view_.get());
  }

 private:
  std::unique_ptr<FlutterWindowsEngine> engine_;
  std::unique_ptr<FlutterWindowsView> view_;
};

TEST_F(PlatformHandlerTest, GetClipboardData) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine(), []() {
    auto clipboard = std::make_unique<MockScopedClipboard>();

    EXPECT_CALL(*clipboard.get(), Open)
        .Times(1)
        .WillOnce(Return(kErrorSuccess));
    EXPECT_CALL(*clipboard.get(), HasString).Times(1).WillOnce(Return(true));
    EXPECT_CALL(*clipboard.get(), GetString)
        .Times(1)
        .WillOnce(Return(std::wstring(L"Hello world")));

    return clipboard;
  });

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardGetDataMessage);

  EXPECT_EQ(result, "[{\"text\":\"Hello world\"}]");
}

TEST_F(PlatformHandlerTest, GetClipboardDataRejectsUnknownContentType) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine());

  // Requesting an unknown content type is an error.
  std::string result = SimulatePlatformMessage(
      &messenger, kClipboardGetDataFakeContentTypeMessage);

  EXPECT_EQ(result, "[\"Clipboard error\",\"Unknown clipboard format\",null]");
}

TEST_F(PlatformHandlerTest, GetClipboardDataRequiresView) {
  use_headless_engine();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine());

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardGetDataMessage);

  EXPECT_EQ(result,
            "[\"Clipboard error\",\"Clipboard is not available in "
            "Windows headless mode\",null]");
}

TEST_F(PlatformHandlerTest, GetClipboardDataReportsOpenFailure) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine(), []() {
    auto clipboard = std::make_unique<MockScopedClipboard>();

    EXPECT_CALL(*clipboard.get(), Open)
        .Times(1)
        .WillOnce(Return(kArbitraryErrorCode));

    return clipboard;
  });

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardGetDataMessage);

  EXPECT_EQ(result, "[\"Clipboard error\",\"Unable to open clipboard\",1]");
}

TEST_F(PlatformHandlerTest, GetClipboardDataReportsGetDataFailure) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine(), []() {
    auto clipboard = std::make_unique<MockScopedClipboard>();

    EXPECT_CALL(*clipboard.get(), Open)
        .Times(1)
        .WillOnce(Return(kErrorSuccess));
    EXPECT_CALL(*clipboard.get(), HasString).Times(1).WillOnce(Return(true));
    EXPECT_CALL(*clipboard.get(), GetString)
        .Times(1)
        .WillOnce(Return(kArbitraryErrorCode));

    return clipboard;
  });

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardGetDataMessage);

  EXPECT_EQ(result, "[\"Clipboard error\",\"Unable to get clipboard data\",1]");
}

TEST_F(PlatformHandlerTest, ClipboardHasStrings) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine(), []() {
    auto clipboard = std::make_unique<MockScopedClipboard>();

    EXPECT_CALL(*clipboard.get(), Open)
        .Times(1)
        .WillOnce(Return(kErrorSuccess));
    EXPECT_CALL(*clipboard.get(), HasString).Times(1).WillOnce(Return(true));

    return clipboard;
  });

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardHasStringsMessage);

  EXPECT_EQ(result, "[{\"value\":true}]");
}

TEST_F(PlatformHandlerTest, ClipboardHasStringsReturnsFalse) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine(), []() {
    auto clipboard = std::make_unique<MockScopedClipboard>();

    EXPECT_CALL(*clipboard.get(), Open)
        .Times(1)
        .WillOnce(Return(kErrorSuccess));
    EXPECT_CALL(*clipboard.get(), HasString).Times(1).WillOnce(Return(false));

    return clipboard;
  });

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardHasStringsMessage);

  EXPECT_EQ(result, "[{\"value\":false}]");
}

TEST_F(PlatformHandlerTest, ClipboardHasStringsRejectsUnknownContentType) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine());

  std::string result = SimulatePlatformMessage(
      &messenger, kClipboardHasStringsFakeContentTypeMessage);

  EXPECT_EQ(result, "[\"Clipboard error\",\"Unknown clipboard format\",null]");
}

TEST_F(PlatformHandlerTest, ClipboardHasStringsRequiresView) {
  use_headless_engine();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine());

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardHasStringsMessage);

  EXPECT_EQ(result,
            "[\"Clipboard error\",\"Clipboard is not available in Windows "
            "headless mode\",null]");
}

// Regression test for https://github.com/flutter/flutter/issues/95817.
TEST_F(PlatformHandlerTest, ClipboardHasStringsIgnoresPermissionErrors) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine(), []() {
    auto clipboard = std::make_unique<MockScopedClipboard>();

    EXPECT_CALL(*clipboard.get(), Open)
        .Times(1)
        .WillOnce(Return(kAccessDeniedErrorCode));

    return clipboard;
  });

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardHasStringsMessage);

  EXPECT_EQ(result, "[{\"value\":false}]");
}

TEST_F(PlatformHandlerTest, ClipboardHasStringsReportsErrors) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine(), []() {
    auto clipboard = std::make_unique<MockScopedClipboard>();

    EXPECT_CALL(*clipboard.get(), Open)
        .Times(1)
        .WillOnce(Return(kArbitraryErrorCode));

    return clipboard;
  });

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardHasStringsMessage);

  EXPECT_EQ(result, "[\"Clipboard error\",\"Unable to open clipboard\",1]");
}

TEST_F(PlatformHandlerTest, ClipboardSetData) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine(), []() {
    auto clipboard = std::make_unique<MockScopedClipboard>();

    EXPECT_CALL(*clipboard.get(), Open)
        .Times(1)
        .WillOnce(Return(kErrorSuccess));
    EXPECT_CALL(*clipboard.get(), SetString)
        .Times(1)
        .WillOnce([](std::wstring string) {
          EXPECT_EQ(string, L"hello");
          return kErrorSuccess;
        });

    return clipboard;
  });

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardSetDataMessage);

  EXPECT_EQ(result, "[null]");
}

TEST_F(PlatformHandlerTest, ClipboardSetDataUnknownType) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine());

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardSetDataUnknownTypeMessage);

  EXPECT_EQ(result, "[\"Clipboard error\",\"Unknown clipboard format\",null]");
}

TEST_F(PlatformHandlerTest, ClipboardSetDataRequiresView) {
  use_headless_engine();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine());

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardSetDataMessage);

  EXPECT_EQ(result,
            "[\"Clipboard error\",\"Clipboard is not available in Windows "
            "headless mode\",null]");
}

TEST_F(PlatformHandlerTest, ClipboardSetDataReportsOpenFailure) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine(), []() {
    auto clipboard = std::make_unique<MockScopedClipboard>();

    EXPECT_CALL(*clipboard.get(), Open)
        .Times(1)
        .WillOnce(Return(kArbitraryErrorCode));

    return clipboard;
  });

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardSetDataMessage);

  EXPECT_EQ(result, "[\"Clipboard error\",\"Unable to open clipboard\",1]");
}

TEST_F(PlatformHandlerTest, ClipboardSetDataReportsSetDataFailure) {
  use_engine_with_view();

  TestBinaryMessenger messenger;
  PlatformHandler platform_handler(&messenger, engine(), []() {
    auto clipboard = std::make_unique<MockScopedClipboard>();

    EXPECT_CALL(*clipboard.get(), Open)
        .Times(1)
        .WillOnce(Return(kErrorSuccess));
    EXPECT_CALL(*clipboard.get(), SetString)
        .Times(1)
        .WillOnce(Return(kArbitraryErrorCode));

    return clipboard;
  });

  std::string result =
      SimulatePlatformMessage(&messenger, kClipboardSetDataMessage);

  EXPECT_EQ(result, "[\"Clipboard error\",\"Unable to set clipboard data\",1]");
}

TEST_F(PlatformHandlerTest, PlaySystemSound) {
  use_headless_engine();

  TestBinaryMessenger messenger;
  MockPlatformHandler platform_handler(&messenger, engine());

  EXPECT_CALL(platform_handler, SystemSoundPlay("SystemSoundType.alert", _))
      .WillOnce([](const std::string& sound,
                   std::unique_ptr<MethodResult<rapidjson::Document>> result) {
        result->Success();
      });

  std::string result =
      SimulatePlatformMessage(&messenger, kSystemSoundTypeAlertMessage);

  EXPECT_EQ(result, "[null]");
}

}  // namespace testing
}  // namespace flutter
