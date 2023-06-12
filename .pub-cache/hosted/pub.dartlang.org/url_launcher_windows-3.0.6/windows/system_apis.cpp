// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "system_apis.h"

#include <windows.h>

namespace url_launcher_windows {

SystemApis::SystemApis() {}

SystemApis::~SystemApis() {}

SystemApisImpl::SystemApisImpl() {}

SystemApisImpl::~SystemApisImpl() {}

LSTATUS SystemApisImpl::RegCloseKey(HKEY key) { return ::RegCloseKey(key); }

LSTATUS SystemApisImpl::RegOpenKeyExW(HKEY key, LPCWSTR sub_key, DWORD options,
                                      REGSAM desired, PHKEY result) {
  return ::RegOpenKeyExW(key, sub_key, options, desired, result);
}

LSTATUS SystemApisImpl::RegQueryValueExW(HKEY key, LPCWSTR value_name,
                                         LPDWORD type, LPBYTE data,
                                         LPDWORD data_size) {
  return ::RegQueryValueExW(key, value_name, nullptr, type, data, data_size);
}

HINSTANCE SystemApisImpl::ShellExecuteW(HWND hwnd, LPCWSTR operation,
                                        LPCWSTR file, LPCWSTR parameters,
                                        LPCWSTR directory, int show_flags) {
  return ::ShellExecuteW(hwnd, operation, file, parameters, directory,
                         show_flags);
}

}  // namespace url_launcher_windows
