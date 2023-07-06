// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_PROC_TABLE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_PROC_TABLE_H_

#include <optional>

#include "flutter/fml/macros.h"
#include "flutter/fml/native_library.h"

namespace flutter {

// Lookup table for Windows APIs that aren't available on all versions of
// Windows, or for mocking Windows API calls.
class WindowsProcTable {
 public:
  WindowsProcTable();
  virtual ~WindowsProcTable();

  // Retrieves the pointer type for a specified pointer.
  //
  // Used to react differently to touch or pen inputs. Returns false on failure.
  // Available in Windows 8 and newer, otherwise returns false.
  virtual BOOL GetPointerType(UINT32 pointer_id,
                              POINTER_INPUT_TYPE* pointer_type);

  // Get the preferred languages for the thread, and optionally the process,
  // and system, in that order, depending on the flags.
  // See
  // https://learn.microsoft.com/windows/win32/api/winnls/nf-winnls-getthreadpreferreduilanguages
  virtual LRESULT GetThreadPreferredUILanguages(DWORD flags,
                                                PULONG count,
                                                PZZWSTR languages,
                                                PULONG length) const;

 private:
  using GetPointerType_ = BOOL __stdcall(UINT32 pointerId,
                                         POINTER_INPUT_TYPE* pointerType);

  // The User32.dll library, used to resolve functions at runtime.
  fml::RefPtr<fml::NativeLibrary> user32_;

  std::optional<GetPointerType_*> get_pointer_type_;

  FML_DISALLOW_COPY_AND_ASSIGN(WindowsProcTable);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_PROC_TABLE_H_
