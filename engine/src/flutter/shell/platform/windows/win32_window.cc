// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/win32_window.h"

#include "dpi_utils.h"

namespace flutter {

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
    return that->MessageHandler(window, message, wparam, lparam);
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
Win32Window::MessageHandler(HWND hwnd,
                            UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam) noexcept {
  int xPos = 0, yPos = 0;
  UINT width = 0, height = 0;
  auto window =
      reinterpret_cast<Win32Window*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
  UINT button_pressed = 0;
  if (window != nullptr) {
    switch (message) {
      case kWmDpiChangedBeforeParent:
        current_dpi_ = GetDpiForHWND(window_handle_);
        window->OnDpiScale(current_dpi_);
        return 0;
      case WM_SIZE:
        width = LOWORD(lparam);
        height = HIWORD(lparam);

        current_width_ = width;
        current_height_ = height;
        window->HandleResize(width, height);
        break;
      case WM_FONTCHANGE:
        window->OnFontChange();
        break;
      case WM_MOUSEMOVE:
        window->TrackMouseLeaveEvent(hwnd);

        xPos = GET_X_LPARAM(lparam);
        yPos = GET_Y_LPARAM(lparam);
        window->OnPointerMove(static_cast<double>(xPos),
                              static_cast<double>(yPos));
        break;
      case WM_MOUSELEAVE:;
        window->OnPointerLeave();
        // Once the tracked event is received, the TrackMouseEvent function
        // resets. Set to false to make sure it's called once mouse movement is
        // detected again.
        tracking_mouse_leave_ = false;
        break;
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
          SetCapture(hwnd);
        }
        button_pressed = message;
        if (message == WM_XBUTTONDOWN) {
          button_pressed = GET_XBUTTON_WPARAM(wparam);
        }
        xPos = GET_X_LPARAM(lparam);
        yPos = GET_Y_LPARAM(lparam);
        window->OnPointerDown(static_cast<double>(xPos),
                              static_cast<double>(yPos), button_pressed);
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
        window->OnPointerUp(static_cast<double>(xPos),
                            static_cast<double>(yPos), button_pressed);
        break;
      case WM_MOUSEWHEEL:
        window->OnScroll(
            0.0, -(static_cast<short>(HIWORD(wparam)) / (double)WHEEL_DELTA));
        break;
      case WM_UNICHAR: {
        // Tell third-pary app, we can support Unicode.
        if (wparam == UNICODE_NOCHAR)
          return TRUE;
        // DefWindowProc will send WM_CHAR for this WM_UNICHAR.
        break;
      }
      case WM_CHAR:
      case WM_SYSCHAR: {
        if (wparam == VK_BACK)
          break;
        char32_t code_point = static_cast<char32_t>(wparam);
        static char32_t lead_surrogate = 0;
        // If code_point is LeadSurrogate, save and return.
        if ((code_point & 0xFFFFFC00) == 0xD800) {
          lead_surrogate = code_point;
          return TRUE;
        }
        // Merge TrailSurrogate and LeadSurrogate.
        if (lead_surrogate != 0 && (code_point & 0xFFFFFC00) == 0xDC00) {
          code_point = 0x10000 + ((lead_surrogate & 0x000003FF) << 10) +
                       (code_point & 0x3FF);
        }
        lead_surrogate = 0;
        window->OnChar(code_point);
        break;
      }
      case WM_KEYDOWN:
      case WM_SYSKEYDOWN:
      case WM_KEYUP:
      case WM_SYSKEYUP:
        unsigned char scancode = ((unsigned char*)&lparam)[2];
        unsigned int virtualKey = MapVirtualKey(scancode, MAPVK_VSC_TO_VK);
        const int key = virtualKey;
        const int action = message == WM_KEYDOWN ? WM_KEYDOWN : WM_KEYUP;
        window->OnKey(key, scancode, action, 0);
        break;
    }
    return DefWindowProc(hwnd, message, wparam, lparam);
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
