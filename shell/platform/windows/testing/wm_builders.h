// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WM_BUILDERS_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WM_BUILDERS_H_

#include <stdint.h>
#include <windows.h>
#include <windowsx.h>

namespace flutter {
namespace testing {

constexpr LRESULT kWmResultZero = 0;
constexpr LRESULT kWmResultDefault = 0xDEADC0DE;
constexpr LRESULT kWmResultDontCheck = 0xFFFF1234;

// A struc to hold simulated events that will be delivered after the framework
// response is handled.
struct Win32Message {
  UINT message;
  WPARAM wParam;
  LPARAM lParam;
  LRESULT expected_result;
  HWND hWnd;
};

typedef enum WmFieldExtended {
  kNotExtended = 0,
  kExtended = 1,
} WmFieldExtended;

typedef enum WmFieldContext {
  kNoContext = 0,
  kAltHeld = 1,
} WmFieldContext;

typedef enum WmFieldPrevState {
  kWasUp = 0,
  kWasDown = 1,
} WmFieldPrevState;

typedef enum WmFieldTransitionState {
  kBeingReleased = 0,
  kBeingPressed = 1,
} WmFieldTransitionState;

// WM_KEYDOWN messages.
//
// See https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-keydown.
typedef struct WmKeyDownInfo {
  uint32_t key;

  uint8_t scan_code;

  WmFieldExtended extended;

  WmFieldPrevState prev_state;

  // WmFieldTransitionState transition; // Always 0.

  // WmFieldContext context; // Always 0.

  uint16_t repeat_count = 1;

  Win32Message Build(LRESULT expected_result = kWmResultDontCheck,
                     HWND hWnd = NULL);
} WmKeyDownInfo;

// Win32Message BuildMessage(WmKeyDownInfo info, LRESULT expected_result =
// kWmResultDontCheck, HWND hWnd = NULL);

// WM_KEYUP  messages.
//
// See https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-keyup.
typedef struct WmKeyUpInfo {
  uint32_t key;

  uint8_t scan_code;

  WmFieldExtended extended;

  // WmFieldPrevState prev_state; // Always 1.

  // WmFieldTransitionState transition; // Always 1.

  // WmFieldContext context; // Always 0.

  // uint16_t repeat_count;  // Always 1.

  Win32Message Build(LRESULT expected_result = kWmResultDontCheck,
                     HWND hWnd = NULL);
} WmKeyUpInfo;

// WM_CHAR  messages.
//
// See https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-char.
typedef struct WmCharInfo {
  uint32_t char_code;

  uint8_t scan_code;

  WmFieldExtended extended;

  WmFieldPrevState prev_state;

  WmFieldTransitionState transition;

  WmFieldContext context;

  uint16_t repeat_count = 1;

  Win32Message Build(LRESULT expected_result = kWmResultDontCheck,
                     HWND hWnd = NULL);
} WmCharInfo;

// WM_SYSKEYDOWN  messages.
//
// See https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-syskeydown.
typedef struct WmSysKeyDownInfo {
  uint32_t key;

  uint8_t scan_code;

  WmFieldExtended extended;

  WmFieldPrevState prev_state;

  // WmFieldTransitionState transition; // Always 0.

  WmFieldContext context;

  uint16_t repeat_count;

  Win32Message Build(LRESULT expected_result = kWmResultDontCheck,
                     HWND hWnd = NULL);
} WmSysKeyDownInfo;

// WM_SYSKEYUP  messages.
//
// See https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-syskeyup.
typedef struct WmSysKeyUpInfo {
  uint32_t key;

  uint8_t scan_code;

  WmFieldExtended extended;

  // WmFieldPrevState prev_state; // Always 1.

  // WmFieldTransitionState transition; // Always 1.

  WmFieldContext context;

  // uint16_t repeat_count;  // Always 1.

  Win32Message Build(LRESULT expected_result = kWmResultDontCheck,
                     HWND hWnd = NULL);
} WmSysKeyUpInfo;

// WM_DEADCHAR messages.
//
// See https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-deadchar.
typedef struct WmDeadCharInfo {
  uint32_t char_code;

  uint8_t scan_code;

  WmFieldExtended extended;

  WmFieldPrevState prev_state;

  WmFieldTransitionState transition;

  WmFieldContext context;

  uint16_t repeat_count = 1;

  Win32Message Build(LRESULT expected_result = kWmResultDontCheck,
                     HWND hWnd = NULL);
} WmDeadCharInfo;

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_WM_BUILDERS_H_
