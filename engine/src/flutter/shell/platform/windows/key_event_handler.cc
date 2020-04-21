// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/key_event_handler.h"

#include <windows.h>

#include <iostream>

#include "flutter/shell/platform/common/cpp/json_message_codec.h"

static constexpr char kChannelName[] = "flutter/keyevent";

static constexpr char kKeyCodeKey[] = "keyCode";
static constexpr char kScanCodeKey[] = "scanCode";
static constexpr char kCharacterCodePointKey[] = "characterCodePoint";
static constexpr char kModifiersKey[] = "modifiers";
static constexpr char kKeyMapKey[] = "keymap";
static constexpr char kTypeKey[] = "type";

static constexpr char kWindowsKeyMap[] = "windows";
static constexpr char kKeyUp[] = "keyup";
static constexpr char kKeyDown[] = "keydown";

namespace flutter {

// Re-definition of the modifiers for compatibility with the Flutter framework.
// These have to be in sync with the framework's RawKeyEventDataWindows
// modifiers definition.
// https://github.com/flutter/flutter/blob/19ff596979e407c484a32f4071420fca4f4c885f/packages/flutter/lib/src/services/raw_keyboard_windows.dart#L203
const int kShift = 1 << 0;
const int kShiftLeft = 1 << 1;
const int kShiftRight = 1 << 2;
const int kControl = 1 << 3;
const int kControlLeft = 1 << 4;
const int kControlRight = 1 << 5;
const int kAlt = 1 << 6;
const int kAltLeft = 1 << 7;
const int kAltRight = 1 << 8;
const int kWinLeft = 1 << 9;
const int kWinRight = 1 << 10;
const int kCapsLock = 1 << 11;
const int kNumLock = 1 << 12;
const int kScrollLock = 1 << 13;

namespace {
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
}  // namespace

KeyEventHandler::KeyEventHandler(flutter::BinaryMessenger* messenger)
    : channel_(
          std::make_unique<flutter::BasicMessageChannel<rapidjson::Document>>(
              messenger,
              kChannelName,
              &flutter::JsonMessageCodec::GetInstance())) {}

KeyEventHandler::~KeyEventHandler() = default;

void KeyEventHandler::TextHook(Win32FlutterWindow* window,
                               const std::u16string& code_point) {}

void KeyEventHandler::KeyboardHook(Win32FlutterWindow* window,
                                   int key,
                                   int scancode,
                                   int action,
                                   char32_t character) {
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
      return;
  }
  channel_->Send(event);
}

}  // namespace flutter
