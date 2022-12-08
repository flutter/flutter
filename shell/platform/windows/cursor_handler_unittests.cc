// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/shell/platform/windows/cursor_handler.h"

#include <memory>
#include <vector>

#include "flutter/shell/platform/common/client_wrapper/include/flutter/method_result_functions.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/standard_message_codec.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/standard_method_codec.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/test_binary_messenger.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {
using ::testing::_;
using ::testing::NotNull;
using ::testing::Return;

static constexpr char kChannelName[] = "flutter/mousecursor";

static constexpr char kActivateSystemCursorMethod[] = "activateSystemCursor";
static constexpr char kCreateCustomCursorMethod[] =
    "createCustomCursor/windows";
static constexpr char kSetCustomCursorMethod[] = "setCustomCursor/windows";
static constexpr char kDeleteCustomCursorMethod[] =
    "deleteCustomCursor/windows";

void SimulateCursorMessage(TestBinaryMessenger* messenger,
                           const std::string& method_name,
                           std::unique_ptr<EncodableValue> arguments,
                           MethodResult<EncodableValue>* result_handler) {
  MethodCall<> call(method_name, std::move(arguments));

  auto message = StandardMethodCodec::GetInstance().EncodeMethodCall(call);

  EXPECT_TRUE(messenger->SimulateEngineMessage(
      kChannelName, message->data(), message->size(),
      [&result_handler](const uint8_t* reply, size_t reply_size) {
        StandardMethodCodec::GetInstance().DecodeAndProcessResponseEnvelope(
            reply, reply_size, result_handler);
      }));
}

}  // namespace

TEST(CursorHandlerTest, ActivateSystemCursor) {
  TestBinaryMessenger messenger;
  MockWindowBindingHandler window;
  CursorHandler cursor_handler(&messenger, &window);

  EXPECT_CALL(window, UpdateFlutterCursor("click")).Times(1);

  bool success = false;
  MethodResultFunctions<> result_handler(
      [&success](const EncodableValue* result) {
        success = true;
        EXPECT_EQ(result, nullptr);
      },
      nullptr, nullptr);

  SimulateCursorMessage(&messenger, kActivateSystemCursorMethod,
                        std::make_unique<EncodableValue>(EncodableMap{
                            {EncodableValue("device"), EncodableValue(0)},
                            {EncodableValue("kind"), EncodableValue("click")},
                        }),
                        &result_handler);

  EXPECT_TRUE(success);
}

TEST(CursorHandlerTest, CreateCustomCursor) {
  TestBinaryMessenger messenger;
  MockWindowBindingHandler window;
  CursorHandler cursor_handler(&messenger, &window);

  // Create a 4x4 raw BGRA test cursor buffer.
  std::vector<uint8_t> buffer(4 * 4 * 4, 0);

  bool success = false;
  MethodResultFunctions<> result_handler(
      [&success](const EncodableValue* result) {
        success = true;
        EXPECT_EQ(std::get<std::string>(*result), "hello");
      },
      nullptr, nullptr);

  SimulateCursorMessage(&messenger, kCreateCustomCursorMethod,
                        std::make_unique<EncodableValue>(EncodableMap{
                            {EncodableValue("name"), EncodableValue("hello")},
                            {EncodableValue("buffer"), EncodableValue(buffer)},
                            {EncodableValue("width"), EncodableValue(4)},
                            {EncodableValue("height"), EncodableValue(4)},
                            {EncodableValue("hotX"), EncodableValue(0.0)},
                            {EncodableValue("hotY"), EncodableValue(0.0)},
                        }),
                        &result_handler);

  EXPECT_TRUE(success);
}

