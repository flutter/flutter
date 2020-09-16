// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/win32_window.h"

#include <cstring>

#include "win32_dpi_utils.h"

namespace flutter {

namespace {
char32_t CodePointFromSurrogatePair(wchar_t high, wchar_t low) {
  return 0x10000 + ((static_cast<char32_t>(high) & 0x000003FF) << 10) +
         (low & 0x3FF);
}
}  // namespace

Win32Window::Win32Window() {
  // Get the DPI of the primary monitor as the initial DPI. If Per-Monitor V2 is
  // supported, |current_dpi_| should be updated in the
  // kWmDpiChangedBeforeParent message.
  current_dpi_ = GetDpiForHWND(nullptr);
}

Win32Window::~Win32Window() {
  Destroy();
}

void Win32Window::InitializeChild(const char* title,
                                  unsigned int width,
                                  unsigned int height) {
  Destroy();
  std::wstring converted_title = NarrowToWide(title);

  WNDCLASS window_class = RegisterWindowClass(converted_title);

  auto* result = CreateWindowEx(
      0, window_class.lpszClassName, converted_title.c_str(),
      WS_CHILD | WS_VISIBLE, CW_DEFAULT, CW_DEFAULT, width, height,
      HWND_MESSAGE, nullptr, window_class.hInstance, this);

  if (result == nullptr) {
    auto error = GetLastError();
    LPWSTR message = nullptr;
    size_t size = FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL, error, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        reinterpret_cast<LPWSTR>(&message), 0, NULL);
    OutputDebugString(message);
    LocalFree(message);
  }
}

std::wstring Win32Window::NarrowToWide(const char* source) {
  size_t length = strlen(source);
  size_t outlen = 0;
  std::wstring wideTitle(length, L'#');
  mbstowcs_s(&outlen, &wideTitle[0], length + 1, source, length);
  return wideTitle;
}

WNDCLASS Win32Window::RegisterWindowClass(std::wstring& title) {
  window_class_name_ = title;

  WNDCLASS window_class{};
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = title.c_str();
  window_class.style = CS_HREDRAW | CS_VREDRAW;
  window_class.cbClsExtra = 0;
  window_class.cbWndExtra = 0;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hIcon = nullptr;
  window_class.hbrBackground = 0;
  window_class.lpszMenuName = nullptr;
  window_class.lpfnWndProc = WndProc;
  RegisterClass(&window_class);
  return window_class;
}

LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(cs->lpCreateParams));

    auto that = static_cast<Win32Window*>(cs->lpCreateParams);
    that->window_handle_ = window;
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->HandleMessage(message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

void Win32Window::TrackMouseLeaveEvent(HWND hwnd) {
  if (!tracking_mouse_leave_) {
    TRACKMOUSEEVENT tme;
    tme.cbSize = sizeof(tme);
    tme.hwndTrack = hwnd;
    tme.dwFlags = TME_LEAVE;
    TrackMouseEvent(&tme);
    tracking_mouse_leave_ = true;
  }
}

LRESULT
Win32Window::HandleMessage(UINT const message,
                           WPARAM const wparam,
                           LPARAM const lparam) noexcept {
  int xPos = 0, yPos = 0;
  UINT width = 0, height = 0;
  UINT button_pressed = 0;

  switch (message) {
    case kWmDpiChangedBeforeParent:
      current_dpi_ = GetDpiForHWND(window_handle_);
      OnDpiScale(current_dpi_);
      return 0;
    case WM_SIZE:
      width = LOWORD(lparam);
      height = HIWORD(lparam);

      current_width_ = width;
      current_height_ = height;
      HandleResize(width, height);
      break;
    case WM_MOUSEMOVE:
      TrackMouseLeaveEvent(window_handle_);

      xPos = GET_X_LPARAM(lparam);
      yPos = GET_Y_LPARAM(lparam);
      OnPointerMove(static_cast<double>(xPos), static_cast<double>(yPos));
      break;
    case WM_MOUSELEAVE:;
      OnPointerLeave();
      // Once the tracked event is received, the TrackMouseEvent function
      // resets. Set to false to make sure it's called once mouse movement is
      // detected again.
      tracking_mouse_leave_ = false;
      break;
    case WM_SETCURSOR: {
      UINT hit_test_result = LOWORD(lparam);
      if (hit_test_result == HTCLIENT) {
        OnSetCursor();
        return TRUE;
      }
      break;
    }
    case WM_LBUTTONDOWN:
    case WM_RBUTTONDOWN:
    case WM_MBUTTONDOWN:
    case WM_XBUTTONDOWN:
      if (message == WM_LBUTTONDOWN) {
        // Capture the pointer in case the user drags outside the client area.
        // In this case, the "mouse leave" event is delayed until the user
        // releases the button. It's only activated on left click given that
        // it's more common for apps to handle dragging with only the left
        // button.
        SetCapture(window_handle_);
      }
      button_pressed = message;
      if (message == WM_XBUTTONDOWN) {
        button_pressed = GET_XBUTTON_WPARAM(wparam);
      }
      xPos = GET_X_LPARAM(lparam);
      yPos = GET_Y_LPARAM(lparam);
      OnPointerDown(static_cast<double>(xPos), static_cast<double>(yPos),
                    button_pressed);
      break;
    case WM_LBUTTONUP:
    case WM_RBUTTONUP:
    case WM_MBUTTONUP:
    case WM_XBUTTONUP:
      if (message == WM_LBUTTONUP) {
        ReleaseCapture();
      }
      button_pressed = message;
      if (message == WM_XBUTTONUP) {
        button_pressed = GET_XBUTTON_WPARAM(wparam);
      }
      xPos = GET_X_LPARAM(lparam);
      yPos = GET_Y_LPARAM(lparam);
      OnPointerUp(static_cast<double>(xPos), static_cast<double>(yPos),
                  button_pressed);
      break;
    case WM_MOUSEWHEEL:
      OnScroll(0.0, -(static_cast<short>(HIWORD(wparam)) /
                      static_cast<double>(WHEEL_DELTA)));
      break;
    case WM_MOUSEHWHEEL:
      OnScroll((static_cast<short>(HIWORD(wparam)) /
                static_cast<double>(WHEEL_DELTA)),
               0.0);
      break;
    case WM_UNICHAR: {
      // Tell third-pary app, we can support Unicode.
      if (wparam == UNICODE_NOCHAR)
        return TRUE;
      // DefWindowProc will send WM_CHAR for this WM_UNICHAR.
      break;
    }
    case WM_DEADCHAR:
    case WM_SYSDEADCHAR:
    case WM_CHAR:
    case WM_SYSCHAR: {
      static wchar_t s_pending_high_surrogate = 0;

      wchar_t character = static_cast<wchar_t>(wparam);
      std::u16string text({character});
      char32_t code_point = character;
      if (IS_HIGH_SURROGATE(character)) {
        // Save to send later with the trailing surrogate.
        s_pending_high_surrogate = character;
      } else if (IS_LOW_SURROGATE(character) && s_pending_high_surrogate != 0) {
        text.insert(text.begin(), s_pending_high_surrogate);
        // Merge the surrogate pairs for the key event.
        code_point =
            CodePointFromSurrogatePair(s_pending_high_surrogate, character);
        s_pending_high_surrogate = 0;
      }

      // Of the messages handled here, only WM_CHAR should be treated as
      // characters. WM_SYS*CHAR are not part of text input, and WM_DEADCHAR
      // will be incorporated into a later WM_CHAR with the full character.
      // Also filter out:
      // - Lead surrogates, which like dead keys will be send once combined.
      // - ASCII control characters, which are sent as WM_CHAR events for all
      //   control key shortcuts.
      if (message == WM_CHAR && s_pending_high_surrogate == 0 &&
          character >= u' ') {
        OnText(text);
      }

      // All key presses that generate a character should be sent from
      // WM_CHAR. In order to send the full key press information, the keycode
      // is persisted in keycode_for_char_message_ obtained from WM_KEYDOWN.
      if (keycode_for_char_message_ != 0) {
        const unsigned int scancode = (lparam >> 16) & 0xff;
        OnKey(keycode_for_char_message_, scancode, WM_KEYDOWN, code_point);
        keycode_for_char_message_ = 0;
      }
      break;
    }
    case WM_KEYDOWN:
    case WM_SYSKEYDOWN:
    case WM_KEYUP:
    case WM_SYSKEYUP:
      const bool is_keydown_message =
          (message == WM_KEYDOWN || message == WM_SYSKEYDOWN);
      // Check if this key produces a character. If so, the key press should
      // be sent with the character produced at WM_CHAR. Store the produced
      // keycode (it's not accessible from WM_CHAR) to be used in WM_CHAR.
      const unsigned int character = MapVirtualKey(wparam, MAPVK_VK_TO_CHAR);
      if (character > 0 && is_keydown_message) {
        keycode_for_char_message_ = wparam;
        break;
      }
      unsigned int keyCode(wparam);
      const unsigned int scancode = (lparam >> 16) & 0xff;
      // If the key is a modifier, get its side.
      if (keyCode == VK_SHIFT || keyCode == VK_MENU || keyCode == VK_CONTROL) {
        keyCode = MapVirtualKey(scancode, MAPVK_VSC_TO_VK_EX);
      }
      const int action = is_keydown_message ? WM_KEYDOWN : WM_KEYUP;
      OnKey(keyCode, scancode, action, 0);
      break;
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

UINT Win32Window::GetCurrentDPI() {
  return current_dpi_;
}

UINT Win32Window::GetCurrentWidth() {
  return current_width_;
}

UINT Win32Window::GetCurrentHeight() {
  return current_height_;
}

HWND Win32Window::GetWindowHandle() {
  return window_handle_;
}

void Win32Window::Destroy() {
  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }

  UnregisterClass(window_class_name_.c_str(), nullptr);
}

void Win32Window::HandleResize(UINT width, UINT height) {
  current_width_ = width;
  current_height_ = height;
  OnResize(width, height);
}

Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

}  // namespace flutter
