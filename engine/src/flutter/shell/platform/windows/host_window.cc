// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window.h"

#include <dwmapi.h>

#include "flutter/shell/platform/windows/dpi_utils.h"
#include "flutter/shell/platform/windows/flutter_window.h"
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"
#include "flutter/shell/platform/windows/window_manager.h"

namespace {

constexpr wchar_t kWindowClassName[] = L"FLUTTER_HOST_WINDOW";

// Clamps |size| to the size of the virtual screen. Both the parameter and
// return size are in physical coordinates.
flutter::Size ClampToVirtualScreen(flutter::Size size) {
  double const virtual_screen_width = GetSystemMetrics(SM_CXVIRTUALSCREEN);
  double const virtual_screen_height = GetSystemMetrics(SM_CYVIRTUALSCREEN);

  return flutter::Size(std::clamp(size.width(), 0.0, virtual_screen_width),
                       std::clamp(size.height(), 0.0, virtual_screen_height));
}

void EnableTransparentWindowBackground(HWND hwnd,
                                       flutter::WindowsProcTable const& win32) {
  enum ACCENT_STATE { ACCENT_DISABLED = 0 };

  struct ACCENT_POLICY {
    ACCENT_STATE AccentState;
    DWORD AccentFlags;
    DWORD GradientColor;
    DWORD AnimationId;
  };

  // Set the accent policy to disable window composition.
  ACCENT_POLICY accent = {ACCENT_DISABLED, 2, static_cast<DWORD>(0), 0};
  flutter::WindowsProcTable::WINDOWCOMPOSITIONATTRIBDATA data = {
      .Attrib =
          flutter::WindowsProcTable::WINDOWCOMPOSITIONATTRIB::WCA_ACCENT_POLICY,
      .pvData = &accent,
      .cbData = sizeof(accent)};
  win32.SetWindowCompositionAttribute(hwnd, &data);

  // Extend the frame into the client area and set the window's system
  // backdrop type for visual effects.
  MARGINS const margins = {-1};
  win32.DwmExtendFrameIntoClientArea(hwnd, &margins);
  INT effect_value = 1;
  win32.DwmSetWindowAttribute(hwnd, DWMWA_SYSTEMBACKDROP_TYPE, &effect_value,
                              sizeof(BOOL));
}

// Retrieves the calling thread's last-error code message as a string,
// or a fallback message if the error message cannot be formatted.
std::string GetLastErrorAsString() {
  LPWSTR message_buffer = nullptr;

  if (DWORD const size = FormatMessage(
          FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
              FORMAT_MESSAGE_IGNORE_INSERTS,
          nullptr, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
          reinterpret_cast<LPTSTR>(&message_buffer), 0, nullptr)) {
    std::wstring const wide_message(message_buffer, size);
    LocalFree(message_buffer);
    message_buffer = nullptr;

    if (int const buffer_size =
            WideCharToMultiByte(CP_UTF8, 0, wide_message.c_str(), -1, nullptr,
                                0, nullptr, nullptr)) {
      std::string message(buffer_size, 0);
      WideCharToMultiByte(CP_UTF8, 0, wide_message.c_str(), -1, &message[0],
                          buffer_size, nullptr, nullptr);
      return message;
    }
  }

  if (message_buffer) {
    LocalFree(message_buffer);
  }
  std::ostringstream oss;
  oss << "Format message failed with 0x" << std::hex << std::setfill('0')
      << std::setw(8) << GetLastError();
  return oss.str();
}

// Calculates the required window size, in physical coordinates, to
// accommodate the given |client_size|, in logical coordinates, constrained by
// optional |smallest| and |biggest|, for a window with the specified
// |window_style| and |extended_window_style|. If |owner_hwnd| is not null, the
// DPI of the display with the largest area of intersection with |owner_hwnd| is
// used for the calculation; otherwise, the primary display's DPI is used. The
// resulting size includes window borders, non-client areas, and drop shadows.
// On error, returns std::nullopt and logs an error message.
std::optional<flutter::Size> GetWindowSizeForClientSize(
    flutter::WindowsProcTable const& win32,
    flutter::Size const& client_size,
    std::optional<flutter::Size> smallest,
    std::optional<flutter::Size> biggest,
    DWORD window_style,
    DWORD extended_window_style,
    HWND owner_hwnd) {
  UINT const dpi = flutter::GetDpiForHWND(owner_hwnd);
  double const scale_factor =
      static_cast<double>(dpi) / USER_DEFAULT_SCREEN_DPI;
  RECT rect = {
      .right = static_cast<LONG>(client_size.width() * scale_factor),
      .bottom = static_cast<LONG>(client_size.height() * scale_factor)};

  if (!win32.AdjustWindowRectExForDpi(&rect, window_style, FALSE,
                                      extended_window_style, dpi)) {
    FML_LOG(ERROR) << "Failed to run AdjustWindowRectExForDpi: "
                   << GetLastErrorAsString();
    return std::nullopt;
  }

  double width = static_cast<double>(rect.right - rect.left);
  double height = static_cast<double>(rect.bottom - rect.top);

  // Apply size constraints
  double const non_client_width = width - (client_size.width() * scale_factor);
  double const non_client_height =
      height - (client_size.height() * scale_factor);
  if (smallest) {
    flutter::Size min_physical_size = ClampToVirtualScreen(
        flutter::Size(smallest->width() * scale_factor + non_client_width,
                      smallest->height() * scale_factor + non_client_height));
    width = std::max(width, min_physical_size.width());
    height = std::max(height, min_physical_size.height());
  }
  if (biggest) {
    flutter::Size max_physical_size = ClampToVirtualScreen(
        flutter::Size(biggest->width() * scale_factor + non_client_width,
                      biggest->height() * scale_factor + non_client_height));
    width = std::min(width, max_physical_size.width());
    height = std::min(height, max_physical_size.height());
  }

  return flutter::Size{width, height};
}

// Checks whether the window class of name |class_name| is registered for the
// current application.
bool IsClassRegistered(LPCWSTR class_name) {
  WNDCLASSEX window_class = {};
  return GetClassInfoEx(GetModuleHandle(nullptr), class_name, &window_class) !=
         0;
}

// Window attribute that enables dark mode window decorations.
//
// Redefined in case the developer's machine has a Windows SDK older than
// version 10.0.22000.0.
// See:
// https://docs.microsoft.com/windows/win32/api/dwmapi/ne-dwmapi-dwmwindowattribute
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

// Updates the window frame's theme to match the system theme.
void UpdateTheme(HWND window) {
  // Registry key for app theme preference.
  const wchar_t kGetPreferredBrightnessRegKey[] =
      L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
  const wchar_t kGetPreferredBrightnessRegValue[] = L"AppsUseLightTheme";

  // A value of 0 indicates apps should use dark mode. A non-zero or missing
  // value indicates apps should use light mode.
  DWORD light_mode;
  DWORD light_mode_size = sizeof(light_mode);
  LSTATUS const result =
      RegGetValue(HKEY_CURRENT_USER, kGetPreferredBrightnessRegKey,
                  kGetPreferredBrightnessRegValue, RRF_RT_REG_DWORD, nullptr,
                  &light_mode, &light_mode_size);

  if (result == ERROR_SUCCESS) {
    BOOL enable_dark_mode = light_mode == 0;
    DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE,
                          &enable_dark_mode, sizeof(enable_dark_mode));
  }
}

