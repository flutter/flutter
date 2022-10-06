// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/windows_registry.h"

namespace flutter {

LSTATUS WindowsRegistry::GetRegistryValue(HKEY hkey,
                                          LPCWSTR key,
                                          LPCWSTR value,
                                          DWORD flags,
                                          LPDWORD type,
                                          PVOID data,
                                          LPDWORD data_size) const {
  return RegGetValue(hkey, key, value, flags, type, data, data_size);
}

}  // namespace flutter
