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

static constexpr char kChannelName[] = "flutter/platform";

static constexpr char kGetClipboardDataMethod[] = "Clipboard.getData";
static constexpr char kHasStringsClipboardMethod[] = "Clipboard.hasStrings";
static constexpr char kSetClipboardDataMethod[] = "Clipboard.setData";
static constexpr char kPlaySoundMethod[] = "SystemSound.play";

static constexpr char kTextPlainFormat[] = "text/plain";
static constexpr char kFakeContentType[] = "text/madeupcontenttype";

static constexpr char kSoundTypeAlert[] = "SystemSoundType.alert";

static constexpr char kValueKey[] = "value";
static constexpr int kAccessDeniedErrorCode = 5;
static constexpr int kErrorSuccess = 0;
static constexpr int kArbitraryErrorCode = 1;

// Test implementation of PlatformHandler to allow testing the PlatformHandler
// logic.
class TestPlatformHandler : public PlatformHandler {
 public:
  explicit TestPlatformHandler(
      BinaryMessenger* messenger,
      FlutterWindowsView* view,
      std::optional<std::function<std::unique_ptr<ScopedClipboardInterface>()>>
          scoped_clipboard_provider = std::nullopt)
      : PlatformHandler(messenger, view, scoped_clipboard_provider) {}

  virtual ~TestPlatformHandler() = default;

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

// Mock result to inspect results of PlatformHandler calls.
class MockMethodResult : public MethodResult<rapidjson::Document> {
 public:
  MOCK_METHOD1(SuccessInternal, void(const rapidjson::Document*));
  MOCK_METHOD3(ErrorInternal,
               void(const std::string&,
                    const std::string&,
                    const rapidjson::Document*));
  MOCK_METHOD0(NotImplementedInternal, void());
};

// A test version of system clipboard.
class MockSystemClipboard {
 public:
  void OpenClipboard() { opened = true; }
  void CloseClipboard() { opened = false; }
  bool opened = false;
};

// A test version of the private ScopedClipboard.
class TestScopedClipboard : public ScopedClipboardInterface {
 public:
  TestScopedClipboard(int open_error,
                      bool has_strings,
                      std::shared_ptr<MockSystemClipboard> clipboard);
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
  std::shared_ptr<MockSystemClipboard> clipboard_;
};

TestScopedClipboard::TestScopedClipboard(
    int open_error,
    bool has_strings,
    std::shared_ptr<MockSystemClipboard> clipboard = nullptr) {
  open_error_ = open_error;
  has_strings_ = has_strings;
  clipboard_ = clipboard;
}

TestScopedClipboard::~TestScopedClipboard() {
  if ((!open_error_) && clipboard_ != nullptr) {
    clipboard_->CloseClipboard();
  }
}

int TestScopedClipboard::Open(HWND window) {
  if ((!open_error_) && clipboard_ != nullptr) {
    clipboard_->OpenClipboard();
  }
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

}  // namespace

TEST(PlatformHandler, GettingTextCallsThrough) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  auto system_clipboard = std::make_shared<MockSystemClipboard>();
  TestPlatformHandler platform_handler(&messenger, &view, [system_clipboard]() {
    return std::make_unique<TestScopedClipboard>(kErrorSuccess, false,
                                                 system_clipboard);
  });

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kStringType);
  auto& allocator = args->GetAllocator();
  args->SetString(kTextPlainFormat);
  auto encoded = JsonMethodCodec::GetInstance().EncodeMethodCall(
      MethodCall<rapidjson::Document>(kGetClipboardDataMethod,
                                      std::move(args)));

  // Set up a handler to call a response on |result| so that it doesn't log
  // on destruction about leaking.
  ON_CALL(platform_handler, GetPlainText)
      .WillByDefault(
          [](std::unique_ptr<MethodResult<rapidjson::Document>> result,
             auto key) { result->NotImplemented(); });

  EXPECT_CALL(platform_handler, GetPlainText(_, ::testing::StrEq("text")));
  EXPECT_TRUE(messenger.SimulateEngineMessage(
      kChannelName, encoded->data(), encoded->size(),
      [](const uint8_t* reply, size_t reply_size) {}));
}

