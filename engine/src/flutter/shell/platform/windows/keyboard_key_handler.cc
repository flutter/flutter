// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/keyboard_key_handler.h"

#include <windows.h>

#include <iostream>

#include "flutter/shell/platform/windows/keyboard_win32_common.h"

namespace flutter {

namespace {

// The maximum number of pending events to keep before
// emitting a warning on the console about unhandled events.
static constexpr int kMaxPendingEvents = 1000;

}  // namespace

KeyboardKeyHandler::KeyboardKeyHandlerDelegate::~KeyboardKeyHandlerDelegate() =
    default;

KeyboardKeyHandler::KeyboardKeyHandler() : last_sequence_id_(1) {}

KeyboardKeyHandler::~KeyboardKeyHandler() = default;

void KeyboardKeyHandler::AddDelegate(
    std::unique_ptr<KeyboardKeyHandlerDelegate> delegate) {
  delegates_.push_back(std::move(delegate));
}

void KeyboardKeyHandler::KeyboardHook(int key,
                                      int scancode,
                                      int action,
                                      char32_t character,
                                      bool extended,
                                      bool was_down,
                                      KeyEventCallback callback) {
  std::unique_ptr<PendingEvent> incoming = std::make_unique<PendingEvent>();

  uint64_t sequence_id = ++last_sequence_id_;
  incoming->sequence_id = sequence_id;
  incoming->unreplied = delegates_.size();
  incoming->any_handled = false;
  incoming->callback = std::move(callback);

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
      // If all delegates have replied, report if any of them handled the event.
      if (event.unreplied == 0) {
        std::unique_ptr<PendingEvent> event_ptr = std::move(*iter);
        pending_responds_.erase(iter);
        event.callback(event.any_handled);
      }
      // Return here; |iter| can't do ++ after erase.
      return;
    }
  }
  // The pending event should always be found.
  assert(false);
}

}  // namespace flutter
