// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/shell/platform/windows/text_input_plugin.h"

#include <rapidjson/document.h>
#include <windows.h>
#include <memory>

#include "flutter/shell/platform/common/json_message_codec.h"
#include "flutter/shell/platform/common/json_method_codec.h"
#include "flutter/shell/platform/windows/testing/test_binary_messenger.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {
static constexpr char kScanCodeKey[] = "scanCode";
static constexpr int kHandledScanCode = 20;
static constexpr int kUnhandledScanCode = 21;

static std::unique_ptr<std::vector<uint8_t>> CreateResponse(bool handled) {
  auto response_doc =
      std::make_unique<rapidjson::Document>(rapidjson::kObjectType);
  auto& allocator = response_doc->GetAllocator();
  response_doc->AddMember("handled", handled, allocator);
  return JsonMessageCodec::GetInstance().EncodeMessage(*response_doc);
}

class EmptyTextInputPluginDelegate : public TextInputPluginDelegate {
 public:
  void OnCursorRectUpdated(const Rect& rect) override {}
  void OnResetImeComposing() override { ime_was_reset_ = true; }

  bool ime_was_reset() const { return ime_was_reset_; }

 private:
  bool ime_was_reset_ = false;
};
}  // namespace

TEST(TextInputPluginTest, TextMethodsWorksWithEmptyModel) {
  auto handled_message = CreateResponse(true);
  auto unhandled_message = CreateResponse(false);
  int received_scancode = 0;

  TestBinaryMessenger messenger(
      [&received_scancode, &handled_message, &unhandled_message](
          const std::string& channel, const uint8_t* message,
          size_t message_size, BinaryReply reply) {});
  EmptyTextInputPluginDelegate delegate;

  int redispatch_scancode = 0;
  TextInputPlugin handler(&messenger, &delegate);

  handler.KeyboardHook(VK_RETURN, 100, WM_KEYDOWN, '\n', false, false);
  handler.ComposeBeginHook();
  std::u16string text;
  text.push_back('\n');
  handler.ComposeChangeHook(text, 1);
  handler.ComposeEndHook();

  // Passes if it did not crash
}

TEST(TextInputPluginTest, ClearClientResetsComposing) {
  TestBinaryMessenger messenger([](const std::string& channel,
                                   const uint8_t* message, size_t message_size,
                                   BinaryReply reply) {});
  BinaryReply reply_handler = [](const uint8_t* reply, size_t reply_size) {};

  EmptyTextInputPluginDelegate delegate;
  TextInputPlugin handler(&messenger, &delegate);

  auto& codec = JsonMethodCodec::GetInstance();
  auto message = codec.EncodeMethodCall({"TextInput.clearClient", nullptr});
  messenger.SimulateEngineMessage("flutter/textinput", message->data(),
                                  message->size(), reply_handler);
  EXPECT_TRUE(delegate.ime_was_reset());
}

// Verify that the embedder sends state update messages to the framework during
// IME composing.
TEST(TextInputPluginTest, VerifyComposingSendStateUpdate) {
  bool sent_message = false;
  TestBinaryMessenger messenger(
      [&sent_message](const std::string& channel, const uint8_t* message,
                      size_t message_size,
                      BinaryReply reply) { sent_message = true; });
  BinaryReply reply_handler = [](const uint8_t* reply, size_t reply_size) {};

  EmptyTextInputPluginDelegate delegate;
  TextInputPlugin handler(&messenger, &delegate);

  auto& codec = JsonMethodCodec::GetInstance();

  // Call TextInput.setClient to initialize the TextInputModel.
  auto arguments = std::make_unique<rapidjson::Document>(rapidjson::kArrayType);
  auto& allocator = arguments->GetAllocator();
  arguments->PushBack(42, allocator);
  rapidjson::Value config(rapidjson::kObjectType);
  config.AddMember("inputAction", "done", allocator);
  config.AddMember("inputType", "text", allocator);
  arguments->PushBack(config, allocator);
  auto message =
      codec.EncodeMethodCall({"TextInput.setClient", std::move(arguments)});
  messenger.SimulateEngineMessage("flutter/textinput", message->data(),
                                  message->size(), reply_handler);

  // ComposeBeginHook should send state update.
  sent_message = false;
  handler.ComposeBeginHook();
  EXPECT_TRUE(sent_message);

  // ComposeChangeHook should send state update.
  sent_message = false;
  handler.ComposeChangeHook(u"4", 1);
  EXPECT_TRUE(sent_message);

  // ComposeCommitHook should NOT send state update.
  //
  // Commit messages are always immediately followed by a change message or an
  // end message, both of which will send an update. Sending intermediate state
  // with a collapsed composing region will trigger the framework to assume
  // composing has ended, which is not the case until a WM_IME_ENDCOMPOSING
  // event is received in the main event loop, which will trigger a call to
  // ComposeEndHook.
  sent_message = false;
  handler.ComposeCommitHook();
  EXPECT_FALSE(sent_message);

  // ComposeEndHook should send state update.
  sent_message = false;
  handler.ComposeEndHook();
  EXPECT_TRUE(sent_message);
}

}  // namespace testing
}  // namespace flutter
