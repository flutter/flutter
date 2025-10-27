// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/host_window.h"
#include "flutter/shell/platform/windows/host_window_dialog.h"
#include "flutter/shell/platform/windows/host_window_regular.h"

#include <dwmapi.h>

#include "flutter/shell/platform/windows/display_manager.h"
#include "flutter/shell/platform/windows/dpi_utils.h"
#include "flutter/shell/platform/windows/flutter_window.h"
#include "flutter/shell/platform/windows/flutter_windows_view_controller.h"
#include "flutter/shell/platform/windows/rect_helper.h"
#include "flutter/shell/platform/windows/wchar_util.h"
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

// Adjusts a 1D segment (defined by origin and size) to fit entirely within
// a destination segment. If the segment is larger than the destination, it is
// first shrunk to fit. Then, it's shifted to be within the bounds.
//
// Let the destination be "{...}" and the segment to adjust be "[...]".
//
// Case 1: The segment sticks out to the right.
//
//   Before:      {------[----}------]
//   After:       {------[----]}
//
// Case 2: The segment sticks out to the left.
//
//   Before: [------{----]------}
//   After:        {[----]------}
void AdjustAlongAxis(LONG dst_origin, LONG dst_size, LONG* origin, LONG* size) {
  *size = std::min(dst_size, *size);
  if (*origin < dst_origin)
    *origin = dst_origin;
  else
    *origin = std::min(dst_origin + dst_size, *origin + *size) - *size;
}

RECT AdjustToFit(const RECT& parent, const RECT& child) {
  auto new_x = child.left;
  auto new_y = child.top;
  auto new_width = flutter::RectWidth(child);
  auto new_height = flutter::RectHeight(child);
  AdjustAlongAxis(parent.left, flutter::RectWidth(parent), &new_x, &new_width);
  AdjustAlongAxis(parent.top, flutter::RectHeight(parent), &new_y, &new_height);
  RECT result;
  result.left = new_x;
  result.right = new_x + new_width;
  result.top = new_y;
  result.bottom = new_y + new_height;
  return result;
}

flutter::BoxConstraints FromWindowConstraints(
    const flutter::WindowConstraints& preferred_constraints) {
  std::optional<flutter::Size> smallest, biggest;
  if (preferred_constraints.has_view_constraints) {
    smallest = flutter::Size(preferred_constraints.view_min_width,
                             preferred_constraints.view_min_height);
    if (preferred_constraints.view_max_width > 0 &&
        preferred_constraints.view_max_height > 0) {
      biggest = flutter::Size(preferred_constraints.view_max_width,
                              preferred_constraints.view_max_height);
    }
  }

  return flutter::BoxConstraints(smallest, biggest);
}

}  // namespace

namespace flutter {

std::unique_ptr<HostWindow> HostWindow::CreateRegularWindow(
    WindowManager* window_manager,
    FlutterWindowsEngine* engine,
    const WindowSizeRequest& preferred_size,
    const WindowConstraints& preferred_constraints,
    LPCWSTR title) {
  return std::unique_ptr<HostWindow>(new HostWindowRegular(
      window_manager, engine, preferred_size,
      FromWindowConstraints(preferred_constraints), title));
}

std::unique_ptr<HostWindow> HostWindow::CreateDialogWindow(
    WindowManager* window_manager,
    FlutterWindowsEngine* engine,
    const WindowSizeRequest& preferred_size,
    const WindowConstraints& preferred_constraints,
    LPCWSTR title,
    HWND parent) {
  return std::unique_ptr<HostWindow>(
      new HostWindowDialog(window_manager, engine, preferred_size,
                           FromWindowConstraints(preferred_constraints), title,
                           parent ? parent : std::optional<HWND>()));
}

HostWindow::HostWindow(WindowManager* window_manager,
                       FlutterWindowsEngine* engine,
                       WindowArchetype archetype,
                       DWORD window_style,
                       DWORD extended_window_style,
                       const BoxConstraints& box_constraints,
                       Rect const initial_window_rect,
                       LPCWSTR title,
                       std::optional<HWND> const& owner_window)
    : window_manager_(window_manager),
      engine_(engine),
      archetype_(archetype),
      box_constraints_(box_constraints) {
  // Set up the view.
  auto view_window = std::make_unique<FlutterWindow>(
      initial_window_rect.width(), initial_window_rect.height(),
      engine->display_manager(), engine->windows_proc_table());

  std::unique_ptr<FlutterWindowsView> view =
      engine->CreateView(std::move(view_window));
  FML_CHECK(view != nullptr);

  view_controller_ =
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

    FML_CHECK(RegisterClassEx(&window_class));
  }

