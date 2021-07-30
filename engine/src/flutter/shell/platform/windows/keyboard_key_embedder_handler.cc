// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/keyboard_key_embedder_handler.h"

#include <assert.h>
#include <windows.h>

#include <chrono>
#include <codecvt>
#include <iostream>
#include <string>

#include "flutter/shell/platform/windows/string_conversion.h"

namespace flutter {

namespace {
// An arbitrary size for the character cache in bytes.
//
// It should hold a UTF-32 character encoded in UTF-8 as well as the trailing
// '\0'.
constexpr size_t kCharacterCacheSize = 8;

constexpr SHORT kStateMaskToggled = 0x01;
constexpr SHORT kStateMaskPressed = 0x80;

const char* empty_character = "";
}  // namespace

KeyboardKeyEmbedderHandler::KeyboardKeyEmbedderHandler(
    SendEvent send_event,
    GetKeyStateHandler get_key_state)
    : sendEvent_(send_event), get_key_state_(get_key_state), response_id_(1) {
  InitCriticalKeys();
}

KeyboardKeyEmbedderHandler::~KeyboardKeyEmbedderHandler() = default;

static bool isEasciiPrintable(int codeUnit) {
  return (codeUnit <= 0x7f && codeUnit >= 0x20) ||
         (codeUnit <= 0xff && codeUnit >= 0x80);
}

// Converts upper letters to lower letters in ASCII and extended ASCII, and
// returns as-is otherwise.
//
// Independent of locale.
static uint64_t toLower(uint64_t n) {
  constexpr uint64_t lower_a = 0x61;
  constexpr uint64_t upper_a = 0x41;
  constexpr uint64_t upper_z = 0x5a;

  constexpr uint64_t lower_a_grave = 0xe0;
  constexpr uint64_t upper_a_grave = 0xc0;
  constexpr uint64_t upper_thorn = 0xde;
  constexpr uint64_t division = 0xf7;

  // ASCII range.
  if (n >= upper_a && n <= upper_z) {
    return n - upper_a + lower_a;
  }

  // EASCII range.
  if (n >= upper_a_grave && n <= upper_thorn && n != division) {
    return n - upper_a_grave + lower_a_grave;
  }

  return n;
}

// Transform scancodes sent by windows to scancodes written in Chromium spec.
static uint16_t normalizeScancode(int windowsScanCode, bool extended) {
  // In Chromium spec the extended bit is shown as 0xe000 bit,
  // e.g. PageUp is represented as 0xe049.
  return (windowsScanCode & 0xff) | (extended ? 0xe000 : 0);
}

uint64_t KeyboardKeyEmbedderHandler::ApplyPlaneToId(uint64_t id,
                                                    uint64_t plane) {
  return (id & valueMask) | plane;
}

uint64_t KeyboardKeyEmbedderHandler::GetPhysicalKey(int scancode,
                                                    bool extended) {
  int chromiumScancode = normalizeScancode(scancode, extended);
  auto resultIt = windowsToPhysicalMap_.find(chromiumScancode);
  if (resultIt != windowsToPhysicalMap_.end())
    return resultIt->second;
  return ApplyPlaneToId(scancode, windowsPlane);
}

uint64_t KeyboardKeyEmbedderHandler::GetLogicalKey(int key,
                                                   bool extended,
                                                   int scancode) {
  // Normally logical keys should only be derived from key codes, but since some
  // key codes are either 0 or ambiguous (multiple keys using the same key
  // code), these keys are resolved by scan codes.
  auto numpadIter =
      scanCodeToLogicalMap_.find(normalizeScancode(scancode, extended));
  if (numpadIter != scanCodeToLogicalMap_.cend())
    return numpadIter->second;

  // Check if the keyCode is one we know about and have a mapping for.
  auto logicalIt = windowsToLogicalMap_.find(key);
  if (logicalIt != windowsToLogicalMap_.cend())
    return logicalIt->second;

  // Upper case letters should be normalized into lower case letters.
  if (isEasciiPrintable(key)) {
    return ApplyPlaneToId(toLower(key), unicodePlane);
  }

  return ApplyPlaneToId(toLower(key), windowsPlane);
}

void KeyboardKeyEmbedderHandler::KeyboardHook(
    int key,
    int scancode,
    int action,
    char32_t character,
    bool extended,
    bool was_down,
    std::function<void(bool)> callback) {
  const uint64_t physical_key = GetPhysicalKey(scancode, extended);
  const uint64_t logical_key = GetLogicalKey(key, extended, scancode);
  assert(action == WM_KEYDOWN || action == WM_KEYUP);
  const bool is_physical_down = action == WM_KEYDOWN;

  auto last_logical_record_iter = pressingRecords_.find(physical_key);
  const bool had_record = last_logical_record_iter != pressingRecords_.end();
  const uint64_t last_logical_record =
      had_record ? last_logical_record_iter->second : 0;

  // The resulting event's `type`.
  FlutterKeyEventType type;
  // The resulting event's `logical_key`.
  uint64_t result_logical_key;
  // The next value of pressingRecords_[physical_key] (or to remove it).
  uint64_t next_logical_record;
  bool next_has_record = true;
  char character_bytes[kCharacterCacheSize];

  if (is_physical_down) {
    if (had_record) {
      if (was_down) {
        // A normal repeated key.
        type = kFlutterKeyEventTypeRepeat;
        assert(had_record);
        ConvertUtf32ToUtf8_(character_bytes, character);
        next_logical_record = last_logical_record;
        result_logical_key = last_logical_record;
      } else {
        // A non-repeated key has been pressed that has the exact physical key
        // as a currently pressed one, usually indicating multiple keyboards are
        // pressing keys with the same physical key, or the up event was lost
        // during a loss of focus. The down event is ignored.
        sendEvent_(CreateEmptyEvent(), nullptr, nullptr);
        callback(true);
        return;
      }
    } else {
      // A normal down event (whether the system event is a repeat or not).
      type = kFlutterKeyEventTypeDown;
      assert(!had_record);
      ConvertUtf32ToUtf8_(character_bytes, character);
      next_logical_record = logical_key;
      result_logical_key = logical_key;
    }
  } else {  // isPhysicalDown is false
    if (last_logical_record == 0) {
      // The physical key has been released before. It might indicate a missed
      // event due to loss of focus, or multiple keyboards pressed keys with the
      // same physical key. Ignore the up event.
      sendEvent_(CreateEmptyEvent(), nullptr, nullptr);
      callback(true);
      return;
    } else {
      // A normal up event.
      type = kFlutterKeyEventTypeUp;
      assert(had_record);
      // Up events never have character.
      character_bytes[0] = '\0';
      next_has_record = false;
      result_logical_key = last_logical_record;
    }
  }

  UpdateLastSeenCritialKey(key, physical_key, result_logical_key);
  SynchronizeCritialToggledStates(type == kFlutterKeyEventTypeDown ? key : 0);

  if (next_has_record) {
    pressingRecords_[physical_key] = next_logical_record;
  } else {
    pressingRecords_.erase(last_logical_record_iter);
  }

  SynchronizeCritialPressedStates();

  if (result_logical_key == VK_PROCESSKEY) {
    // VK_PROCESSKEY means that the key press is used by an IME. These key
    // presses are considered handled and not sent to Flutter. These events must
    // be filtered by result_logical_key because the key up event of such
    // presses uses the "original" logical key.
    sendEvent_(CreateEmptyEvent(), nullptr, nullptr);
    callback(true);
    return;
  }

  FlutterKeyEvent key_data{
      .struct_size = sizeof(FlutterKeyEvent),
      .timestamp = static_cast<double>(
          std::chrono::duration_cast<std::chrono::microseconds>(
              std::chrono::high_resolution_clock::now().time_since_epoch())
              .count()),
      .type = type,
      .physical = physical_key,
      .logical = result_logical_key,
      .character = character_bytes,
      .synthesized = false,
  };

  response_id_ += 1;
  uint64_t response_id = response_id_;
  PendingResponse pending{
      .callback =
          [this, callback = std::move(callback)](bool handled,
                                                 uint64_t response_id) {
            auto found = pending_responses_.find(response_id);
            if (found != pending_responses_.end()) {
              pending_responses_.erase(found);
            }
            callback(handled);
          },
      .response_id = response_id,
  };
  auto pending_ptr = std::make_unique<PendingResponse>(std::move(pending));
  pending_responses_[response_id] = std::move(pending_ptr);
  sendEvent_(key_data, KeyboardKeyEmbedderHandler::HandleResponse,
             reinterpret_cast<void*>(pending_responses_[response_id].get()));
}

void KeyboardKeyEmbedderHandler::UpdateLastSeenCritialKey(
    int virtual_key,
    uint64_t physical_key,
    uint64_t logical_key) {
  auto found = critical_keys_.find(virtual_key);
  if (found != critical_keys_.end()) {
    found->second.physical_key = physical_key;
    found->second.logical_key = logical_key;
  }
}

void KeyboardKeyEmbedderHandler::SynchronizeCritialToggledStates(
    int toggle_virtual_key) {
  // TODO(dkwingsmt) consider adding support for synchronizing key state for UWP
  // https://github.com/flutter/flutter/issues/70202
#ifdef WINUWP
  return;
#else
  for (auto& kv : critical_keys_) {
    UINT virtual_key = kv.first;
    CriticalKey& key_info = kv.second;
    if (key_info.physical_key == 0) {
      // Never seen this key.
      continue;
    }
    assert(key_info.logical_key != 0);
    SHORT state = get_key_state_(virtual_key);

    // Check toggling state first, because it might alter pressing state.
    if (key_info.check_toggled) {
      bool should_toggled = state & kStateMaskToggled;
      if (virtual_key == toggle_virtual_key) {
        key_info.toggled_on = !key_info.toggled_on;
      }
      if (key_info.toggled_on != should_toggled) {
        // If the key is pressed, release it first.
        if (pressingRecords_.find(key_info.physical_key) !=
            pressingRecords_.end()) {
          sendEvent_(SynthesizeSimpleEvent(
                         kFlutterKeyEventTypeUp, key_info.physical_key,
                         key_info.logical_key, empty_character),
                     nullptr, nullptr);
        } else {
          // This key will always be pressed in the following synthesized event.
          pressingRecords_[key_info.physical_key] = key_info.logical_key;
        }
        sendEvent_(SynthesizeSimpleEvent(kFlutterKeyEventTypeDown,
                                         key_info.physical_key,
                                         key_info.logical_key, empty_character),
                   nullptr, nullptr);
      }
      key_info.toggled_on = should_toggled;
    }
  }
#endif
}

void KeyboardKeyEmbedderHandler::SynchronizeCritialPressedStates() {
  // TODO(dkwingsmt) consider adding support for synchronizing key state for UWP
  // https://github.com/flutter/flutter/issues/70202
#ifdef WINUWP
  return;
#else
  for (auto& kv : critical_keys_) {
    UINT virtual_key = kv.first;
    CriticalKey& key_info = kv.second;
    if (key_info.physical_key == 0) {
      // Never seen this key.
      continue;
    }
    assert(key_info.logical_key != 0);
    SHORT state = get_key_state_(virtual_key);
    if (key_info.check_pressed) {
      auto recorded_pressed_iter = pressingRecords_.find(key_info.physical_key);
      bool recorded_pressed = recorded_pressed_iter != pressingRecords_.end();
      bool should_pressed = state & kStateMaskPressed;
      if (recorded_pressed != should_pressed) {
        if (should_pressed) {
          pressingRecords_[key_info.physical_key] = key_info.logical_key;
        } else {
          pressingRecords_.erase(recorded_pressed_iter);
        }
        const char* empty_character = "";
        sendEvent_(
            SynthesizeSimpleEvent(should_pressed ? kFlutterKeyEventTypeDown
                                                 : kFlutterKeyEventTypeUp,
                                  key_info.physical_key, key_info.logical_key,
                                  empty_character),
            nullptr, nullptr);
      }
    }
  }
#endif
}

void KeyboardKeyEmbedderHandler::HandleResponse(bool handled, void* user_data) {
  PendingResponse* pending = reinterpret_cast<PendingResponse*>(user_data);
  auto callback = std::move(pending->callback);
  callback(handled, pending->response_id);
}

void KeyboardKeyEmbedderHandler::InitCriticalKeys() {
  // TODO(dkwingsmt) consider adding support for synchronizing key state for UWP
  // https://github.com/flutter/flutter/issues/70202
#ifdef WINUWP
  return;
#else
  auto createCheckedKey = [this](UINT virtual_key, bool extended,
                                 bool check_pressed,
                                 bool check_toggled) -> CriticalKey {
    UINT scan_code = MapVirtualKey(virtual_key, MAPVK_VK_TO_VSC);
    return CriticalKey{
        .physical_key = GetPhysicalKey(scan_code, extended),
        .logical_key = GetLogicalKey(virtual_key, extended, scan_code),
        .check_pressed = check_pressed || check_toggled,
        .check_toggled = check_toggled,
        .toggled_on = check_toggled
                          ? !!(get_key_state_(virtual_key) & kStateMaskToggled)
                          : false,
    };
  };

  // TODO(dkwingsmt): Consider adding more critical keys here.
  // https://github.com/flutter/flutter/issues/76736
  critical_keys_.emplace(VK_LSHIFT,
                         createCheckedKey(VK_LSHIFT, false, true, false));
  critical_keys_.emplace(VK_RSHIFT,
                         createCheckedKey(VK_RSHIFT, false, true, false));
  critical_keys_.emplace(VK_LCONTROL,
                         createCheckedKey(VK_LCONTROL, false, true, false));
  critical_keys_.emplace(VK_RCONTROL,
                         createCheckedKey(VK_RCONTROL, true, true, false));

  critical_keys_.emplace(VK_CAPITAL,
                         createCheckedKey(VK_CAPITAL, false, true, true));
  critical_keys_.emplace(VK_SCROLL,
                         createCheckedKey(VK_SCROLL, false, true, true));
  critical_keys_.emplace(VK_NUMLOCK,
                         createCheckedKey(VK_NUMLOCK, true, true, true));
#endif
}

void KeyboardKeyEmbedderHandler::ConvertUtf32ToUtf8_(char* out, char32_t ch) {
  if (ch == 0) {
    out[0] = '\0';
    return;
  }
  // TODO: Correctly handle UTF-32
  std::wstring text({static_cast<wchar_t>(ch)});
  strcpy_s(out, kCharacterCacheSize, Utf8FromUtf16(text).c_str());
}

FlutterKeyEvent KeyboardKeyEmbedderHandler::CreateEmptyEvent() {
  return FlutterKeyEvent{
      .struct_size = sizeof(FlutterKeyEvent),
      .timestamp = static_cast<double>(
          std::chrono::duration_cast<std::chrono::microseconds>(
              std::chrono::high_resolution_clock::now().time_since_epoch())
              .count()),
      .type = kFlutterKeyEventTypeDown,
      .physical = 0,
      .logical = 0,
      .character = empty_character,
      .synthesized = false,
  };
}

FlutterKeyEvent KeyboardKeyEmbedderHandler::SynthesizeSimpleEvent(
    FlutterKeyEventType type,
    uint64_t physical,
    uint64_t logical,
    const char* character) {
  return FlutterKeyEvent{
      .struct_size = sizeof(FlutterKeyEvent),
      .timestamp = static_cast<double>(
          std::chrono::duration_cast<std::chrono::microseconds>(
              std::chrono::high_resolution_clock::now().time_since_epoch())
              .count()),
      .type = type,
      .physical = physical,
      .logical = logical,
      .character = character,
      .synthesized = true,
  };
}

}  // namespace flutter
