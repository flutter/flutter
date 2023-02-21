// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/shell/platform/windows/keyboard_key_handler.h"

#include <rapidjson/document.h>
#include <memory>

#include "flutter/fml/macros.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

static constexpr int kHandledScanCode = 20;
static constexpr int kHandledScanCode2 = 22;
static constexpr int kUnhandledScanCode = 21;

constexpr uint64_t kScanCodeShiftRight = 0x36;
constexpr uint64_t kScanCodeControl = 0x1D;
constexpr uint64_t kScanCodeAltLeft = 0x38;

typedef std::function<void(bool)> Callback;
typedef std::function<void(Callback&)> CallbackHandler;
void dont_respond(Callback& callback) {}
void respond_true(Callback& callback) {
  callback(true);
}
void respond_false(Callback& callback) {
  callback(false);
}

// A testing |KeyHandlerDelegate| that records all calls
// to |KeyboardHook| and can be customized with whether
// the hook is handled in async.
class MockKeyHandlerDelegate
    : public KeyboardKeyHandler::KeyboardKeyHandlerDelegate {
 public:
  class KeyboardHookCall {
   public:
    int delegate_id;
    int key;
    int scancode;
    int action;
    char32_t character;
    bool extended;
    bool was_down;
    std::function<void(bool)> callback;
  };

  // Create a |MockKeyHandlerDelegate|.
  //
  // The |delegate_id| is an arbitrary ID to tell between delegates
  // that will be recorded in |KeyboardHookCall|.
  //
  // The |hook_history| will store every call to |KeyboardHookCall| that are
  // handled asynchronously.
  //
  // The |is_async| is a function that the class calls upon every
  // |KeyboardHookCall| to decide whether the call is handled asynchronously.
  // Defaults to always returning true (async).
  MockKeyHandlerDelegate(int delegate_id,
                         std::list<KeyboardHookCall>* hook_history)
      : delegate_id(delegate_id),
        hook_history(hook_history),
        callback_handler(dont_respond) {}
  virtual ~MockKeyHandlerDelegate() = default;

  virtual void KeyboardHook(int key,
                            int scancode,
                            int action,
                            char32_t character,
                            bool extended,
                            bool was_down,
                            std::function<void(bool)> callback) {
    hook_history->push_back(KeyboardHookCall{
        .delegate_id = delegate_id,
        .key = key,
        .scancode = scancode,
        .character = character,
        .extended = extended,
        .was_down = was_down,
        .callback = std::move(callback),
    });
    callback_handler(hook_history->back().callback);
  }

  virtual void SyncModifiersIfNeeded(int modifiers_state) {
    // Do Nothing
  }

  CallbackHandler callback_handler;
  int delegate_id;
  std::list<KeyboardHookCall>* hook_history;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockKeyHandlerDelegate);
};

enum KeyEventResponse {
  kNoResponse,
  kHandled,
  kUnhandled,
};

static KeyEventResponse key_event_response = kNoResponse;

void OnKeyEventResult(bool handled) {
  key_event_response = handled ? kHandled : kUnhandled;
}

}  // namespace

TEST(KeyboardKeyHandlerTest, SingleDelegateWithAsyncResponds) {
  std::list<MockKeyHandlerDelegate::KeyboardHookCall> hook_history;

  KeyboardKeyHandler handler;
  // Add one delegate
  auto delegate = std::make_unique<MockKeyHandlerDelegate>(1, &hook_history);
  handler.AddDelegate(std::move(delegate));

  /// Test 1: One event that is handled by the framework

  // Dispatch a key event
  handler.KeyboardHook(64, kHandledScanCode, WM_KEYDOWN, L'a', false, true,
                       OnKeyEventResult);
  EXPECT_EQ(key_event_response, kNoResponse);
  EXPECT_EQ(hook_history.size(), 1);
  EXPECT_EQ(hook_history.back().delegate_id, 1);
  EXPECT_EQ(hook_history.back().scancode, kHandledScanCode);
  EXPECT_EQ(hook_history.back().was_down, true);

  EXPECT_EQ(key_event_response, kNoResponse);
  hook_history.back().callback(true);
  EXPECT_EQ(key_event_response, kHandled);

  key_event_response = kNoResponse;
  hook_history.clear();

  /// Test 2: Two events that are unhandled by the framework

  handler.KeyboardHook(64, kHandledScanCode, WM_KEYDOWN, L'a', false, false,
                       OnKeyEventResult);
  EXPECT_EQ(key_event_response, kNoResponse);
  EXPECT_EQ(hook_history.size(), 1);
  EXPECT_EQ(hook_history.back().delegate_id, 1);
  EXPECT_EQ(hook_history.back().scancode, kHandledScanCode);
  EXPECT_EQ(hook_history.back().was_down, false);

  // Dispatch another key event
  handler.KeyboardHook(65, kHandledScanCode2, WM_KEYUP, L'b', false, true,
                       OnKeyEventResult);
  EXPECT_EQ(key_event_response, kNoResponse);
  EXPECT_EQ(hook_history.size(), 2);
  EXPECT_EQ(hook_history.back().delegate_id, 1);
  EXPECT_EQ(hook_history.back().scancode, kHandledScanCode2);
  EXPECT_EQ(hook_history.back().was_down, true);

  // Resolve the second event first to test out-of-order response
  hook_history.back().callback(false);
  EXPECT_EQ(key_event_response, kUnhandled);
  key_event_response = kNoResponse;

  // Resolve the first event then
  hook_history.front().callback(false);
  EXPECT_EQ(key_event_response, kUnhandled);

  hook_history.clear();
  key_event_response = kNoResponse;
}

TEST(KeyboardKeyHandlerTest, SingleDelegateWithSyncResponds) {
  std::list<MockKeyHandlerDelegate::KeyboardHookCall> hook_history;

  KeyboardKeyHandler handler;
  // Add one delegate
  auto delegate = std::make_unique<MockKeyHandlerDelegate>(1, &hook_history);
  CallbackHandler& delegate_handler = delegate->callback_handler;
  handler.AddDelegate(std::move(delegate));

  /// Test 1: One event that is handled by the framework

  // Dispatch a key event
  delegate_handler = respond_true;
  handler.KeyboardHook(64, kHandledScanCode, WM_KEYDOWN, L'a', false, false,
                       OnKeyEventResult);
  EXPECT_EQ(key_event_response, kHandled);
  EXPECT_EQ(hook_history.size(), 1);
  EXPECT_EQ(hook_history.back().delegate_id, 1);
  EXPECT_EQ(hook_history.back().scancode, kHandledScanCode);
  EXPECT_EQ(hook_history.back().was_down, false);

  hook_history.clear();

  /// Test 2: An event unhandled by the framework

  delegate_handler = respond_false;
  handler.KeyboardHook(64, kHandledScanCode, WM_KEYDOWN, L'a', false, false,
                       OnKeyEventResult);
  EXPECT_EQ(key_event_response, kUnhandled);
  EXPECT_EQ(hook_history.size(), 1);
  EXPECT_EQ(hook_history.back().delegate_id, 1);
  EXPECT_EQ(hook_history.back().scancode, kHandledScanCode);
  EXPECT_EQ(hook_history.back().was_down, false);

  hook_history.clear();
  key_event_response = kNoResponse;
}

}  // namespace testing
}  // namespace flutter
