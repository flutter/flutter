// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/windows_proc_table.h"

#include <WinUser.h>
#include <dwmapi.h>

namespace flutter {

WindowsProcTable::WindowsProcTable() {
  user32_ = fml::NativeLibrary::Create("user32.dll");
  get_pointer_type_ =
      user32_->ResolveFunction<GetPointerType_*>("GetPointerType");
  enable_non_client_dpi_scaling_ =
      user32_->ResolveFunction<EnableNonClientDpiScaling_*>(
          "EnableNonClientDpiScaling");
  set_window_composition_attribute_ =
      user32_->ResolveFunction<SetWindowCompositionAttribute_*>(
          "SetWindowCompositionAttribute");
  adjust_window_rect_ext_for_dpi_ =
      user32_->ResolveFunction<AdjustWindowRectExForDpi_*>(
          "AdjustWindowRectExForDpi");
}

WindowsProcTable::~WindowsProcTable() {
  user32_ = nullptr;
}

BOOL WindowsProcTable::GetPointerType(UINT32 pointer_id,
                                      POINTER_INPUT_TYPE* pointer_type) const {
  if (!get_pointer_type_.has_value()) {
    return FALSE;
  }

  return get_pointer_type_.value()(pointer_id, pointer_type);
}

LRESULT WindowsProcTable::GetThreadPreferredUILanguages(DWORD flags,
                                                        PULONG count,
                                                        PZZWSTR languages,
                                                        PULONG length) const {
  return ::GetThreadPreferredUILanguages(flags, count, languages, length);
}

bool WindowsProcTable::GetHighContrastEnabled() const {
  HIGHCONTRAST high_contrast = {.cbSize = sizeof(HIGHCONTRAST)};
  if (!::SystemParametersInfoW(SPI_GETHIGHCONTRAST, sizeof(HIGHCONTRAST),
                               &high_contrast, 0)) {
    return false;
  }

  return high_contrast.dwFlags & HCF_HIGHCONTRASTON;
}

bool WindowsProcTable::DwmIsCompositionEnabled() const {
  BOOL composition_enabled;
  if (SUCCEEDED(::DwmIsCompositionEnabled(&composition_enabled))) {
    return composition_enabled;
  }

  return true;
}

HRESULT WindowsProcTable::DwmFlush() const {
  return ::DwmFlush();
}

HCURSOR WindowsProcTable::LoadCursor(HINSTANCE instance,
                                     LPCWSTR cursor_name) const {
  return ::LoadCursorW(instance, cursor_name);
}

HCURSOR WindowsProcTable::SetCursor(HCURSOR cursor) const {
  return ::SetCursor(cursor);
}

BOOL WindowsProcTable::EnableNonClientDpiScaling(HWND hwnd) const {
  if (!enable_non_client_dpi_scaling_.has_value()) {
    return FALSE;
  }

  return enable_non_client_dpi_scaling_.value()(hwnd);
}

BOOL WindowsProcTable::SetWindowCompositionAttribute(
    HWND hwnd,
    WINDOWCOMPOSITIONATTRIBDATA* data) const {
  if (!set_window_composition_attribute_.has_value()) {
    return FALSE;
  }

  return set_window_composition_attribute_.value()(hwnd, data);
}

HRESULT WindowsProcTable::DwmExtendFrameIntoClientArea(
    HWND hwnd,
    const MARGINS* pMarInset) const {
  return ::DwmExtendFrameIntoClientArea(hwnd, pMarInset);
}

HRESULT WindowsProcTable::DwmSetWindowAttribute(HWND hwnd,
                                                DWORD dwAttribute,
                                                LPCVOID pvAttribute,
                                                DWORD cbAttribute) const {
  return ::DwmSetWindowAttribute(hwnd, dwAttribute, pvAttribute, cbAttribute);
}

BOOL WindowsProcTable::AdjustWindowRectExForDpi(LPRECT lpRect,
                                                DWORD dwStyle,
                                                BOOL bMenu,
                                                DWORD dwExStyle,
                                                UINT dpi) const {
  if (!adjust_window_rect_ext_for_dpi_.has_value()) {
    return FALSE;
  }

  return adjust_window_rect_ext_for_dpi_.value()(lpRect, dwStyle, bMenu,
                                                 dwExStyle, dpi);
}

int WindowsProcTable::GetSystemMetrics(int nIndex) const {
  return ::GetSystemMetrics(nIndex);
}

BOOL WindowsProcTable::EnumDisplayDevices(LPCWSTR lpDevice,
                                          DWORD iDevNum,
                                          PDISPLAY_DEVICE lpDisplayDevice,
                                          DWORD dwFlags) const {
  return ::EnumDisplayDevices(lpDevice, iDevNum, lpDisplayDevice, dwFlags);
}

BOOL WindowsProcTable::EnumDisplaySettings(LPCWSTR lpszDeviceName,
                                           DWORD iModeNum,
                                           DEVMODEW* lpDevMode) const {
  return ::EnumDisplaySettingsW(lpszDeviceName, iModeNum, lpDevMode);
}

BOOL WindowsProcTable::GetMonitorInfo(HMONITOR hMonitor,
                                      LPMONITORINFO lpmi) const {
  return ::GetMonitorInfoW(hMonitor, lpmi);
}

BOOL WindowsProcTable::EnumDisplayMonitors(HDC hdc,
                                           LPCRECT lprcClip,
                                           MONITORENUMPROC lpfnEnum,
                                           LPARAM dwData) const {
  return ::EnumDisplayMonitors(hdc, lprcClip, lpfnEnum, dwData);
}

}  // namespace flutter
