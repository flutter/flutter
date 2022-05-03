// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/platform_handler_win32.h"

#include <memory>

#include "flutter/shell/platform/common/json_method_codec.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/test_binary_messenger.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "rapidjson/document.h"

namespace flutter {
namespace testing {

namespace {
using ::testing::_;

static constexpr char kChannelName[] = "flutter/platform";

static constexpr char kHasStringsClipboardMethod[] = "Clipboard.hasStrings";

static constexpr char kTextPlainFormat[] = "text/plain";

static constexpr char kValueKey[] = "value";
static constexpr int kAccessDeniedErrorCode = 5;
static constexpr int kErrorSuccess = 0;
static constexpr int kArbitraryErrorCode = 1;

}  // namespace

// A test version of the private ScopedClipboard.
class TestScopedClipboard : public ScopedClipboardInterface {
 public:
  TestScopedClipboard(int open_error, bool has_strings);
  ~TestScopedClipboard();

  // Prevent copying.
  TestScopedClipboard(TestScopedClipboard const&) = delete;
  TestScopedClipboard& operator=(TestScopedClipboard const&) = delete;

  int Open(HWND window) override;

  bool HasString() override;

  std::variant<std::wstring, int> GetString() override;

  int SetString(const std::wstring string) override;

 private:
  bool opened_ = false;
  bool has_strings_;
  int open_error_;
};

TestScopedClipboard::TestScopedClipboard(int open_error, bool has_strings) {
  open_error_ = open_error;
  has_strings_ = has_strings;
};

TestScopedClipboard::~TestScopedClipboard() {
  if (opened_) {
    ::CloseClipboard();
  }
}

int TestScopedClipboard::Open(HWND window) {
  return open_error_;
}

bool TestScopedClipboard::HasString() {
  return has_strings_;
}

std::variant<std::wstring, int> TestScopedClipboard::GetString() {
  return -1;
}

int TestScopedClipboard::SetString(const std::wstring string) {
  return -1;
}

class MockMethodResult : public MethodResult<rapidjson::Document> {
 public:
  MOCK_METHOD1(SuccessInternal, void(const rapidjson::Document*));
  MOCK_METHOD3(ErrorInternal,
               void(const std::string&,
                    const std::string&,
                    const rapidjson::Document*));
  MOCK_METHOD0(NotImplementedInternal, void());
};

// Regression test for https://github.com/flutter/flutter/issues/95817.
TEST(PlatformHandlerWin32, HasStringsAccessDeniedReturnsFalseWithoutError) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  // HasStrings will receive access denied on the clipboard, but will return
  // false without error.
  PlatformHandlerWin32 platform_handler(
      &messenger, &view,
      std::make_unique<TestScopedClipboard>(kAccessDeniedErrorCode, true));

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kStringType);
  auto& allocator = args->GetAllocator();
  args->SetString(kTextPlainFormat);
  auto encoded = JsonMethodCodec::GetInstance().EncodeMethodCall(
      MethodCall<rapidjson::Document>(kHasStringsClipboardMethod,
                                      std::move(args)));

  MockMethodResult result;
  rapidjson::Document document;
  document.SetObject();
  rapidjson::Document::AllocatorType& document_allocator =
      document.GetAllocator();
  document.AddMember(rapidjson::Value(kValueKey, document_allocator),
                     rapidjson::Value(false), document_allocator);

  EXPECT_CALL(result, SuccessInternal(_))
      .WillOnce([](const rapidjson::Document* document) {
        ASSERT_FALSE((*document)[kValueKey].GetBool());
      });
  EXPECT_TRUE(messenger.SimulateEngineMessage(
      kChannelName, encoded->data(), encoded->size(),
      [&](const uint8_t* reply, size_t reply_size) {
        JsonMethodCodec::GetInstance().DecodeAndProcessResponseEnvelope(
            reply, reply_size, &result);
      }));
}

