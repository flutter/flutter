// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/shell/platform/windows/text_input_plugin.h"

#include <rapidjson/document.h>
#include <memory>

#include "flutter/shell/platform/common/json_message_codec.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
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
  // Notifies delegate that the cursor position has changed.
  void OnCursorRectUpdated(const Rect& rect) {}
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

  handler.KeyboardHook(nullptr, VK_RETURN, 100, WM_KEYDOWN, '\n', false, false);
  handler.ComposeBeginHook();
  std::u16string text;
  text.push_back('\n');
  handler.ComposeChangeHook(text, 1);
  handler.ComposeEndHook();

  // Passes if it did not crash
}

}  // namespace testing
}  // namespace flutter
