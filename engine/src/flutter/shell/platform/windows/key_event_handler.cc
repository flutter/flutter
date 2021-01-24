// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/key_event_handler.h"

#include <windows.h>

#include <iostream>

#include "flutter/shell/platform/common/cpp/json_message_codec.h"

namespace flutter {

namespace {

static constexpr char kChannelName[] = "flutter/keyevent";

static constexpr char kKeyCodeKey[] = "keyCode";
static constexpr char kScanCodeKey[] = "scanCode";
static constexpr char kCharacterCodePointKey[] = "characterCodePoint";
static constexpr char kModifiersKey[] = "modifiers";
static constexpr char kKeyMapKey[] = "keymap";
static constexpr char kTypeKey[] = "type";
static constexpr char kHandledKey[] = "handled";

static constexpr char kWindowsKeyMap[] = "windows";
static constexpr char kKeyUp[] = "keyup";
static constexpr char kKeyDown[] = "keydown";

// The maximum number of pending events to keep before
// emitting a warning on the console about unhandled events.
static constexpr int kMaxPendingEvents = 1000;

// Re-definition of the modifiers for compatibility with the Flutter framework.
// These have to be in sync with the framework's RawKeyEventDataWindows
// modifiers definition.
// https://github.com/flutter/flutter/blob/19ff596979e407c484a32f4071420fca4f4c885f/packages/flutter/lib/src/services/raw_keyboard_windows.dart#L203
static constexpr int kShift = 1 << 0;
static constexpr int kShiftLeft = 1 << 1;
static constexpr int kShiftRight = 1 << 2;
static constexpr int kControl = 1 << 3;
static constexpr int kControlLeft = 1 << 4;
static constexpr int kControlRight = 1 << 5;
static constexpr int kAlt = 1 << 6;
static constexpr int kAltLeft = 1 << 7;
static constexpr int kAltRight = 1 << 8;
static constexpr int kWinLeft = 1 << 9;
static constexpr int kWinRight = 1 << 10;
static constexpr int kCapsLock = 1 << 11;
static constexpr int kNumLock = 1 << 12;
static constexpr int kScrollLock = 1 << 13;

/// Calls GetKeyState() an all modifier keys and packs the result in an int,
/// with the re-defined values declared above for compatibility with the Flutter
/// framework.
int GetModsForKeyState() {
  int mods = 0;

  if (GetKeyState(VK_SHIFT) < 0)
    mods |= kShift;
  if (GetKeyState(VK_LSHIFT) < 0)
    mods |= kShiftLeft;
  if (GetKeyState(VK_RSHIFT) < 0)
    mods |= kShiftRight;
  if (GetKeyState(VK_CONTROL) < 0)
    mods |= kControl;
  if (GetKeyState(VK_LCONTROL) < 0)
    mods |= kControlLeft;
  if (GetKeyState(VK_RCONTROL) < 0)
    mods |= kControlRight;
  if (GetKeyState(VK_MENU) < 0)
    mods |= kAlt;
  if (GetKeyState(VK_LMENU) < 0)
    mods |= kAltLeft;
  if (GetKeyState(VK_RMENU) < 0)
    mods |= kAltRight;
  if (GetKeyState(VK_LWIN) < 0)
    mods |= kWinLeft;
  if (GetKeyState(VK_RWIN) < 0)
    mods |= kWinRight;
  if (GetKeyState(VK_CAPITAL) < 0)
    mods |= kCapsLock;
  if (GetKeyState(VK_NUMLOCK) < 0)
    mods |= kNumLock;
  if (GetKeyState(VK_SCROLL) < 0)
    mods |= kScrollLock;
  return mods;
}

// This uses event data instead of generating a serial number because
// information can't be attached to the redispatched events, so it has to be
// possible to compute an ID from the identifying data in the event when it is
// received again in order to differentiate between events that are new, and
// events that have been redispatched.
//
// Another alternative would be to compute a checksum from all the data in the
// event (just compute it over the bytes in the struct, probably skipping
// timestamps), but the fields used below are enough to differentiate them, and
// since Windows does some processing on the events (coming up with virtual key
// codes, setting timestamps, etc.), it's not clear that the redispatched
// events would have the same checksums.
uint64_t CalculateEventId(int scancode, int action, bool extended) {
  // Calculate a key event ID based on the scan code of the key pressed,
  // and the flags we care about.
  return scancode | (((action == WM_KEYUP ? KEYEVENTF_KEYUP : 0x0) |
                      (extended ? KEYEVENTF_EXTENDEDKEY : 0x0))
                     << 16);
}

}  // namespace

KeyEventHandler::KeyEventHandler(flutter::BinaryMessenger* messenger,
                                 KeyEventHandler::SendInputDelegate send_input)
    : channel_(
          std::make_unique<flutter::BasicMessageChannel<rapidjson::Document>>(
              messenger,
              kChannelName,
              &flutter::JsonMessageCodec::GetInstance())),
      send_input_(send_input) {
  assert(send_input != nullptr);
}

KeyEventHandler::~KeyEventHandler() = default;

void KeyEventHandler::TextHook(FlutterWindowsView* view,
                               const std::u16string& code_point) {}

KEYBDINPUT* KeyEventHandler::FindPendingEvent(uint64_t id) {
  if (pending_events_.empty()) {
    return nullptr;
  }
  for (auto iter = pending_events_.begin(); iter != pending_events_.end();
       ++iter) {
    if (iter->first == id) {
      return &iter->second;
    }
  }
  return nullptr;
}

void KeyEventHandler::RemovePendingEvent(uint64_t id) {
  for (auto iter = pending_events_.begin(); iter != pending_events_.end();
       ++iter) {
    if (iter->first == id) {
      pending_events_.erase(iter);
      return;
    }
  }
  std::cerr << "Tried to remove pending event with id " << id
            << ", but the event was not found." << std::endl;
}

void KeyEventHandler::AddPendingEvent(uint64_t id,
                                      int scancode,
                                      int action,
                                      bool extended) {
  if (pending_events_.size() > kMaxPendingEvents) {
    std::cerr
        << "There are " << pending_events_.size()
        << " keyboard events that have not yet received a response from the "
        << "framework. Are responses being sent?" << std::endl;
  }
  KEYBDINPUT key_event = KEYBDINPUT{0};
  key_event.wScan = scancode;
  key_event.dwFlags = KEYEVENTF_SCANCODE |
                      (extended ? KEYEVENTF_EXTENDEDKEY : 0x0) |
                      (action == WM_KEYUP ? KEYEVENTF_KEYUP : 0x0);
  pending_events_.push_back(std::make_pair(id, key_event));
}

void KeyEventHandler::HandleResponse(bool handled,
                                     uint64_t id,
                                     int action,
                                     bool extended,
                                     int scancode,
                                     int character) {
  if (handled) {
    this->RemovePendingEvent(id);
  } else {
    // Since the framework didn't handle the event, we inject a newly
    // synthesized one. We let Windows figure out the virtual key and
    // character for the given scancode, as well as a new timestamp.
    const KEYBDINPUT* key_event = this->FindPendingEvent(id);
    if (key_event == nullptr) {
      std::cerr << "Unable to find event " << id << " in pending events queue.";
      return;
    }
    INPUT input_event;
    input_event.type = INPUT_KEYBOARD;
    input_event.ki = *key_event;
    UINT accepted = send_input_(1, &input_event, sizeof(input_event));
    if (accepted != 1) {
      std::cerr << "Unable to synthesize event for unhandled keyboard event "
                   "with scancode "
                << scancode << " (character " << character << ")" << std::endl;
    }
  }
}

bool KeyEventHandler::KeyboardHook(FlutterWindowsView* view,
                                   int key,
                                   int scancode,
                                   int action,
                                   char32_t character,
                                   bool extended) {
  const uint64_t id = CalculateEventId(scancode, action, extended);
  if (FindPendingEvent(id) != nullptr) {
    // Don't pass messages that we synthesized to the framework again.
    RemovePendingEvent(id);
    return false;
  }

  // TODO: Translate to a cross-platform key code system rather than passing
  // the native key code.
  rapidjson::Document event(rapidjson::kObjectType);
  auto& allocator = event.GetAllocator();
  event.AddMember(kKeyCodeKey, key, allocator);
  event.AddMember(kScanCodeKey, scancode, allocator);
  event.AddMember(kCharacterCodePointKey, character, allocator);
  event.AddMember(kKeyMapKey, kWindowsKeyMap, allocator);
  event.AddMember(kModifiersKey, GetModsForKeyState(), allocator);

  switch (action) {
    case WM_KEYDOWN:
      event.AddMember(kTypeKey, kKeyDown, allocator);
      break;
    case WM_KEYUP:
      event.AddMember(kTypeKey, kKeyUp, allocator);
      break;
    default:
      std::cerr << "Unknown key event action: " << action << std::endl;
      return false;
  }
  AddPendingEvent(id, scancode, action, extended);
  channel_->Send(event, [this, id, action, extended, scancode, character](
                            const uint8_t* reply, size_t reply_size) {
    auto decoded = flutter::JsonMessageCodec::GetInstance().DecodeMessage(
        reply, reply_size);
    bool handled = (*decoded)[kHandledKey].GetBool();
    this->HandleResponse(handled, id, action, extended, scancode, character);
  });
  return true;
}

void KeyEventHandler::ComposeBeginHook() {
  // Ignore.
}

void KeyEventHandler::ComposeEndHook() {
  // Ignore.
}

void KeyEventHandler::ComposeChangeHook(const std::u16string& text,
                                        int cursor_pos) {
  // Ignore.
}

}  // namespace flutter