// Inserts |content| into the window tree.
void SetChildContent(HWND content, HWND window) {
  SetParent(content, window);
  RECT client_rect;
  GetClientRect(window, &client_rect);
  MoveWindow(content, client_rect.left, client_rect.top,
             client_rect.right - client_rect.left,
             client_rect.bottom - client_rect.top, true);
}

}  // namespace

namespace flutter {

std::unique_ptr<HostWindow> HostWindow::CreateRegularWindow(
    WindowManager* window_manager,
    FlutterWindowsEngine* engine,
    const WindowSizing& content_size) {
  DWORD window_style = WS_OVERLAPPEDWINDOW;
  DWORD extended_window_style = 0;
  std::optional<Size> smallest = std::nullopt;
  std::optional<Size> biggest = std::nullopt;

  if (content_size.has_view_constraints) {
    smallest = Size(content_size.view_min_width, content_size.view_min_height);
    if (content_size.view_max_width > 0 && content_size.view_max_height > 0) {
      biggest = Size(content_size.view_max_width, content_size.view_max_height);
    }
  }

  // TODO(knopp): What about windows sized to content?
  FML_CHECK(content_size.has_preferred_view_size);

  // Calculate the screen space window rectangle for the new window.
  // Default positioning values (CW_USEDEFAULT) are used
  // if the window has no owner.
  Rect const initial_window_rect = [&]() -> Rect {
    std::optional<Size> const window_size = GetWindowSizeForClientSize(
        *engine->windows_proc_table(),
        Size(content_size.preferred_view_width,
             content_size.preferred_view_height),
        smallest, biggest, window_style, extended_window_style, nullptr);
    return {{CW_USEDEFAULT, CW_USEDEFAULT},
            window_size ? *window_size : Size{CW_USEDEFAULT, CW_USEDEFAULT}};
  }();

  // Set up the view.
  auto view_window = std::make_unique<FlutterWindow>(
      initial_window_rect.width(), initial_window_rect.height(),
      engine->windows_proc_table());

  std::unique_ptr<FlutterWindowsView> view =
      engine->CreateView(std::move(view_window));
  if (view == nullptr) {
    FML_LOG(ERROR) << "Failed to create view";
    return nullptr;
  }

  std::unique_ptr<FlutterWindowsViewController> view_controller =
      std::make_unique<FlutterWindowsViewController>(nullptr, std::move(view));
  FML_CHECK(engine->running());
  // The Windows embedder listens to accessibility updates using the
  // view's HWND. The embedder's accessibility features may be stale if
  // the app was in headless mode.
  engine->UpdateAccessibilityFeatures();

  // Register the window class.
  if (!IsClassRegistered(kWindowClassName)) {
    auto const idi_app_icon = 101;
    WNDCLASSEX window_class = {};
    window_class.cbSize = sizeof(WNDCLASSEX);
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.lpfnWndProc = HostWindow::WndProc;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(idi_app_icon));
    if (!window_class.hIcon) {
      window_class.hIcon = LoadIcon(nullptr, IDI_APPLICATION);
    }
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kWindowClassName;

    if (!RegisterClassEx(&window_class)) {
      FML_LOG(ERROR) << "Cannot register window class " << kWindowClassName
                     << ": " << GetLastErrorAsString();
      return nullptr;
    }
  }

