// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_KEYCODES_DOM4_KEYCODE_CONVERTER_H_
#define UI_EVENTS_KEYCODES_DOM4_KEYCODE_CONVERTER_H_

#include <stdint.h>
#include "base/basictypes.h"

// For reference, the W3C UI Event spec is located at:
// http://www.w3.org/TR/uievents/

namespace ui {

// This structure is used to define the keycode mapping table.
// It is defined here because the unittests need access to it.
typedef struct {
  // USB keycode:
  //  Upper 16-bits: USB Usage Page.
  //  Lower 16-bits: USB Usage Id: Assigned ID within this usage page.
  uint32_t usb_keycode;

  // Contains one of the following:
  //  On Linux: XKB scancode
  //  On Windows: Windows OEM scancode
  //  On Mac: Mac keycode
  uint16_t native_keycode;

  // The UIEvents (aka: DOM4Events) |code| value as defined in:
  // https://dvcs.w3.org/hg/d4e/raw-file/tip/source_respec.htm
  const char* code;
} KeycodeMapEntry;

// A class to convert between the current platform's native keycode (scancode)
// and platform-neutral |code| values (as defined in the W3C UI Events
// spec (http://www.w3.org/TR/uievents/).
class KeycodeConverter {
 public:
  // Return the value that identifies an invalid native keycode.
  static uint16_t InvalidNativeKeycode();

  // Return the string that indentifies an invalid UI Event |code|.
  // The returned pointer references a static global string.
  static const char* InvalidKeyboardEventCode();

  // Convert a native (Mac/Win/Linux) keycode into the |code| string.
  // The returned pointer references a static global string.
  static const char* NativeKeycodeToCode(uint16_t native_keycode);

  // Convert a UI Events |code| string value into a native keycode.
  static uint16_t CodeToNativeKeycode(const char* code);

  // The following methods relate to USB keycodes.
  // Note that USB keycodes are not part of any web standard.
  // Please don't use USB keycodes in new code.

  // Return the value that identifies an invalid USB keycode.
  static uint16_t InvalidUsbKeycode();

  // Convert a USB keycode into an equivalent platform native keycode.
  static uint16_t UsbKeycodeToNativeKeycode(uint32_t usb_keycode);

  // Convert a platform native keycode into an equivalent USB keycode.
  static uint32_t NativeKeycodeToUsbKeycode(uint16_t native_keycode);

  // Convert a USB keycode into the string with the DOM3 |code| value.
  // The returned pointer references a static global string.
  static const char* UsbKeycodeToCode(uint32_t usb_keycode);

  // Convert a DOM3 Event |code| string into a USB keycode value.
  static uint32_t CodeToUsbKeycode(const char* code);

  // Static methods to support testing.
  static size_t NumKeycodeMapEntriesForTest();
  static const KeycodeMapEntry* GetKeycodeMapForTest();

 private:
  DISALLOW_COPY_AND_ASSIGN(KeycodeConverter);
};

}  // namespace ui

#endif  // UI_EVENTS_KEYCODES_DOM4_KEYCODE_CONVERTER_H_
