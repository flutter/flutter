// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/shell/platform/windows/cursor_handler.h"

#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/method_result_functions.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/standard_message_codec.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/standard_method_codec.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/mock_windows_proc_table.h"
#include "flutter/shell/platform/windows/testing/test_binary_messenger.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {
using ::testing::_;
using ::testing::IsNull;
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

class CursorHandlerTest : public WindowsTest {
 public:
  CursorHandlerTest() = default;
  virtual ~CursorHandlerTest() = default;

 protected:
  FlutterWindowsEngine* engine() { return engine_.get(); }
  FlutterWindowsView* view() { return view_.get(); }
  MockWindowBindingHandler* window() { return window_; }
  MockWindowsProcTable* proc_table() { return windows_proc_table_.get(); }

  void UseHeadlessEngine() {
    FlutterWindowsEngineBuilder builder{GetContext()};

    engine_ = builder.Build();
  }

  void UseEngineWithView() {
    windows_proc_table_ = std::make_shared<MockWindowsProcTable>();

    FlutterWindowsEngineBuilder builder{GetContext()};
    builder.SetWindowsProcTable(windows_proc_table_);

    auto window = std::make_unique<MockWindowBindingHandler>();
    EXPECT_CALL(*window.get(), SetView).Times(1);
    EXPECT_CALL(*window.get(), GetWindowHandle).WillRepeatedly(Return(nullptr));

    window_ = window.get();
    engine_ = builder.Build();
    view_ = engine_->CreateView(std::move(window));
  }

 private:
  std::unique_ptr<FlutterWindowsEngine> engine_;
  std::unique_ptr<FlutterWindowsView> view_;
  MockWindowBindingHandler* window_;
  std::shared_ptr<MockWindowsProcTable> windows_proc_table_;

  FML_DISALLOW_COPY_AND_ASSIGN(CursorHandlerTest);
};

TEST_F(CursorHandlerTest, ActivateSystemCursor) {
  UseEngineWithView();

  TestBinaryMessenger messenger;
  CursorHandler cursor_handler(&messenger, engine());

  EXPECT_CALL(*proc_table(), LoadCursor(IsNull(), IDC_HAND)).Times(1);
  EXPECT_CALL(*proc_table(), SetCursor).Times(1);

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

TEST_F(CursorHandlerTest, CreateCustomCursor) {
  UseEngineWithView();

  TestBinaryMessenger messenger;
  CursorHandler cursor_handler(&messenger, engine());

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

TEST_F(CursorHandlerTest, SetCustomCursor) {
  UseEngineWithView();

  TestBinaryMessenger messenger;
  CursorHandler cursor_handler(&messenger, engine());

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

  EXPECT_CALL(*proc_table(), LoadCursor).Times(0);
  EXPECT_CALL(*proc_table(), SetCursor(NotNull())).Times(1);

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

TEST_F(CursorHandlerTest, SetNonexistentCustomCursor) {
  UseEngineWithView();

  TestBinaryMessenger messenger;
  CursorHandler cursor_handler(&messenger, engine());

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

  EXPECT_CALL(*proc_table(), LoadCursor).Times(0);
  EXPECT_CALL(*proc_table(), SetCursor).Times(0);

  SimulateCursorMessage(&messenger, kSetCustomCursorMethod,
                        std::make_unique<EncodableValue>(EncodableMap{
                            {EncodableValue("name"), EncodableValue("hello")},
                        }),
                        &result_handler);

  EXPECT_TRUE(error);
}

TEST_F(CursorHandlerTest, DeleteCustomCursor) {
  UseEngineWithView();

  TestBinaryMessenger messenger;
  CursorHandler cursor_handler(&messenger, engine());

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

TEST_F(CursorHandlerTest, DeleteNonexistentCustomCursor) {
  UseEngineWithView();

  TestBinaryMessenger messenger;
  CursorHandler cursor_handler(&messenger, engine());

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
