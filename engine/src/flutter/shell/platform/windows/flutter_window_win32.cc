// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_window_win32.h"

#include <dwmapi.h>
#include <chrono>
#include <map>

namespace flutter {

namespace {

// The Windows DPI system is based on this
// constant for machines running at 100% scaling.
constexpr int base_dpi = 96;

// TODO: See if this can be queried from the OS; this value is chosen
// arbitrarily to get something that feels reasonable.
constexpr int kScrollOffsetMultiplier = 20;

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

FlutterWindowWin32::FlutterWindowWin32(int width, int height)
    : binding_handler_delegate_(nullptr) {
  WindowWin32::InitializeChild("FLUTTERVIEW", width, height);
  current_cursor_ = ::LoadCursor(nullptr, IDC_ARROW);
}

FlutterWindowWin32::~FlutterWindowWin32() {}

void FlutterWindowWin32::SetView(WindowBindingHandlerDelegate* window) {
  binding_handler_delegate_ = window;
  direct_manipulation_owner_->SetBindingHandlerDelegate(window);
}

WindowsRenderTarget FlutterWindowWin32::GetRenderTarget() {
  return WindowsRenderTarget(GetWindowHandle());
}

PlatformWindow FlutterWindowWin32::GetPlatformWindow() {
  return GetWindowHandle();
}

float FlutterWindowWin32::GetDpiScale() {
  return static_cast<float>(GetCurrentDPI()) / static_cast<float>(base_dpi);
}

bool FlutterWindowWin32::IsVisible() {
  return IsWindowVisible(GetWindowHandle());
}

PhysicalWindowBounds FlutterWindowWin32::GetPhysicalWindowBounds() {
  return {GetCurrentWidth(), GetCurrentHeight()};
}

void FlutterWindowWin32::UpdateFlutterCursor(const std::string& cursor_name) {
  current_cursor_ = GetCursorByName(cursor_name);
}

void FlutterWindowWin32::OnWindowResized() {
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
  std::cerr << "Mouse button not recognized: " << button << std::endl;
  return 0;
}

void FlutterWindowWin32::OnDpiScale(unsigned int dpi){};

// When DesktopWindow notifies that a WM_Size message has come in
// lets FlutterEngine know about the new size.
void FlutterWindowWin32::OnResize(unsigned int width, unsigned int height) {
  if (binding_handler_delegate_ != nullptr) {
    binding_handler_delegate_->OnWindowSizeChanged(width, height);
  }
}

void FlutterWindowWin32::OnPointerMove(double x,
                                       double y,
                                       FlutterPointerDeviceKind device_kind,
                                       int32_t device_id) {
  binding_handler_delegate_->OnPointerMove(x, y, device_kind, device_id);
}

void FlutterWindowWin32::OnPointerDown(double x,
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

void FlutterWindowWin32::OnPointerUp(double x,
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

void FlutterWindowWin32::OnPointerLeave(double x,
                                        double y,
                                        FlutterPointerDeviceKind device_kind,
                                        int32_t device_id) {
  binding_handler_delegate_->OnPointerLeave(x, y, device_kind, device_id);
}

void FlutterWindowWin32::OnSetCursor() {
  ::SetCursor(current_cursor_);
}

void FlutterWindowWin32::OnText(const std::u16string& text) {
  binding_handler_delegate_->OnText(text);
}

void FlutterWindowWin32::OnKey(int key,
                               int scancode,
                               int action,
                               char32_t character,
                               bool extended,
                               bool was_down,
                               KeyEventCallback callback) {
  binding_handler_delegate_->OnKey(key, scancode, action, character, extended,
                                   was_down, std::move(callback));
}

void FlutterWindowWin32::OnComposeBegin() {
  binding_handler_delegate_->OnComposeBegin();
}

void FlutterWindowWin32::OnComposeCommit() {
  binding_handler_delegate_->OnComposeCommit();
}

void FlutterWindowWin32::OnComposeEnd() {
  binding_handler_delegate_->OnComposeEnd();
}

void FlutterWindowWin32::OnComposeChange(const std::u16string& text,
                                         int cursor_pos) {
  binding_handler_delegate_->OnComposeChange(text, cursor_pos);
}

void FlutterWindowWin32::OnUpdateSemanticsEnabled(bool enabled) {
  binding_handler_delegate_->OnUpdateSemanticsEnabled(enabled);
}

void FlutterWindowWin32::OnScroll(double delta_x,
                                  double delta_y,
                                  FlutterPointerDeviceKind device_kind,
                                  int32_t device_id) {
  POINT point;
  GetCursorPos(&point);

  ScreenToClient(GetWindowHandle(), &point);
  binding_handler_delegate_->OnScroll(point.x, point.y, delta_x, delta_y,
                                      kScrollOffsetMultiplier, device_kind,
                                      device_id);
}

void FlutterWindowWin32::OnCursorRectUpdated(const Rect& rect) {
  // Convert the rect from Flutter logical coordinates to device coordinates.
  auto scale = GetDpiScale();
  Point origin(rect.left() * scale, rect.top() * scale);
  Size size(rect.width() * scale, rect.height() * scale);
  UpdateCursorRect(Rect(origin, size));
}

void FlutterWindowWin32::OnResetImeComposing() {
  AbortImeComposing();
}

bool FlutterWindowWin32::OnBitmapSurfaceUpdated(const void* allocation,
                                                size_t row_bytes,
                                                size_t height) {
  HDC dc = ::GetDC(std::get<HWND>(GetRenderTarget()));
  BITMAPINFO bmi;
  memset(&bmi, 0, sizeof(bmi));
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = row_bytes / 4;
  bmi.bmiHeader.biHeight = -height;
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;
  bmi.bmiHeader.biSizeImage = 0;
  int ret = SetDIBitsToDevice(dc, 0, 0, row_bytes / 4, height, 0, 0, 0, height,
                              allocation, &bmi, DIB_RGB_COLORS);
  return ret != 0;
}

gfx::NativeViewAccessible FlutterWindowWin32::GetNativeViewAccessible() {
  return binding_handler_delegate_->GetNativeViewAccessible();
}

PointerLocation FlutterWindowWin32::GetPrimaryPointerLocation() {
  POINT point;
  GetCursorPos(&point);
  ScreenToClient(GetWindowHandle(), &point);
  return {(size_t)point.x, (size_t)point.y};
}

}  // namespace flutter
