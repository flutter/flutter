// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_REGISTRY_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_REGISTRY_H_

#include <Windows.h>

#include "flutter/fml/macros.h"

namespace flutter {

/// A utility class to encapsulate interaction with the Windows registry.
/// By encapsulating this in a class, we can mock out this functionality
/// for unit testing.
class WindowsRegistry {
 public:
  WindowsRegistry() = default;
  virtual ~WindowsRegistry() = default;

  // Parameters and return values of this method match those of RegGetValue
  // See:
  // https://learn.microsoft.com/windows/win32/api/winreg/nf-winreg-reggetvaluew
  virtual LSTATUS GetRegistryValue(HKEY hkey,
                                   LPCWSTR key,
                                   LPCWSTR value,
                                   DWORD flags,
                                   LPDWORD type,
                                   PVOID data,
                                   LPDWORD data_size) const;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(WindowsRegistry);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WINDOWS_REGISTRY_H_
