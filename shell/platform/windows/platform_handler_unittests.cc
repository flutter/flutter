// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/platform_handler.h"

#include <memory>

#include "flutter/shell/platform/common/client_wrapper/include/flutter/binary_messenger.h"
#include "flutter/shell/platform/common/json_method_codec.h"
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
static constexpr char kSetClipboardDataMethod[] = "Clipboard.setData";

static constexpr char kTextPlainFormat[] = "text/plain";

// Test implementation of PlatformHandler to allow testing the PlatformHandler
// logic.
class TestPlatformHandler : public PlatformHandler {
 public:
  explicit TestPlatformHandler(BinaryMessenger* messenger)
      : PlatformHandler(messenger) {}

  virtual ~TestPlatformHandler() {}

  // |PlatformHandler|
  MOCK_METHOD2(GetPlainText,
               void(std::unique_ptr<MethodResult<rapidjson::Document>>,
                    const char*));
  MOCK_METHOD2(SetPlainText,
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

}  // namespace

TEST(PlatformHandler, GettingTextCallsThrough) {
  TestBinaryMessenger messenger;
  TestPlatformHandler platform_handler(&messenger);

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kArrayType);
  auto& allocator = args->GetAllocator();
  args->PushBack(kTextPlainFormat, allocator);
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
  TestPlatformHandler platform_handler(&messenger);

  auto args = std::make_unique<rapidjson::Document>(rapidjson::kArrayType);
  auto& allocator = args->GetAllocator();
  args->PushBack("madeup/contenttype", allocator);
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

TEST(PlatformHandler, SettingTextCallsThrough) {
  TestBinaryMessenger messenger;
  TestPlatformHandler platform_handler(&messenger);

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
  TestPlatformHandler platform_handler(&messenger);

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

}  // namespace testing
}  // namespace flutter
