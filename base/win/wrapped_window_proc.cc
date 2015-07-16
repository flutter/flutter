// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/wrapped_window_proc.h"

#include "base/atomicops.h"
#include "base/logging.h"
#include "base/process/memory.h"

namespace {

base::win::WinProcExceptionFilter s_exception_filter = NULL;

}  // namespace.

namespace base {
namespace win {

WinProcExceptionFilter SetWinProcExceptionFilter(
    WinProcExceptionFilter filter) {
  subtle::AtomicWord rv = subtle::NoBarrier_AtomicExchange(
      reinterpret_cast<subtle::AtomicWord*>(&s_exception_filter),
      reinterpret_cast<subtle::AtomicWord>(filter));
  return reinterpret_cast<WinProcExceptionFilter>(rv);
}

int CallExceptionFilter(EXCEPTION_POINTERS* info) {
  return s_exception_filter ? s_exception_filter(info) :
                              EXCEPTION_CONTINUE_SEARCH;
}

BASE_EXPORT void InitializeWindowClass(
    const char16* class_name,
    WNDPROC window_proc,
    UINT style,
    int class_extra,
    int window_extra,
    HCURSOR cursor,
    HBRUSH background,
    const char16* menu_name,
    HICON large_icon,
    HICON small_icon,
    WNDCLASSEX* class_out) {
  class_out->cbSize = sizeof(WNDCLASSEX);
  class_out->style = style;
  class_out->lpfnWndProc = window_proc;
  class_out->cbClsExtra = class_extra;
  class_out->cbWndExtra = window_extra;
  class_out->hInstance = base::GetModuleFromAddress(window_proc);
  class_out->hIcon = large_icon;
  class_out->hCursor = cursor;
  class_out->hbrBackground = background;
  class_out->lpszMenuName = menu_name;
  class_out->lpszClassName = class_name;
  class_out->hIconSm = small_icon;

  // Check if |window_proc| is valid.
  DCHECK(class_out->hInstance != NULL);
}

}  // namespace win
}  // namespace base