TEST(CursorHandlerTest, SetCustomCursor) {
  TestBinaryMessenger messenger;
  MockWindowBindingHandler window;
  CursorHandler cursor_handler(&messenger, &window);

  // Create a 4x4 raw BGRA test cursor buffer.
  std::vector<uint8_t> buffer(4 * 4 * 4, 0);

  bool success = false;
  MethodResultFunctions<> create_result_handler(nullptr, nullptr, nullptr);
  MethodResultFunctions<> set_result_handler(
      [&success](const EncodableValue* result) {
        success = true;
        EXPECT_EQ(result, nullptr);
      },
      nullptr, nullptr);

  EXPECT_CALL(window, SetFlutterCursor(/*cursor=*/NotNull())).Times(1);

  SimulateCursorMessage(&messenger, kCreateCustomCursorMethod,
                        std::make_unique<EncodableValue>(EncodableMap{
                            {EncodableValue("name"), EncodableValue("hello")},
                            {EncodableValue("buffer"), EncodableValue(buffer)},
                            {EncodableValue("width"), EncodableValue(4)},
                            {EncodableValue("height"), EncodableValue(4)},
                            {EncodableValue("hotX"), EncodableValue(0.0)},
                            {EncodableValue("hotY"), EncodableValue(0.0)},
                        }),
                        &create_result_handler);

  SimulateCursorMessage(&messenger, kSetCustomCursorMethod,
                        std::make_unique<EncodableValue>(EncodableMap{
                            {EncodableValue("name"), EncodableValue("hello")},
                        }),
                        &set_result_handler);

  EXPECT_TRUE(success);
}

TEST(CursorHandlerTest, SetNonexistentCustomCursor) {
  TestBinaryMessenger messenger;
  MockWindowBindingHandler window;
  CursorHandler cursor_handler(&messenger, &window);

  bool error = false;
  MethodResultFunctions<> result_handler(
      nullptr,
      [&error](const std::string& error_code, const std::string& error_message,
               const EncodableValue* value) {
        error = true;
        EXPECT_EQ(
            error_message,
            "The custom cursor identified by the argument key cannot be found");
      },
      nullptr);

  EXPECT_CALL(window, SetFlutterCursor).Times(0);

  SimulateCursorMessage(&messenger, kSetCustomCursorMethod,
                        std::make_unique<EncodableValue>(EncodableMap{
                            {EncodableValue("name"), EncodableValue("hello")},
                        }),
                        &result_handler);

  EXPECT_TRUE(error);
}

TEST(CursorHandlerTest, DeleteCustomCursor) {
  TestBinaryMessenger messenger;
  MockWindowBindingHandler window;
  CursorHandler cursor_handler(&messenger, &window);

  // Create a 4x4 raw BGRA test cursor buffer.
  std::vector<uint8_t> buffer(4 * 4 * 4, 0);

  bool success = false;
  MethodResultFunctions<> create_result_handler(nullptr, nullptr, nullptr);
  MethodResultFunctions<> delete_result_handler(
      [&success](const EncodableValue* result) {
        success = true;
        EXPECT_EQ(result, nullptr);
      },
      nullptr, nullptr);

  SimulateCursorMessage(&messenger, kCreateCustomCursorMethod,
                        std::make_unique<EncodableValue>(EncodableMap{
                            {EncodableValue("name"), EncodableValue("hello")},
                            {EncodableValue("buffer"), EncodableValue(buffer)},
                            {EncodableValue("width"), EncodableValue(4)},
                            {EncodableValue("height"), EncodableValue(4)},
                            {EncodableValue("hotX"), EncodableValue(0.0)},
                            {EncodableValue("hotY"), EncodableValue(0.0)},
                        }),
                        &create_result_handler);

  SimulateCursorMessage(&messenger, kDeleteCustomCursorMethod,
                        std::make_unique<EncodableValue>(EncodableMap{
                            {EncodableValue("name"), EncodableValue("hello")},
                        }),
                        &delete_result_handler);

  EXPECT_TRUE(success);
}

TEST(CursorHandlerTest, DeleteNonexistentCustomCursor) {
  TestBinaryMessenger messenger;
  MockWindowBindingHandler handler;
  CursorHandler cursor_handler(&messenger, &handler);

  bool success = false;
  MethodResultFunctions<> result_handler(
      [&success](const EncodableValue* result) {
        success = true;
        EXPECT_EQ(result, nullptr);
      },
      nullptr, nullptr);

  SimulateCursorMessage(&messenger, kDeleteCustomCursorMethod,
                        std::make_unique<EncodableValue>(EncodableMap{
                            {EncodableValue("name"), EncodableValue("fake")},
                        }),
                        &result_handler);

  EXPECT_TRUE(success);
}

}  // namespace testing
}  // namespace flutter