  // Create the native window.
  window_handle_ = CreateWindowEx(
      extended_window_style, kWindowClassName, title, window_style,
      initial_window_rect.left(), initial_window_rect.top(),
      initial_window_rect.width(), initial_window_rect.height(),
      owner_window ? *owner_window : nullptr, nullptr, GetModuleHandle(nullptr),
      engine->windows_proc_table().get());
  FML_CHECK(window_handle_ != nullptr);

  // Adjust the window position so its origin aligns with the top-left corner
  // of the window frame, not the window rectangle (which includes the
  // drop-shadow). This adjustment must be done post-creation since the frame
  // rectangle is only available after the window has been created.
  RECT frame_rect;
  DwmGetWindowAttribute(window_handle_, DWMWA_EXTENDED_FRAME_BOUNDS,
                        &frame_rect, sizeof(frame_rect));
  RECT window_rect;
  GetWindowRect(window_handle_, &window_rect);
  LONG const left_dropshadow_width = frame_rect.left - window_rect.left;
  LONG const top_dropshadow_height = window_rect.top - frame_rect.top;
  SetWindowPos(window_handle_, nullptr,
               window_rect.left - left_dropshadow_width,
               window_rect.top - top_dropshadow_height, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);

  UpdateTheme(window_handle_);

  SetChildContent(view_controller_->view()->GetWindowHandle(), window_handle_);

  // TODO(loicsharma): Hide the window until the first frame is rendered.
  // Single window apps use the engine's next frame callback to show the
  // window. This doesn't work for multi window apps as the engine cannot have
  // multiple next frame callbacks. If multiple windows are created, only the
  // last one will be shown.
  ShowWindow(window_handle_, SW_SHOWNORMAL);
  SetWindowLongPtr(window_handle_, GWLP_USERDATA,
                   reinterpret_cast<LONG_PTR>(this));
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
  wchar_t class_name[256];
  if (!GetClassName(hwnd, class_name, sizeof(class_name) / sizeof(wchar_t))) {
    FML_LOG(ERROR) << "Failed to get class name for window handle " << hwnd
                   << ": " << GetLastErrorAsString();
    return nullptr;
  }
  // Ignore window handles that do not match the expected class name.
  if (wcscmp(class_name, kWindowClassName) != 0) {
    return nullptr;
  }

  return reinterpret_cast<HostWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
}

HWND HostWindow::GetWindowHandle() const {
  return window_handle_;
}