  // Create the native window.
  HWND hwnd = CreateWindowEx(
      extended_window_style, kWindowClassName, L"", window_style,
      initial_window_rect.left(), initial_window_rect.top(),
      initial_window_rect.width(), initial_window_rect.height(), nullptr,
      nullptr, GetModuleHandle(nullptr), engine->windows_proc_table().get());
  if (!hwnd) {
    FML_LOG(ERROR) << "Cannot create window: " << GetLastErrorAsString();
    return nullptr;
  }

  // Adjust the window position so its origin aligns with the top-left corner
  // of the window frame, not the window rectangle (which includes the
  // drop-shadow). This adjustment must be done post-creation since the frame
  // rectangle is only available after the window has been created.
  RECT frame_rect;
  DwmGetWindowAttribute(hwnd, DWMWA_EXTENDED_FRAME_BOUNDS, &frame_rect,
                        sizeof(frame_rect));
  RECT window_rect;
  GetWindowRect(hwnd, &window_rect);
  LONG const left_dropshadow_width = frame_rect.left - window_rect.left;
  LONG const top_dropshadow_height = window_rect.top - frame_rect.top;
  SetWindowPos(hwnd, nullptr, window_rect.left - left_dropshadow_width,
               window_rect.top - top_dropshadow_height, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);

  UpdateTheme(hwnd);

  SetChildContent(view_controller->view()->GetWindowHandle(), hwnd);

  // TODO(loicsharma): Hide the window until the first frame is rendered.
  // Single window apps use the engine's next frame callback to show the
  // window. This doesn't work for multi window apps as the engine cannot have
  // multiple next frame callbacks. If multiple windows are created, only the
  // last one will be shown.
  ShowWindow(hwnd, SW_SHOWNORMAL);
  return std::unique_ptr<HostWindow>(new HostWindow(
      window_manager, engine, WindowArchetype::kRegular,
      std::move(view_controller), BoxConstraints(smallest, biggest), hwnd));
}

HostWindow::HostWindow(
    WindowManager* window_manager,
    FlutterWindowsEngine* engine,
    WindowArchetype archetype,
    std::unique_ptr<FlutterWindowsViewController> view_controller,
    const BoxConstraints& box_constraints,
    HWND hwnd)
    : window_manager_(window_manager),
      engine_(engine),
      archetype_(archetype),
      view_controller_(std::move(view_controller)),
      window_handle_(hwnd),
      box_constraints_(box_constraints) {
  SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
}

HostWindow::~HostWindow() {
  if (view_controller_) {
    // Unregister the window class. Fail silently if other windows are still
    // using the class, as only the last window can successfully unregister it.
    if (!UnregisterClass(kWindowClassName, GetModuleHandle(nullptr))) {
      // Clear the error state after the failed unregistration.
      SetLastError(ERROR_SUCCESS);
    }
  }
}

HostWindow* HostWindow::GetThisFromHandle(HWND hwnd) {
  return reinterpret_cast<HostWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
}

HWND HostWindow::GetWindowHandle() const {
  return window_handle_;
}

void HostWindow::FocusViewOf(HostWindow* window) {
  auto child_content = window->view_controller_->view()->GetWindowHandle();
  if (window != nullptr && child_content != nullptr) {
    SetFocus(child_content);
  }
};

