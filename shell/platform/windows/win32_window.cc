// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/win32_window.h"

namespace flutter {

Win32Window::Win32Window() {
  // Assume Windows 10 1703 or greater for DPI handling.  When running on a
  // older release of Windows where this context doesn't exist, DPI calls will
  // fail and Flutter rendering will be impacted until this is fixed.
  // To handle downlevel correctly, dpi_helper must use the most recent DPI
  // context available should be used: Windows 1703: Per-Monitor V2, 8.1:
  // Per-Monitor V1, Windows 7: System See
  // https://docs.microsoft.com/en-us/windows/win32/hidpi/high-dpi-desktop-application-development-on-windows
  // for more information.
}
Win32Window::~Win32Window() {
  Destroy();
}

void Win32Window::InitializeChild(const char* title,
                                  unsigned int width,
                                  unsigned int height) {
  Destroy();
  std::wstring converted_title = NarrowToWide(title);

  WNDCLASS window_class = ResgisterWindowClass(converted_title);

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

WNDCLASS Win32Window::ResgisterWindowClass(std::wstring& title) {
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

    // Since the application is running in Per-monitor V2 mode, turn on
    // automatic titlebar scaling
    BOOL result = that->dpi_helper_->EnableNonClientDpiScaling(window);
    if (result != TRUE) {
      OutputDebugString(L"Failed to enable non-client area autoscaling");
    }
    that->current_dpi_ = that->dpi_helper_->GetDpiForWindow(window);
    that->window_handle_ = window;
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
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

  if (window != nullptr) {
    switch (message) {
      case WM_DPICHANGED:
        return HandleDpiChange(window_handle_, wparam, lparam, true);
        break;
      case kWmDpiChangedBeforeParent:
        return HandleDpiChange(window_handle_, wparam, lparam, false);
        break;
      case WM_DESTROY:
        window->OnClose();
        return 0;
        break;

      case WM_SIZE:
        width = LOWORD(lparam);
        height = HIWORD(lparam);

        current_width_ = width;
        current_height_ = height;
        window->HandleResize(width, height);
        break;

      case WM_MOUSEMOVE:
        xPos = GET_X_LPARAM(lparam);
        yPos = GET_Y_LPARAM(lparam);

        window->OnPointerMove(static_cast<double>(xPos),
                              static_cast<double>(yPos));
        break;
      case WM_LBUTTONDOWN:
        xPos = GET_X_LPARAM(lparam);
        yPos = GET_Y_LPARAM(lparam);
        window->OnPointerDown(static_cast<double>(xPos),
                              static_cast<double>(yPos));
        break;
      case WM_LBUTTONUP:
        xPos = GET_X_LPARAM(lparam);
        yPos = GET_Y_LPARAM(lparam);
        window->OnPointerUp(static_cast<double>(xPos),
                            static_cast<double>(yPos));
        break;
      case WM_MOUSEWHEEL:
        window->OnScroll(
            0.0, -(static_cast<short>(HIWORD(wparam)) / (double)WHEEL_DELTA));
        break;
      case WM_CHAR:
      case WM_SYSCHAR:
      case WM_UNICHAR:
        if (wparam != VK_BACK) {
          window->OnChar(static_cast<unsigned int>(wparam));
        }
        break;
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

// DPI Change handler. on WM_DPICHANGE resize the window
LRESULT
Win32Window::HandleDpiChange(HWND hwnd,
                             WPARAM wparam,
                             LPARAM lparam,
                             bool toplevel) {
  if (hwnd != nullptr) {
    auto window =
        reinterpret_cast<Win32Window*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));

    UINT uDpi = HIWORD(wparam);

    // The DPI is only passed for DPI change messages on top level windows,
    // hence call function to get DPI if needed.
    if (uDpi == 0) {
      uDpi = dpi_helper_->GetDpiForWindow(hwnd);
    }
    current_dpi_ = uDpi;
    window->OnDpiScale(uDpi);

    if (toplevel) {
      // Resize the window only for toplevel windows which have a suggested
      // size.
      auto lprcNewScale = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = lprcNewScale->right - lprcNewScale->left;
      LONG newHeight = lprcNewScale->bottom - lprcNewScale->top;

      SetWindowPos(hwnd, nullptr, lprcNewScale->left, lprcNewScale->top,
                   newWidth, newHeight, SWP_NOZORDER | SWP_NOACTIVATE);
    }
  }
  return 0;
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
