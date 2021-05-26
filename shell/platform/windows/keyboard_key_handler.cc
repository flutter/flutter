// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/keyboard_key_handler.h"

#include <windows.h>

#include <iostream>

#include "flutter/shell/platform/common/json_message_codec.h"

namespace flutter {

namespace {

// The maximum number of pending events to keep before
// emitting a warning on the console about unhandled events.
static constexpr int kMaxPendingEvents = 1000;

}  // namespace

KeyboardKeyHandler::KeyboardKeyHandlerDelegate::~KeyboardKeyHandlerDelegate() =
    default;

KeyboardKeyHandler::KeyboardKeyHandler(EventRedispatcher redispatch_event)
    : redispatch_event_(redispatch_event), last_sequence_id_(1) {}

KeyboardKeyHandler::~KeyboardKeyHandler() = default;

void KeyboardKeyHandler::TextHook(FlutterWindowsView* view,
                                  const std::u16string& code_point) {}

void KeyboardKeyHandler::AddDelegate(
    std::unique_ptr<KeyboardKeyHandlerDelegate> delegate) {
  delegates_.push_back(std::move(delegate));
}

size_t KeyboardKeyHandler::RedispatchedCount() {
  return pending_redispatches_.size();
}

void KeyboardKeyHandler::RedispatchEvent(std::unique_ptr<PendingEvent> event) {
  // TODO(dkwingsmt) consider adding support for redispatching events for UWP
  // in order to support add-to-app.
  // https://github.com/flutter/flutter/issues/70202
#ifdef WINUWP
  return;
#else
  uint8_t scancode = event->scancode;
  char32_t character = event->character;

  INPUT input_event{
      .type = INPUT_KEYBOARD,
      .ki =
          KEYBDINPUT{
              .wVk = 0,
              .wScan = static_cast<WORD>(event->scancode),
              .dwFlags = static_cast<WORD>(
                  KEYEVENTF_SCANCODE |
                  (event->extended ? KEYEVENTF_EXTENDEDKEY : 0x0) |
                  (event->action == WM_KEYUP ? KEYEVENTF_KEYUP : 0x0)),
          },
  };

  pending_redispatches_.push_back(std::move(event));

  UINT accepted = redispatch_event_(1, &input_event, sizeof(input_event));
  if (accepted != 1) {
    std::cerr << "Unable to synthesize event for unhandled keyboard event "
                 "with scancode "
              << scancode << " (character " << character << ")" << std::endl;
  }
#endif
}

bool KeyboardKeyHandler::KeyboardHook(FlutterWindowsView* view,
                                      int key,
                                      int scancode,
                                      int action,
                                      char32_t character,
                                      bool extended,
                                      bool was_down) {
  std::unique_ptr<PendingEvent> incoming =
      std::make_unique<PendingEvent>(PendingEvent{
          .key = static_cast<uint32_t>(key),
          .scancode = static_cast<uint8_t>(scancode),
          .action = static_cast<uint32_t>(action),
          .character = character,
          .extended = extended,
          .was_down = was_down,
      });
  incoming->hash = ComputeEventHash(*incoming);

  if (RemoveRedispatchedEvent(*incoming)) {
    return false;
  }

  uint64_t sequence_id = ++last_sequence_id_;
  incoming->sequence_id = sequence_id;
  incoming->unreplied = delegates_.size();
  incoming->any_handled = false;

  if (pending_responds_.size() > kMaxPendingEvents) {
    std::cerr
        << "There are " << pending_responds_.size()
        << " keyboard events that have not yet received a response from the "
        << "framework. Are responses being sent?" << std::endl;
  }
  pending_responds_.push_back(std::move(incoming));

  for (const auto& delegate : delegates_) {
    delegate->KeyboardHook(key, scancode, action, character, extended, was_down,
                           [sequence_id, this](bool handled) {
                             ResolvePendingEvent(sequence_id, handled);
                           });
  }

  // |ResolvePendingEvent| might trigger redispatching synchronously,
  // which might occur before |KeyboardHook| is returned. This won't
  // make events out of order though, because |KeyboardHook| will always
  // return true at this time, preventing this event from affecting
  // others.

  return true;
}

bool KeyboardKeyHandler::RemoveRedispatchedEvent(const PendingEvent& incoming) {
  for (auto iter = pending_redispatches_.begin();
       iter != pending_redispatches_.end(); ++iter) {
    if ((*iter)->hash == incoming.hash) {
      pending_redispatches_.erase(iter);
      return true;
    }
  }
  return false;
}

void KeyboardKeyHandler::ResolvePendingEvent(uint64_t sequence_id,
                                             bool handled) {
  // Find the pending event
  for (auto iter = pending_responds_.begin(); iter != pending_responds_.end();
       ++iter) {
    if ((*iter)->sequence_id == sequence_id) {
      PendingEvent& event = **iter;
      event.any_handled = event.any_handled || handled;
      event.unreplied -= 1;
      assert(event.unreplied >= 0);
      // If all delegates have replied, redispatch if no one handled.
      if (event.unreplied == 0) {
        auto event_ptr = std::move(*iter);
        pending_responds_.erase(iter);
        if (!event_ptr->any_handled) {
          RedispatchEvent(std::move(event_ptr));
        }
      }
      // Return here; |iter| can't do ++ after erase.
      return;
    }
  }
  // The pending event should always be found.
  assert(false);
}

void KeyboardKeyHandler::ComposeBeginHook() {
  // Ignore.
}

void KeyboardKeyHandler::ComposeCommitHook() {
  // Ignore.
}

void KeyboardKeyHandler::ComposeEndHook() {
  // Ignore.
}

void KeyboardKeyHandler::ComposeChangeHook(const std::u16string& text,
                                           int cursor_pos) {
  // Ignore.
}

uint64_t KeyboardKeyHandler::ComputeEventHash(const PendingEvent& event) {
  // Calculate a key event ID based on the scan code of the key pressed,
  // and the flags we care about.
  return event.scancode | (((event.action == WM_KEYUP ? KEYEVENTF_KEYUP : 0x0) |
                            (event.extended ? KEYEVENTF_EXTENDEDKEY : 0x0))
                           << 16);
}

}  // namespace flutter