TEST(PlatformHandlerWin32, HasStringsSuccessWithStrings) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  // HasStrings will succeed and return true.
  PlatformHandlerWin32 platform_handler(
      &messenger, &view,
      std::make_unique<TestScopedClipboard>(kErrorSuccess, true));

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kStringType);
  auto& allocator = args->GetAllocator();
  args->SetString(kTextPlainFormat);
  auto encoded = JsonMethodCodec::GetInstance().EncodeMethodCall(
      MethodCall<rapidjson::Document>(kHasStringsClipboardMethod,
                                      std::move(args)));

  MockMethodResult result;
  rapidjson::Document document;
  document.SetObject();
  rapidjson::Document::AllocatorType& document_allocator =
      document.GetAllocator();
  document.AddMember(rapidjson::Value(kValueKey, document_allocator),
                     rapidjson::Value(false), document_allocator);

  EXPECT_CALL(result, SuccessInternal(_))
      .WillOnce([](const rapidjson::Document* document) {
        ASSERT_TRUE((*document)[kValueKey].GetBool());
      });
  EXPECT_TRUE(messenger.SimulateEngineMessage(
      kChannelName, encoded->data(), encoded->size(),
      [&](const uint8_t* reply, size_t reply_size) {
        JsonMethodCodec::GetInstance().DecodeAndProcessResponseEnvelope(
            reply, reply_size, &result);
      }));
}

TEST(PlatformHandlerWin32, HasStringsSuccessWithoutStrings) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  // HasStrings will succeed and return false.
  PlatformHandlerWin32 platform_handler(
      &messenger, &view,
      std::make_unique<TestScopedClipboard>(kErrorSuccess, false));

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kStringType);
  auto& allocator = args->GetAllocator();
  args->SetString(kTextPlainFormat);
  auto encoded = JsonMethodCodec::GetInstance().EncodeMethodCall(
      MethodCall<rapidjson::Document>(kHasStringsClipboardMethod,
                                      std::move(args)));

  MockMethodResult result;
  rapidjson::Document document;
  document.SetObject();
  rapidjson::Document::AllocatorType& document_allocator =
      document.GetAllocator();
  document.AddMember(rapidjson::Value(kValueKey, document_allocator),
                     rapidjson::Value(false), document_allocator);

  EXPECT_CALL(result, SuccessInternal(_))
      .WillOnce([](const rapidjson::Document* document) {
        ASSERT_FALSE((*document)[kValueKey].GetBool());
      });
  EXPECT_TRUE(messenger.SimulateEngineMessage(
      kChannelName, encoded->data(), encoded->size(),
      [&](const uint8_t* reply, size_t reply_size) {
        JsonMethodCodec::GetInstance().DecodeAndProcessResponseEnvelope(
            reply, reply_size, &result);
      }));
}

TEST(PlatformHandlerWin32, HasStringsError) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  // HasStrings will fail.
  PlatformHandlerWin32 platform_handler(
      &messenger, &view,
      std::make_unique<TestScopedClipboard>(kArbitraryErrorCode, true));

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kStringType);
  auto& allocator = args->GetAllocator();
  args->SetString(kTextPlainFormat);
  auto encoded = JsonMethodCodec::GetInstance().EncodeMethodCall(
      MethodCall<rapidjson::Document>(kHasStringsClipboardMethod,
                                      std::move(args)));

  MockMethodResult result;
  rapidjson::Document document;
  document.SetObject();
  rapidjson::Document::AllocatorType& document_allocator =
      document.GetAllocator();
  document.AddMember(rapidjson::Value(kValueKey, document_allocator),
                     rapidjson::Value(false), document_allocator);

  EXPECT_CALL(result, SuccessInternal(_)).Times(0);
  EXPECT_CALL(result, ErrorInternal(_, _, _)).Times(1);
  EXPECT_TRUE(messenger.SimulateEngineMessage(
      kChannelName, encoded->data(), encoded->size(),
      [&](const uint8_t* reply, size_t reply_size) {
        JsonMethodCodec::GetInstance().DecodeAndProcessResponseEnvelope(
            reply, reply_size, &result);
      }));
}

}  // namespace testing
}  // namespace flutter
