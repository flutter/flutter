// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/shell/platform/windows/key_event_handler.h"

#include <rapidjson/document.h>
#include <memory>

#include "flutter/shell/platform/common/cpp/json_message_codec.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/testing/test_binary_messenger.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

static constexpr char kScanCodeKey[] = "scanCode";
static constexpr int kHandledScanCode = 20;
static constexpr int kUnhandledScanCode = 21;

std::unique_ptr<std::vector<uint8_t>> CreateResponse(bool handled) {
  auto response_doc =
      std::make_unique<rapidjson::Document>(rapidjson::kObjectType);
  auto& allocator = response_doc->GetAllocator();
  response_doc->AddMember("handled", handled, allocator);
  return JsonMessageCodec::GetInstance().EncodeMessage(*response_doc);
}

TEST(KeyEventHandlerTest, KeyboardHookHandling) {
  auto handled_message = CreateResponse(true);
  auto unhandled_message = CreateResponse(false);
  int received_scancode = 0;

  TestBinaryMessenger messenger(
      [&received_scancode, &handled_message, &unhandled_message](
          const std::string& channel, const uint8_t* message,
          size_t message_size, BinaryReply reply) {
        if (channel == "flutter/keyevent") {
          auto message_doc = JsonMessageCodec::GetInstance().DecodeMessage(
              message, message_size);
          received_scancode = (*message_doc)[kScanCodeKey].GetInt();
          if (received_scancode == kHandledScanCode) {
            reply(handled_message->data(), handled_message->size());
          } else {
            reply(unhandled_message->data(), unhandled_message->size());
          }
        }
      });

  int redispatch_scancode = 0;
  KeyEventHandler handler(&messenger,
                          [&redispatch_scancode](UINT cInputs, LPINPUT pInputs,
                                                 int cbSize) -> UINT {
                            EXPECT_TRUE(cbSize > 0);
                            redispatch_scancode = pInputs->ki.wScan;
                            return 1;
                          });

  handler.KeyboardHook(nullptr, 64, kHandledScanCode, WM_KEYDOWN, L'a', false);
  EXPECT_EQ(received_scancode, kHandledScanCode);
  EXPECT_EQ(redispatch_scancode, 0);
  received_scancode = 0;
  handler.KeyboardHook(nullptr, 64, kUnhandledScanCode, WM_KEYDOWN, L'b',
                       false);
  EXPECT_EQ(received_scancode, kUnhandledScanCode);
  EXPECT_EQ(redispatch_scancode, kUnhandledScanCode);
}

TEST(KeyEventHandlerTest, ExtendedKeysAreSentToRedispatch) {
  auto handled_message = CreateResponse(true);
  auto unhandled_message = CreateResponse(false);
  int received_scancode = 0;
  bool is_extended_key = false;

  TestBinaryMessenger messenger(
      [&received_scancode, &handled_message, &unhandled_message](
          const std::string& channel, const uint8_t* message,
          size_t message_size, BinaryReply reply) {
        if (channel == "flutter/keyevent") {
          auto message_doc = JsonMessageCodec::GetInstance().DecodeMessage(
              message, message_size);
          received_scancode = (*message_doc)[kScanCodeKey].GetInt();
          if (received_scancode == kHandledScanCode) {
            reply(handled_message->data(), handled_message->size());
          } else {
            reply(unhandled_message->data(), unhandled_message->size());
          }
        }
      });

  int redispatch_scancode = 0;
  KeyEventHandler handler(
      &messenger,
      [&redispatch_scancode, &is_extended_key](UINT cInputs, LPINPUT pInputs,
                                               int cbSize) -> UINT {
        EXPECT_TRUE(cbSize > 0);
        redispatch_scancode = pInputs->ki.wScan;
        is_extended_key = (pInputs->ki.dwFlags & KEYEVENTF_EXTENDEDKEY) != 0;
        return 1;
      });

  // Extended key flag is passed to redispatched events if set.
  handler.KeyboardHook(nullptr, 64, kUnhandledScanCode, WM_KEYDOWN, L'b', true);
  EXPECT_EQ(received_scancode, kUnhandledScanCode);
  EXPECT_EQ(redispatch_scancode, kUnhandledScanCode);
  EXPECT_EQ(is_extended_key, true);

  // Extended key flag is not passed to redispatched events if not set.
  handler.KeyboardHook(nullptr, 64, kUnhandledScanCode, WM_KEYDOWN, L'b',
                       false);
  EXPECT_EQ(received_scancode, kUnhandledScanCode);
  EXPECT_EQ(redispatch_scancode, kUnhandledScanCode);
  EXPECT_EQ(is_extended_key, false);
}

}  // namespace testing
}  // namespace flutter
