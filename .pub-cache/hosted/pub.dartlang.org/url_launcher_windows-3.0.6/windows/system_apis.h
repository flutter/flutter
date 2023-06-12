// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include <windows.h>

namespace url_launcher_windows {

// An interface wrapping system APIs used by the plugin, for mocking.
class SystemApis {
 public:
  SystemApis();
  virtual ~SystemApis();

  // Disallow copy and move.
  SystemApis(const SystemApis&) = delete;
  SystemApis& operator=(const SystemApis&) = delete;

  // Wrapper for RegCloseKey.
  virtual LSTATUS RegCloseKey(HKEY key) = 0;

  // Wrapper for RegQueryValueEx.
  virtual LSTATUS RegQueryValueExW(HKEY key, LPCWSTR value_name, LPDWORD type,
                                   LPBYTE data, LPDWORD data_size) = 0;

  // Wrapper for RegOpenKeyEx.
  virtual LSTATUS RegOpenKeyExW(HKEY key, LPCWSTR sub_key, DWORD options,
                                REGSAM desired, PHKEY result) = 0;

  // Wrapper for ShellExecute.
  virtual HINSTANCE ShellExecuteW(HWND hwnd, LPCWSTR operation, LPCWSTR file,
                                  LPCWSTR parameters, LPCWSTR directory,
                                  int show_flags) = 0;
};

// Implementation of SystemApis using the Win32 APIs.
class SystemApisImpl : public SystemApis {
 public:
  SystemApisImpl();
  virtual ~SystemApisImpl();

  // Disallow copy and move.
  SystemApisImpl(const SystemApisImpl&) = delete;
  SystemApisImpl& operator=(const SystemApisImpl&) = delete;

  // SystemApis Implementation:
  virtual LSTATUS RegCloseKey(HKEY key);
  virtual LSTATUS RegOpenKeyExW(HKEY key, LPCWSTR sub_key, DWORD options,
                                REGSAM desired, PHKEY result);
  virtual LSTATUS RegQueryValueExW(HKEY key, LPCWSTR value_name, LPDWORD type,
                                   LPBYTE data, LPDWORD data_size);
  virtual HINSTANCE ShellExecuteW(HWND hwnd, LPCWSTR operation, LPCWSTR file,
                                  LPCWSTR parameters, LPCWSTR directory,
                                  int show_flags);
};

}  // namespace url_launcher_windows
