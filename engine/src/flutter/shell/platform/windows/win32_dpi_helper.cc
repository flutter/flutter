#include "flutter/shell/platform/windows/win32_dpi_helper.h"

namespace flutter {

namespace {

template <typename T>
bool AssignProcAddress(HMODULE comBaseModule, const char* name, T*& outProc) {
  outProc = reinterpret_cast<T*>(GetProcAddress(comBaseModule, name));
  return *outProc != nullptr;
}

}  // namespace

Win32DpiHelper::Win32DpiHelper() {
  // TODO ensure that this helper works correctly on downlevel builds.
  user32_module_ = LoadLibraryA("User32.dll");
  if (user32_module_ == nullptr) {
    return;
  }

  if (!AssignProcAddress(user32_module_, "EnableNonClientDpiScaling",
                         enable_non_client_dpi_scaling_)) {
    return;
  }

  if (!AssignProcAddress(user32_module_, "GetDpiForWindow",
                         get_dpi_for_window_)) {
    return;
  }

  if (!AssignProcAddress(user32_module_, "SetProcessDpiAwarenessContext",
                         set_process_dpi_awareness_context_)) {
    return;
  }

  permonitorv2_supported_ = true;
}

Win32DpiHelper::~Win32DpiHelper() {
  if (user32_module_ != nullptr) {
    FreeLibrary(user32_module_);
  }
}

bool Win32DpiHelper::IsPerMonitorV2Available() {
  return permonitorv2_supported_;
}

BOOL Win32DpiHelper::EnableNonClientDpiScaling(HWND hwnd) {
  if (!permonitorv2_supported_) {
    return false;
  }
  return enable_non_client_dpi_scaling_(hwnd);
}

UINT Win32DpiHelper::GetDpiForWindow(HWND hwnd) {
  if (!permonitorv2_supported_) {
    return false;
  }
  return get_dpi_for_window_(hwnd);
}

BOOL Win32DpiHelper::SetProcessDpiAwarenessContext(
    DPI_AWARENESS_CONTEXT context) {
  if (!permonitorv2_supported_) {
    return false;
  }
  return set_process_dpi_awareness_context_(context);
}

}  // namespace flutter