void HostWindow::FocusRootViewOf(HostWindow* window) {
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
    case WM_DESTROY:
      is_being_destroyed_ = true;
      break;

    case WM_NCLBUTTONDOWN: {
      // Fix for 500ms hang after user clicks on the title bar, but before
      // moving mouse. Reference:
      // https://gamedev.net/forums/topic/672094-keeping-things-moving-during-win32-moveresize-events/5254386/
      if (SendMessage(window_handle_, WM_NCHITTEST, wparam, lparam) ==
          HTCAPTION) {
        POINT cursorPos;
        // Get the current cursor position and synthesize WM_MOUSEMOVE to
        // unblock default window proc implementation for WM_NCLBUTTONDOWN at
        // HTCAPTION.
        GetCursorPos(&cursorPos);
        ScreenToClient(window_handle_, &cursorPos);
        PostMessage(window_handle_, WM_MOUSEMOVE, 0,
                    MAKELPARAM(cursorPos.x, cursorPos.y));
      }
      break;
    }

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
      FocusRootViewOf(this);
      return 0;

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

void HostWindow::SetContentSize(const WindowSizeRequest& size) {
  if (!size.has_preferred_view_size) {
    return;
  }

  if (GetFullscreen()) {
    std::optional<Size> const window_size = GetWindowSizeForClientSize(
        *engine_->windows_proc_table(),
        Size(size.preferred_view_width, size.preferred_view_height),
        box_constraints_.smallest(), box_constraints_.biggest(),
        saved_window_info_.style, saved_window_info_.ex_style, nullptr);
    if (!window_size) {
      return;
    }

    saved_window_info_.client_size =
        ActualWindowSize{.width = size.preferred_view_width,
                         .height = size.preferred_view_height};
    saved_window_info_.rect.right =
        saved_window_info_.rect.left + static_cast<LONG>(window_size->width());
    saved_window_info_.rect.bottom =
        saved_window_info_.rect.top + static_cast<LONG>(window_size->height());
  } else {
    WINDOWINFO window_info = {.cbSize = sizeof(WINDOWINFO)};
    GetWindowInfo(window_handle_, &window_info);

    std::optional<Size> const window_size = GetWindowSizeForClientSize(
        *engine_->windows_proc_table(),
        Size(size.preferred_view_width, size.preferred_view_height),
        box_constraints_.smallest(), box_constraints_.biggest(),
        window_info.dwStyle, window_info.dwExStyle, nullptr);

    if (!window_size) {
      return;
    }

    SetWindowPos(window_handle_, NULL, 0, 0, window_size->width(),
                 window_size->height(),
                 SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
  }
}

void HostWindow::SetConstraints(const WindowConstraints& constraints) {
  box_constraints_ = FromWindowConstraints(constraints);

  if (GetFullscreen()) {
    std::optional<Size> const window_size = GetWindowSizeForClientSize(
        *engine_->windows_proc_table(),
        Size(saved_window_info_.client_size.width,
             saved_window_info_.client_size.height),
        box_constraints_.smallest(), box_constraints_.biggest(),
        saved_window_info_.style, saved_window_info_.ex_style, nullptr);
    if (!window_size) {
      return;
    }

    saved_window_info_.rect.right =
        saved_window_info_.rect.left + static_cast<LONG>(window_size->width());
    saved_window_info_.rect.bottom =
        saved_window_info_.rect.top + static_cast<LONG>(window_size->height());
  } else {
    auto const client_size = GetWindowContentSize(window_handle_);
    auto const current_size = Size(client_size.width, client_size.height);
    WINDOWINFO window_info = {.cbSize = sizeof(WINDOWINFO)};
    GetWindowInfo(window_handle_, &window_info);
    std::optional<Size> const window_size = GetWindowSizeForClientSize(
        *engine_->windows_proc_table(), current_size,
        box_constraints_.smallest(), box_constraints_.biggest(),
        window_info.dwStyle, window_info.dwExStyle, nullptr);

    if (window_size && current_size != window_size) {
      SetWindowPos(window_handle_, NULL, 0, 0, window_size->width(),
                   window_size->height(),
                   SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
    }
  }
}

// The fullscreen method is largely adapted from the method found in chromium:
// See:
//
// * https://chromium.googlesource.com/chromium/src/+/refs/heads/main/ui/views/win/fullscreen_handler.h
// * https://chromium.googlesource.com/chromium/src/+/refs/heads/main/ui/views/win/fullscreen_handler.cc
void HostWindow::SetFullscreen(
    bool fullscreen,
    std::optional<FlutterEngineDisplayId> display_id) {
  if (fullscreen == GetFullscreen()) {
    return;
  }

  if (fullscreen) {
    WINDOWINFO window_info = {.cbSize = sizeof(WINDOWINFO)};
    GetWindowInfo(window_handle_, &window_info);
    saved_window_info_.style = window_info.dwStyle;
    saved_window_info_.ex_style = window_info.dwExStyle;
    // Store the original window rect, DPI, and monitor info to detect changes
    // and more accurately restore window placements when exiting fullscreen.
    ::GetWindowRect(window_handle_, &saved_window_info_.rect);
    saved_window_info_.client_size = GetWindowContentSize(window_handle_);
    saved_window_info_.dpi = GetDpiForHWND(window_handle_);
    saved_window_info_.monitor =
        MonitorFromWindow(window_handle_, MONITOR_DEFAULTTONEAREST);
    saved_window_info_.monitor_info.cbSize =
        sizeof(saved_window_info_.monitor_info);
    GetMonitorInfo(saved_window_info_.monitor,
                   &saved_window_info_.monitor_info);
  }

  if (fullscreen) {
    // Next, get the raw HMONITOR that we want to be fullscreened on
    HMONITOR monitor =
        MonitorFromWindow(window_handle_, MONITOR_DEFAULTTONEAREST);
    if (display_id) {
      if (auto const display =
              engine_->display_manager()->FindById(display_id.value())) {
        monitor = reinterpret_cast<HMONITOR>(display->display_id);
      }
    }

    MONITORINFO monitor_info;
    monitor_info.cbSize = sizeof(monitor_info);
    if (!GetMonitorInfo(monitor, &monitor_info)) {
      FML_LOG(ERROR) << "Cannot set window fullscreen because the monitor info "
                        "was not found";
    }

    auto const width = RectWidth(monitor_info.rcMonitor);
    auto const height = RectHeight(monitor_info.rcMonitor);
    WINDOWINFO window_info = {.cbSize = sizeof(WINDOWINFO)};
    GetWindowInfo(window_handle_, &window_info);

    // Set new window style and size.
    SetWindowLong(window_handle_, GWL_STYLE,
                  saved_window_info_.style & ~(WS_CAPTION | WS_THICKFRAME));
    SetWindowLong(
        window_handle_, GWL_EXSTYLE,
        saved_window_info_.ex_style & ~(WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE |
                                        WS_EX_CLIENTEDGE | WS_EX_STATICEDGE));

    // We call SetWindowPos first to set the window flags immediately. This
    // makes it so that the WM_GETMINMAXINFO gets called with the correct window
    // and content sizes.
    SetWindowPos(window_handle_, NULL, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);

    SetWindowPos(window_handle_, nullptr, monitor_info.rcMonitor.left,
                 monitor_info.rcMonitor.top, width, height,
                 SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
  } else {
    // Restore the window style and bounds saved prior to entering fullscreen.
    // Use WS_VISIBLE for windows shown after SetFullscreen: crbug.com/1062251.
    // Making multiple window adjustments here is ugly, but if SetWindowPos()
    // doesn't redraw, the taskbar won't be repainted.
    SetWindowLong(window_handle_, GWL_STYLE,
                  saved_window_info_.style | WS_VISIBLE);
    SetWindowLong(window_handle_, GWL_EXSTYLE, saved_window_info_.ex_style);

    // We call SetWindowPos first to set the window flags immediately. This
    // makes it so that the WM_GETMINMAXINFO gets called with the correct window
    // and content sizes.
    SetWindowPos(window_handle_, NULL, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);

    HMONITOR monitor =
        MonitorFromRect(&saved_window_info_.rect, MONITOR_DEFAULTTONEAREST);
    MONITORINFO monitor_info;
    monitor_info.cbSize = sizeof(monitor_info);
    GetMonitorInfo(monitor, &monitor_info);

    auto window_rect = saved_window_info_.rect;

    // Adjust the window bounds to restore, if displays were disconnected,
    // virtually rearranged, or otherwise changed metrics during fullscreen.
    if (monitor != saved_window_info_.monitor ||
        !AreRectsEqual(saved_window_info_.monitor_info.rcWork,
                       monitor_info.rcWork)) {
      window_rect = AdjustToFit(monitor_info.rcWork, window_rect);
    }

    auto const fullscreen_dpi = GetDpiForHWND(window_handle_);
    SetWindowPos(window_handle_, nullptr, window_rect.left, window_rect.top,
                 RectWidth(window_rect), RectHeight(window_rect),
                 SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    auto const final_dpi = GetDpiForHWND(window_handle_);
    if (final_dpi != saved_window_info_.dpi || final_dpi != fullscreen_dpi) {
      // Reissue SetWindowPos if the DPI changed from saved or fullscreen DPIs.
      // The first call may misinterpret bounds spanning displays, if the
      // fullscreen display's DPI does not match the target display's DPI.
      //
      // Scale and clamp the bounds if the final DPI changed from the saved DPI.
      // This more accurately matches the original placement, while avoiding
      // unexpected offscreen placement in a recongifured multi-screen space.
      if (final_dpi != saved_window_info_.dpi) {
        auto const scale =
            final_dpi / static_cast<float>(saved_window_info_.dpi);
        auto const width = static_cast<LONG>(scale * RectWidth(window_rect));
        auto const height = static_cast<LONG>(scale * RectHeight(window_rect));
        window_rect.right = window_rect.left + width;
        window_rect.bottom = window_rect.top + height;
        window_rect = AdjustToFit(monitor_info.rcWork, window_rect);
      }

      SetWindowPos(window_handle_, nullptr, window_rect.left, window_rect.top,
                   RectWidth(window_rect), RectHeight(window_rect),
                   SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    }
  }

  if (!task_bar_list_) {
    HRESULT hr =
        ::CoCreateInstance(CLSID_TaskbarList, nullptr, CLSCTX_INPROC_SERVER,
                           IID_PPV_ARGS(&task_bar_list_));
    if (SUCCEEDED(hr) && FAILED(task_bar_list_->HrInit())) {
      task_bar_list_ = nullptr;
    }
  }

  // As per MSDN marking the window as fullscreen should ensure that the
  // taskbar is moved to the bottom of the Z-order when the fullscreen window
  // is activated. If the window is not fullscreen, the Shell falls back to
  // heuristics to determine how the window should be treated, which means
  // that it could still consider the window as fullscreen. :(
  if (task_bar_list_) {
    task_bar_list_->MarkFullscreenWindow(window_handle_, !!fullscreen);
  }

  is_fullscreen_ = fullscreen;
}

bool HostWindow::GetFullscreen() const {
  return is_fullscreen_;
}

ActualWindowSize HostWindow::GetWindowContentSize(HWND hwnd) {
  RECT rect;
  GetClientRect(hwnd, &rect);
  double const dpr = FlutterDesktopGetDpiForHWND(hwnd) /
                     static_cast<double>(USER_DEFAULT_SCREEN_DPI);
  double const width = rect.right / dpr;
  double const height = rect.bottom / dpr;
  return {
      .width = rect.right / dpr,
      .height = rect.bottom / dpr,
  };
}

std::optional<Size> HostWindow::GetWindowSizeForClientSize(
    WindowsProcTable const& win32,
    Size const& client_size,
    std::optional<Size> smallest,
    std::optional<Size> biggest,
    DWORD window_style,
    DWORD extended_window_style,
    std::optional<HWND> const& owner_hwnd) {
  UINT const dpi = GetDpiForHWND(owner_hwnd ? *owner_hwnd : nullptr);
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

  // Apply size constraints.
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

void HostWindow::EnableRecursively(bool enable) {
  EnableWindow(window_handle_, enable);

  for (HostWindow* const owned : GetOwnedWindows()) {
    owned->EnableRecursively(enable);
  }
}

HostWindow* HostWindow::FindFirstEnabledDescendant() const {
  if (IsWindowEnabled(window_handle_)) {
    return const_cast<HostWindow*>(this);
  }

  for (HostWindow* const owned : GetOwnedWindows()) {
    if (HostWindow* const result = owned->FindFirstEnabledDescendant()) {
      return result;
    }
  }

  return nullptr;
}

std::vector<HostWindow*> HostWindow::GetOwnedWindows() const {
  std::vector<HostWindow*> owned_windows;
  struct EnumData {
    HWND owner_window_handle;
    std::vector<HostWindow*>* owned_windows;
  } data{window_handle_, &owned_windows};

  EnumWindows(
      [](HWND hwnd, LPARAM lparam) -> BOOL {
        auto* const data = reinterpret_cast<EnumData*>(lparam);
        if (GetWindow(hwnd, GW_OWNER) == data->owner_window_handle) {
          HostWindow* const window = GetThisFromHandle(hwnd);
          if (window && !window->is_being_destroyed_) {
            data->owned_windows->push_back(window);
          }
        }
        return TRUE;
      },
      reinterpret_cast<LPARAM>(&data));

  return owned_windows;
}

HostWindow* HostWindow::GetOwnerWindow() const {
  if (HWND const owner_window_handle = GetWindow(GetWindowHandle(), GW_OWNER)) {
    return GetThisFromHandle(owner_window_handle);
  }
  return nullptr;
};

void HostWindow::DisableRecursively() {
  // Disable the window itself.
  EnableWindow(window_handle_, false);

  for (HostWindow* const owned : GetOwnedWindows()) {
    owned->DisableRecursively();
  }
}

void HostWindow::UpdateModalStateLayer() {
  auto children = GetOwnedWindows();
  if (children.empty()) {
    // Leaf window in the active path, enable it.
    EnableWindow(window_handle_, true);
  } else {
    // Non-leaf window in the active path, disable it and process children.
    EnableWindow(window_handle_, false);

    // On same level of window hierarchy the most recently created window
    // will remain enabled.
    auto latest_child = *std::max_element(
        children.begin(), children.end(), [](HostWindow* a, HostWindow* b) {
          return a->view_controller_->view()->view_id() <
                 b->view_controller_->view()->view_id();
        });

    for (HostWindow* const child : children) {
      if (child == latest_child) {
        child->UpdateModalStateLayer();
      } else {
        child->DisableRecursively();
      }
    }
  }
}

}  // namespace flutter