TEST(PlatformHandler, RejectsGettingUnknownTypes) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  auto system_clipboard = std::make_shared<MockSystemClipboard>();
  TestPlatformHandler platform_handler(&messenger, &view, [system_clipboard]() {
    return std::make_unique<TestScopedClipboard>(kErrorSuccess, false,
                                                 system_clipboard);
  });

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kStringType);
  auto& allocator = args->GetAllocator();
  args->SetString(kFakeContentType);
  auto encoded = JsonMethodCodec::GetInstance().EncodeMethodCall(
      MethodCall<rapidjson::Document>(kGetClipboardDataMethod,
                                      std::move(args)));

  MockMethodResult result;
  // Requsting an unknow content type is an error.
  EXPECT_CALL(result, ErrorInternal(_, _, _));
  EXPECT_TRUE(messenger.SimulateEngineMessage(
      kChannelName, encoded->data(), encoded->size(),
      [&](const uint8_t* reply, size_t reply_size) {
        JsonMethodCodec::GetInstance().DecodeAndProcessResponseEnvelope(
            reply, reply_size, &result);
      }));
}

TEST(PlatformHandler, GetHasStringsCallsThrough) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  auto system_clipboard = std::make_shared<MockSystemClipboard>();
  TestPlatformHandler platform_handler(&messenger, &view, [system_clipboard]() {
    return std::make_unique<TestScopedClipboard>(kErrorSuccess, false,
                                                 system_clipboard);
  });

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kStringType);
  auto& allocator = args->GetAllocator();
  args->SetString(kTextPlainFormat);
  auto encoded = JsonMethodCodec::GetInstance().EncodeMethodCall(
      MethodCall<rapidjson::Document>(kHasStringsClipboardMethod,
                                      std::move(args)));

  // Set up a handler to call a response on |result| so that it doesn't log
  // on destruction about leaking.
  ON_CALL(platform_handler, GetHasStrings)
      .WillByDefault(
          [](std::unique_ptr<MethodResult<rapidjson::Document>> result) {
            result->NotImplemented();
          });

  EXPECT_CALL(platform_handler, GetHasStrings(_));
  EXPECT_TRUE(messenger.SimulateEngineMessage(
      kChannelName, encoded->data(), encoded->size(),
      [](const uint8_t* reply, size_t reply_size) {}));
}

TEST(PlatformHandler, RejectsGetHasStringsOnUnknownTypes) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  auto system_clipboard = std::make_shared<MockSystemClipboard>();
  TestPlatformHandler platform_handler(&messenger, &view, [system_clipboard]() {
    return std::make_unique<TestScopedClipboard>(kErrorSuccess, false,
                                                 system_clipboard);
  });

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kStringType);
  auto& allocator = args->GetAllocator();
  args->SetString(kFakeContentType);
  auto encoded = JsonMethodCodec::GetInstance().EncodeMethodCall(
      MethodCall<rapidjson::Document>(kHasStringsClipboardMethod,
                                      std::move(args)));

  MockMethodResult result;
  // Requsting an unknow content type is an error.
  EXPECT_CALL(result, ErrorInternal(_, _, _));
  EXPECT_TRUE(messenger.SimulateEngineMessage(
      kChannelName, encoded->data(), encoded->size(),
      [&](const uint8_t* reply, size_t reply_size) {
        JsonMethodCodec::GetInstance().DecodeAndProcessResponseEnvelope(
            reply, reply_size, &result);
      }));
}

TEST(PlatformHandler, SettingTextCallsThrough) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  auto system_clipboard = std::make_shared<MockSystemClipboard>();
  TestPlatformHandler platform_handler(&messenger, &view, [system_clipboard]() {
    return std::make_unique<TestScopedClipboard>(kErrorSuccess, false,
                                                 system_clipboard);
  });

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kObjectType);
  auto& allocator = args->GetAllocator();
  args->AddMember("text", "hello", allocator);
  auto encoded = JsonMethodCodec::GetInstance().EncodeMethodCall(
      MethodCall<rapidjson::Document>(kSetClipboardDataMethod,
                                      std::move(args)));

  // Set up a handler to call a response on |result| so that it doesn't log
  // on destruction about leaking.
  ON_CALL(platform_handler, SetPlainText)
      .WillByDefault(
          [](auto value,
             std::unique_ptr<MethodResult<rapidjson::Document>> result) {
            result->NotImplemented();
          });

  EXPECT_CALL(platform_handler, SetPlainText(::testing::StrEq("hello"), _));
  EXPECT_TRUE(messenger.SimulateEngineMessage(
      kChannelName, encoded->data(), encoded->size(),
      [](const uint8_t* reply, size_t reply_size) {}));
}