LRESULT HostWindow::WndProc(HWND hwnd,
                            UINT message,
                            WPARAM wparam,
                            LPARAM lparam) {
  if (message == WM_NCCREATE) {
    auto* const create_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    auto* const windows_proc_table =
        static_cast<WindowsProcTable*>(create_struct->lpCreateParams);
    windows_proc_table->EnableNonClientDpiScaling(hwnd);
    EnableTransparentWindowBackground(hwnd, *windows_proc_table);
  } else if (HostWindow* const window = GetThisFromHandle(hwnd)) {
    return window->HandleMessage(hwnd, message, wparam, lparam);
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

LRESULT HostWindow::HandleMessage(HWND hwnd,
                                  UINT message,
                                  WPARAM wparam,
                                  LPARAM lparam) {
  auto result = engine_->window_proc_delegate_manager()->OnTopLevelWindowProc(
      window_handle_, message, wparam, lparam);
  if (result) {
    return *result;
  }

  switch (message) {
    case WM_DPICHANGED: {
      auto* const new_scaled_window_rect = reinterpret_cast<RECT*>(lparam);
      LONG const width =
          new_scaled_window_rect->right - new_scaled_window_rect->left;
      LONG const height =
          new_scaled_window_rect->bottom - new_scaled_window_rect->top;
      SetWindowPos(hwnd, nullptr, new_scaled_window_rect->left,
                   new_scaled_window_rect->top, width, height,
                   SWP_NOZORDER | SWP_NOACTIVATE);
      return 0;
    }

    case WM_GETMINMAXINFO: {
      RECT window_rect;
      GetWindowRect(hwnd, &window_rect);
      RECT client_rect;
      GetClientRect(hwnd, &client_rect);
      LONG const non_client_width = (window_rect.right - window_rect.left) -
                                    (client_rect.right - client_rect.left);
      LONG const non_client_height = (window_rect.bottom - window_rect.top) -
                                     (client_rect.bottom - client_rect.top);

      UINT const dpi = flutter::GetDpiForHWND(hwnd);
      double const scale_factor =
          static_cast<double>(dpi) / USER_DEFAULT_SCREEN_DPI;

      MINMAXINFO* info = reinterpret_cast<MINMAXINFO*>(lparam);
      Size const min_physical_size = ClampToVirtualScreen(Size(
          box_constraints_.smallest().width() * scale_factor + non_client_width,
          box_constraints_.smallest().height() * scale_factor +
              non_client_height));

      info->ptMinTrackSize.x = min_physical_size.width();
      info->ptMinTrackSize.y = min_physical_size.height();
      Size const max_physical_size = ClampToVirtualScreen(Size(
          box_constraints_.biggest().width() * scale_factor + non_client_width,
          box_constraints_.biggest().height() * scale_factor +
              non_client_height));

      info->ptMaxTrackSize.x = max_physical_size.width();
      info->ptMaxTrackSize.y = max_physical_size.height();
      return 0;
    }

    case WM_SIZE: {
      auto child_content = view_controller_->view()->GetWindowHandle();
      if (child_content != nullptr) {
        // Resize and reposition the child content window.
        RECT client_rect;
        GetClientRect(hwnd, &client_rect);
        MoveWindow(child_content, client_rect.left, client_rect.top,
                   client_rect.right - client_rect.left,
                   client_rect.bottom - client_rect.top, TRUE);
      }
      return 0;
    }

    case WM_ACTIVATE:
      FocusViewOf(this);
      return 0;

    case WM_MOUSEACTIVATE:
      FocusViewOf(this);
      return MA_ACTIVATE;

    case WM_DWMCOLORIZATIONCOLORCHANGED:
      UpdateTheme(hwnd);
      return 0;

    default:
      break;
  }

  if (!view_controller_) {
    return 0;
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

void HostWindow::SetContentSize(const WindowSizing& size) {
  WINDOWINFO window_info = {.cbSize = sizeof(WINDOWINFO)};
  GetWindowInfo(window_handle_, &window_info);

  std::optional<Size> smallest, biggest;
  if (size.has_view_constraints) {
    smallest = Size(size.view_min_width, size.view_min_height);
    if (size.view_max_width > 0 && size.view_max_height > 0) {
      biggest = Size(size.view_max_width, size.view_max_height);
    }
  }

  box_constraints_ = BoxConstraints(smallest, biggest);

  if (size.has_preferred_view_size) {
    std::optional<Size> const window_size = GetWindowSizeForClientSize(
        *engine_->windows_proc_table(),
        Size(size.preferred_view_width, size.preferred_view_height),
        box_constraints_.smallest(), box_constraints_.biggest(),
        window_info.dwStyle, window_info.dwExStyle, nullptr);

    if (window_size) {
      SetWindowPos(window_handle_, NULL, 0, 0, window_size->width(),
                   window_size->height(),
                   SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
    }
  }
}

}  // namespace flutter
