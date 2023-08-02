// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_window.h"

#include <WinUser.h>
#include <dwmapi.h>

#include <chrono>
#include <map>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"

namespace flutter {

namespace {

// The Windows DPI system is based on this
// constant for machines running at 100% scaling.
constexpr int base_dpi = 96;

// Maps a Flutter cursor name to an HCURSOR.
//
// Returns the arrow cursor for unknown constants.
//
// This map must be kept in sync with Flutter framework's
// services/mouse_cursor.dart.
static HCURSOR GetCursorByName(const std::string& cursor_name) {
  static auto* cursors = new std::map<std::string, const wchar_t*>{
      {"allScroll", IDC_SIZEALL},
      {"basic", IDC_ARROW},
      {"click", IDC_HAND},
      {"forbidden", IDC_NO},
      {"help", IDC_HELP},
      {"move", IDC_SIZEALL},
      {"none", nullptr},
      {"noDrop", IDC_NO},
      {"precise", IDC_CROSS},
      {"progress", IDC_APPSTARTING},
      {"text", IDC_IBEAM},
      {"resizeColumn", IDC_SIZEWE},
      {"resizeDown", IDC_SIZENS},
      {"resizeDownLeft", IDC_SIZENESW},
      {"resizeDownRight", IDC_SIZENWSE},
      {"resizeLeft", IDC_SIZEWE},
      {"resizeLeftRight", IDC_SIZEWE},
      {"resizeRight", IDC_SIZEWE},
      {"resizeRow", IDC_SIZENS},
      {"resizeUp", IDC_SIZENS},
      {"resizeUpDown", IDC_SIZENS},
      {"resizeUpLeft", IDC_SIZENWSE},
      {"resizeUpRight", IDC_SIZENESW},
      {"resizeUpLeftDownRight", IDC_SIZENWSE},
      {"resizeUpRightDownLeft", IDC_SIZENESW},
      {"wait", IDC_WAIT},
  };
  const wchar_t* idc_name = IDC_ARROW;
  auto it = cursors->find(cursor_name);
  if (it != cursors->end()) {
    idc_name = it->second;
  }
  return ::LoadCursor(nullptr, idc_name);
}

}  // namespace

FlutterWindow::FlutterWindow(int width, int height)
    : binding_handler_delegate_(nullptr) {
  Window::InitializeChild("FLUTTERVIEW", width, height);
  current_cursor_ = ::LoadCursor(nullptr, IDC_ARROW);
}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::SetView(WindowBindingHandlerDelegate* window) {
  binding_handler_delegate_ = window;
  direct_manipulation_owner_->SetBindingHandlerDelegate(window);
}

WindowsRenderTarget FlutterWindow::GetRenderTarget() {
  return WindowsRenderTarget(GetWindowHandle());
}

PlatformWindow FlutterWindow::GetPlatformWindow() {
  return GetWindowHandle();
}

float FlutterWindow::GetDpiScale() {
  return static_cast<float>(GetCurrentDPI()) / static_cast<float>(base_dpi);
}

bool FlutterWindow::IsVisible() {
  return IsWindowVisible(GetWindowHandle());
}

PhysicalWindowBounds FlutterWindow::GetPhysicalWindowBounds() {
  return {GetCurrentWidth(), GetCurrentHeight()};
}

void FlutterWindow::UpdateFlutterCursor(const std::string& cursor_name) {
  current_cursor_ = GetCursorByName(cursor_name);
}

void FlutterWindow::SetFlutterCursor(HCURSOR cursor) {
  current_cursor_ = cursor;
  ::SetCursor(current_cursor_);
}

void FlutterWindow::OnWindowResized() {
  // Blocking the raster thread until DWM flushes alleviates glitches where
  // previous size surface is stretched over current size view.
  DwmFlush();
}

// Translates button codes from Win32 API to FlutterPointerMouseButtons.
static uint64_t ConvertWinButtonToFlutterButton(UINT button) {
  switch (button) {
    case WM_LBUTTONDOWN:
    case WM_LBUTTONUP:
      return kFlutterPointerButtonMousePrimary;
    case WM_RBUTTONDOWN:
    case WM_RBUTTONUP:
      return kFlutterPointerButtonMouseSecondary;
    case WM_MBUTTONDOWN:
    case WM_MBUTTONUP:
      return kFlutterPointerButtonMouseMiddle;
    case XBUTTON1:
      return kFlutterPointerButtonMouseBack;
    case XBUTTON2:
      return kFlutterPointerButtonMouseForward;
  }
  FML_LOG(WARNING) << "Mouse button not recognized: " << button;
  return 0;
}

void FlutterWindow::OnDpiScale(unsigned int dpi){};

// When DesktopWindow notifies that a WM_Size message has come in
// lets FlutterEngine know about the new size.
void FlutterWindow::OnResize(unsigned int width, unsigned int height) {
  if (binding_handler_delegate_ != nullptr) {
    binding_handler_delegate_->OnWindowSizeChanged(width, height);
  }
}

void FlutterWindow::OnPaint() {
  if (binding_handler_delegate_ != nullptr) {
    binding_handler_delegate_->OnWindowRepaint();
  }
}

void FlutterWindow::OnPointerMove(double x,
                                  double y,
                                  FlutterPointerDeviceKind device_kind,
                                  int32_t device_id,
                                  int modifiers_state) {
  binding_handler_delegate_->OnPointerMove(x, y, device_kind, device_id,
                                           modifiers_state);
}

void FlutterWindow::OnPointerDown(double x,
                                  double y,
                                  FlutterPointerDeviceKind device_kind,
                                  int32_t device_id,
                                  UINT button) {
  uint64_t flutter_button = ConvertWinButtonToFlutterButton(button);
  if (flutter_button != 0) {
    binding_handler_delegate_->OnPointerDown(
        x, y, device_kind, device_id,
        static_cast<FlutterPointerMouseButtons>(flutter_button));
  }
}

void FlutterWindow::OnPointerUp(double x,
                                double y,
                                FlutterPointerDeviceKind device_kind,
                                int32_t device_id,
                                UINT button) {
  uint64_t flutter_button = ConvertWinButtonToFlutterButton(button);
  if (flutter_button != 0) {
    binding_handler_delegate_->OnPointerUp(
        x, y, device_kind, device_id,
        static_cast<FlutterPointerMouseButtons>(flutter_button));
  }
}

void FlutterWindow::OnPointerLeave(double x,
                                   double y,
                                   FlutterPointerDeviceKind device_kind,
                                   int32_t device_id) {
  binding_handler_delegate_->OnPointerLeave(x, y, device_kind, device_id);
}

void FlutterWindow::OnSetCursor() {
  ::SetCursor(current_cursor_);
}

void FlutterWindow::OnText(const std::u16string& text) {
  binding_handler_delegate_->OnText(text);
}

void FlutterWindow::OnKey(int key,
                          int scancode,
                          int action,
                          char32_t character,
                          bool extended,
                          bool was_down,
                          KeyEventCallback callback) {
  binding_handler_delegate_->OnKey(key, scancode, action, character, extended,
                                   was_down, std::move(callback));
}

void FlutterWindow::OnComposeBegin() {
  binding_handler_delegate_->OnComposeBegin();
}

void FlutterWindow::OnComposeCommit() {
  binding_handler_delegate_->OnComposeCommit();
}

void FlutterWindow::OnComposeEnd() {
  binding_handler_delegate_->OnComposeEnd();
}

void FlutterWindow::OnComposeChange(const std::u16string& text,
                                    int cursor_pos) {
  binding_handler_delegate_->OnComposeChange(text, cursor_pos);
}

void FlutterWindow::OnUpdateSemanticsEnabled(bool enabled) {
  binding_handler_delegate_->OnUpdateSemanticsEnabled(enabled);
}

void FlutterWindow::OnScroll(double delta_x,
                             double delta_y,
                             FlutterPointerDeviceKind device_kind,
                             int32_t device_id) {
  POINT point;
  GetCursorPos(&point);

  ScreenToClient(GetWindowHandle(), &point);
  binding_handler_delegate_->OnScroll(point.x, point.y, delta_x, delta_y,
                                      GetScrollOffsetMultiplier(), device_kind,
                                      device_id);
}

void FlutterWindow::OnCursorRectUpdated(const Rect& rect) {
  // Convert the rect from Flutter logical coordinates to device coordinates.
  auto scale = GetDpiScale();
  Point origin(rect.left() * scale, rect.top() * scale);
  Size size(rect.width() * scale, rect.height() * scale);
  UpdateCursorRect(Rect(origin, size));
}

void FlutterWindow::OnResetImeComposing() {
  AbortImeComposing();
}

bool FlutterWindow::OnBitmapSurfaceUpdated(const void* allocation,
                                           size_t row_bytes,
                                           size_t height) {
  HDC dc = ::GetDC(GetWindowHandle());
  BITMAPINFO bmi = {};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = row_bytes / 4;
  bmi.bmiHeader.biHeight = -height;
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;
  bmi.bmiHeader.biSizeImage = 0;
  int ret = SetDIBitsToDevice(dc, 0, 0, row_bytes / 4, height, 0, 0, 0, height,
                              allocation, &bmi, DIB_RGB_COLORS);
  ::ReleaseDC(GetWindowHandle(), dc);
  return ret != 0;
}

gfx::NativeViewAccessible FlutterWindow::GetNativeViewAccessible() {
  if (binding_handler_delegate_ == nullptr) {
    return nullptr;
  }

  return binding_handler_delegate_->GetNativeViewAccessible();
}

PointerLocation FlutterWindow::GetPrimaryPointerLocation() {
  POINT point;
  GetCursorPos(&point);
  ScreenToClient(GetWindowHandle(), &point);
  return {(size_t)point.x, (size_t)point.y};
}

void FlutterWindow::OnThemeChange() {
  binding_handler_delegate_->UpdateHighContrastEnabled(
      GetHighContrastEnabled());
}

void FlutterWindow::SendInitialAccessibilityFeatures() {
  OnThemeChange();
}

ui::AXFragmentRootDelegateWin* FlutterWindow::GetAxFragmentRootDelegate() {
  return binding_handler_delegate_->GetAxFragmentRootDelegate();
}

AlertPlatformNodeDelegate* FlutterWindow::GetAlertDelegate() {
  CreateAxFragmentRoot();
  return alert_delegate_.get();
}

ui::AXPlatformNodeWin* FlutterWindow::GetAlert() {
  CreateAxFragmentRoot();
  return alert_node_.get();
}

bool FlutterWindow::NeedsVSync() {
  // If the Desktop Window Manager composition is enabled,
  // the system itself synchronizes with v-sync.
  // See: https://learn.microsoft.com/windows/win32/dwm/composition-ovw
  BOOL composition_enabled;
  if (SUCCEEDED(::DwmIsCompositionEnabled(&composition_enabled))) {
    return !composition_enabled;
  }

  return true;
}

}  // namespace flutter