TEST(PlatformHandler, RejectsSettingUnknownTypes) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  auto system_clipboard = std::make_shared<MockSystemClipboard>();
  TestPlatformHandler platform_handler(&messenger, &view, [system_clipboard]() {
    return std::make_unique<TestScopedClipboard>(kErrorSuccess, false,
                                                 system_clipboard);
  });

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kObjectType);
  auto& allocator = args->GetAllocator();
  args->AddMember("madeuptype", "hello", allocator);
  auto encoded = JsonMethodCodec::GetInstance().EncodeMethodCall(
      MethodCall<rapidjson::Document>(kSetClipboardDataMethod,
                                      std::move(args)));

  MockMethodResult result;
  // Requsting an unknow content type is an error.
  EXPECT_CALL(result, ErrorInternal(_, _, _));
  EXPECT_TRUE(messenger.SimulateEngineMessage(
      kChannelName, encoded->data(), encoded->size(),
      [&](const uint8_t* reply, size_t reply_size) {
        JsonMethodCodec::GetInstance().DecodeAndProcessResponseEnvelope(
            reply, reply_size, &result);
      }));
}

TEST(PlatformHandler, PlayingSystemSoundCallsThrough) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  auto system_clipboard = std::make_shared<MockSystemClipboard>();
  TestPlatformHandler platform_handler(&messenger, &view, [system_clipboard]() {
    return std::make_unique<TestScopedClipboard>(kErrorSuccess, false,
                                                 system_clipboard);
  });

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kStringType);
  auto& allocator = args->GetAllocator();
  args->SetString(kSoundTypeAlert);
  auto encoded = JsonMethodCodec::GetInstance().EncodeMethodCall(
      MethodCall<rapidjson::Document>(kPlaySoundMethod, std::move(args)));

  // Set up a handler to call a response on |result| so that it doesn't log
  // on destruction about leaking.
  ON_CALL(platform_handler, SystemSoundPlay)
      .WillByDefault(
          [](auto sound_type,
             std::unique_ptr<MethodResult<rapidjson::Document>> result) {
            result->NotImplemented();
          });

  EXPECT_CALL(platform_handler,
              SystemSoundPlay(::testing::StrEq(kSoundTypeAlert), _));
  EXPECT_TRUE(messenger.SimulateEngineMessage(
      kChannelName, encoded->data(), encoded->size(),
      [](const uint8_t* reply, size_t reply_size) {}));
}

// Regression test for https://github.com/flutter/flutter/issues/95817.
TEST(PlatformHandler, HasStringsAccessDeniedReturnsFalseWithoutError) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  // HasStrings will receive access denied on the clipboard, but will return
  // false without error.
  PlatformHandler platform_handler(&messenger, &view, []() {
    return std::make_unique<TestScopedClipboard>(kAccessDeniedErrorCode, true);
  });

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

TEST(PlatformHandler, HasStringsSuccessWithStrings) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  // HasStrings will succeed and return true.
  PlatformHandler platform_handler(&messenger, &view, []() {
    return std::make_unique<TestScopedClipboard>(kErrorSuccess, true);
  });

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

TEST(PlatformHandler, HasStringsSuccessWithoutStrings) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  // HasStrings will succeed and return false.
  PlatformHandler platform_handler(&messenger, &view, []() {
    return std::make_unique<TestScopedClipboard>(kErrorSuccess, false);
  });

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

TEST(PlatformHandler, HasStringsError) {
  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  // HasStrings will fail.
  PlatformHandler platform_handler(&messenger, &view, []() {
    return std::make_unique<TestScopedClipboard>(kArbitraryErrorCode, true);
  });

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

// Regression test for https://github.com/flutter/flutter/issues/103205.
TEST(PlatformHandler, ReleaseClipboard) {
  auto system_clipboard = std::make_shared<MockSystemClipboard>();

  TestBinaryMessenger messenger;
  FlutterWindowsView view(
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>());
  TestPlatformHandler platform_handler(&messenger, &view, [system_clipboard]() {
    return std::make_unique<TestScopedClipboard>(kErrorSuccess, false,
                                                 system_clipboard);
  });

  platform_handler.GetPlainText(std::make_unique<MockMethodResult>(), "text");
  ASSERT_FALSE(system_clipboard->opened);

  platform_handler.GetHasStrings(std::make_unique<MockMethodResult>());
  ASSERT_FALSE(system_clipboard->opened);

  platform_handler.SetPlainText("", std::make_unique<MockMethodResult>());
  ASSERT_FALSE(system_clipboard->opened);
}

}  // namespace testing
}  // namespace flutter
